//
//  CreateAlbumArtistPlaylistViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 26.01.2021.
//

import UIKit
import CoreData
import Alamofire

/// A view controller that specializes in creating or editing all available entities
final class CreateOrEditContentViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var refreshBlurView: UIVisualEffectView!
    @IBOutlet private weak var refreshButton: UIButton!
    @IBOutlet private weak var cameraBlurView: UIVisualEffectView!
    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var searchImageTextField: FloatingLabelTextField!
    @IBOutlet private weak var nameTextField: FloatingLabelTextField!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var createButton: UIBarButtonItem!
    @IBOutlet private weak var activityIndicatiorView: UIActivityIndicatorView!
    @IBOutlet private weak var imageViewBlur: UIVisualEffectView!

    @IBOutlet private weak var selectSongsView: UIView!
    @IBOutlet private weak var selectSongsButton: UIButton!
    
    @IBOutlet private weak var selectArtistButton: UIButton!
    @IBOutlet private weak var selectArtistView: UIView!
    
    @IBOutlet private weak var selectAlbumButton: UIButton!
    @IBOutlet private weak var selectAlbumButtonView: UIView!
    
    
    //MARK: - Properties
    /// configures the type of content that will be added
    public var contentType: ContentType = .playlist
    /// Configures object for editing mode
    public var editingContent: NSManagedObject?
    /// The type of content that will be added
    enum ContentType {
        case album, artist, playlist, song
    }
    
    private var imageName = ""
    private var searchText = ""
    private var dataSource: UICollectionViewDiffableDataSource<Int, UnsplashResponse.Result>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, UnsplashResponse.Result>()
    private var results = [UnsplashResponse.Result]()
    // Songs that may be contained in the object.
    private var selectedSongs = [Song]() {
        didSet {
            selectSongsButton.setTitle("Selected Songs (\(selectedSongs.count))", for: .normal)
        }
    }
    // Albums that can be contained in the object.
    private var selectedAlbums = [Album]() {
        didSet {
            selectAlbumButton.setTitle("Selected Albums (\(selectedAlbums.count))", for: .normal)
        }
    }
    // Album, which can only be 1 in the object.
    private var selectedAlbum: Album? {
        didSet {
            selectAlbumButton.setTitle("Selected Album (1)", for: .normal)
        }
    }
    // Artist, which can only be 1 in the object.
    private var selectedArtist: Artist? {
        didSet {
            let title = selectedArtist == nil ? "Select Artist" : "Selected Artist (1)"
            selectArtistButton.setTitle(title, for: .normal)
        }
    }
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI
        configureBlurView()
        imageView.layer.cornerRadius = 13
        configureTextFields()
        configureCollectionView()
        
        // If Object are editing
        if editingContent != nil {
            configureViewForEditing()
            configureContentForEditing()
        } else {
            createButton.isEnabled = false
            refreshTapped(self)
            configureViewForCreating()
        }
        
        // Data
        configureDataSource()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LocalFileManager.deleteFile(withNameAndExtension: "\(imageName).jpg")
    }
    
    
    //MARK: - Actions
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    /// Saves the object to CoreData.
    @IBAction func createTapped(_ sender: Any) {
        if editingContent != nil {
            editInCoreData()
        } else {
            createInCoreData()
        }
        
        do {
            try context.save()
        } catch {
            print(error)
            self.showAlert(alertText: error.localizedDescription)
        }
        dismiss(animated: true, completion: nil)
    }
    
    /// Looks for a random picture in Unsplash
    @IBAction func refreshTapped(_ sender: Any) {
        activityIndicatiorView.startAnimating()
        refreshButton.isHidden = true
        let string = "https://source.unsplash.com/random"
        guard let url = URL(string: string) else { return }
        // Deletes temporary picture
        LocalFileManager.deleteFile(withNameAndExtension: "\(self.imageName).jpg")
        loadImage(from: url) { [weak self] error, fileURL in
            if let error = error {
                print(error)
                self?.showAlert(alertText: error.localizedDescription)
                self?.activityIndicatiorView.stopAnimating()
                self?.refreshButton.isHidden = false
                return
            }
            
            if let url = fileURL {
                self?.imageView.af.setImage(withURL: url)
            }
            
            UIView.animate(withDuration: 0.325, delay: 0, options: [], animations: {
                self?.imageViewBlur.alpha = 0
            }, completion: { _ in
                self?.imageViewBlur.isHidden = true
            })
            
            self?.activityIndicatiorView.stopAnimating()
            self?.refreshButton.isHidden = false
        }
    }
    
    /// Opens a controller with a list of songs.
    @IBAction func selectSongsTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: Storyboards.selectSongs, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? SelectSongsViewController else { return }
        vc.delegate = self
        vc.selectedSongs = selectedSongs
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Opens a controller with a list of artists.
    @objc private func selectArtistTapped() {
        let storyboard = UIStoryboard(name: Storyboards.selectArtist, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? SelectArtistViewController else { return }
        vc.delegate = self
        vc.selectedArtist = selectedArtist
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Opens a controller with a list of albums for multiple selection.
    @objc private func selectAlbumsTapped() {
        let storyboard = UIStoryboard(name: Storyboards.selectAlbums, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? SelectAlbumsViewController else { return }
        vc.delegate = self
        vc.selectedAlbums = selectedAlbums
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Opens a controller with a list of albums for single selection.
    @objc private func selectAlbumTapped() {
        let storyboard = UIStoryboard(name: Storyboards.selectAlbums, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? SelectAlbumsViewController else { return }
        vc.delegate = self
        vc.isMultipleSelectionAllowed = false
        vc.selectedAlbum = selectedAlbum
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Открывает UIImagePickerController для выбора изображения с галереи
    @IBAction func selectPhotoTapped(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
        present(pickerController, animated: true, completion: nil)
    }
}

//MARK: - Networking
extension CreateOrEditContentViewController {
    /// Hears changes of the text field.
    /// Checks the text field for emptiness, makes an appropriate mapping.
    @objc private func nameDidChanged(_ textField: UITextView) {
        if let text = textField.text, text.isEmpty {
            nameTextField.bottomLineColor = #colorLiteral(red: 0.8470588235, green: 0.2392156863, blue: 0.1882352941, alpha: 1)
            createButton.isEnabled = false
        } else {
            nameTextField.bottomLineColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            createButton.isEnabled = true
        }
    }
    
    /// Hears changes of the text field.
    /// Searches for images.
    @objc private func searchImageDidChanged(_ textField: UITextView) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(searchImages), object: nil)
        self.searchText = textField.text
        perform(#selector(searchImages), with: nil, afterDelay: 2)
    }
    
    /// Searches for pictures in Unsplash, or by the entered URL..
    @objc private func searchImages() {
        guard !searchText.isEmpty else { return }
        // loading image from URL
        if searchText.isValidURL, let url = URL(string: searchText) {
            activityIndicatiorView.startAnimating()
            refreshButton.isHidden = true
            imageView.af.setImage(withURL: url, completion:  { (_) in
                self.activityIndicatiorView.stopAnimating()
                self.refreshButton.isHidden = false
            })
            searchImageTextField.textField.text = ""
            searchImageTextField.textField.endEditing(true)
        } else {
            // Search for a picture in Unsplash.
            searchImage(by: searchText) { [weak self] (error, response) in
                if let error = error {
                    print(error)
                    self?.showAlert(alertText: error.localizedDescription)
                    return
                }
                
                guard let results = response?.results else { return }
                self?.results = results
                self?.setupSnapshot()
                UIView.animate(withDuration: 1) { [weak self] in
                    self?.collectionView.isHidden = false
                    self?.stackView.layoutIfNeeded()
                }
            }
        }
    }
    
    /// Search images in Unsplash.
    /// - Parameters:
    ///   - string: The string by which the search will be performed.
    ///   - completion: The block in which pass the error if received if not, a response.
    private func searchImage(by string: String, completion: ((Error?, UnsplashResponse?) -> Void)? = nil) {
        let safeString = "https://api.unsplash.com/search/photos?page=1&query=\(string)&client_id=\(ApiKeys.unsplashApiKey)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        AF.request(safeString).validate().responseDecodable(of: UnsplashResponse.self) { response in
            completion?(response.error, response.value)
        }
    }
    
    /// Uploads an image to storage.
    /// - Parameter url: Link to receive the picture.
    /// - Parameter completion: The block in which pass the error if received if not, a URL.
    private func loadImage(from url: URL, completion: ((Error?, URL?) -> Void)? = nil) {
        let destination: DownloadRequest.Destination = { _, _ in
            self.imageName = UUID().uuidString
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(self.imageName).jpg")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, to: destination).validate().response { (response) in
            completion?(response.error, response.fileURL)
        }
    }
    
    private typealias Thumbnails = (small: String, medium: String, large: String)
    
    /// Compresses the selected image and saves it to local storage.
    /// - Returns: Returns a tuple with the names of the saved images.
    private func compressImages() -> Thumbnails? {
        if imageName.isEmpty { imageName = UUID().uuidString }
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.8) else { return nil }
        guard let largeData = imageData.compressImage(size: .large) else { return nil }
        guard let mediumData = imageData.compressImage(size: .medium) else { return nil }
        guard let smallData = imageData.compressImage(size: .small) else { return nil }
        LocalFileManager.saveData(withNameAndExtension: "\(imageName)Large.jpg", data: largeData)
        LocalFileManager.saveData(withNameAndExtension: "\(imageName)Medium.jpg", data: mediumData)
        LocalFileManager.saveData(withNameAndExtension: "\(imageName)Small.jpg", data: smallData)
        
        return Thumbnails(small: "\(imageName)Small.jpg",
                          medium: "\(imageName)Medium.jpg",
                          large: "\(imageName)Large.jpg")
    }
}

//MARK: Configure UI
extension CreateOrEditContentViewController {
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.register(SquareImageCollectionViewCell.self, forCellWithReuseIdentifier: SquareImageCollectionViewCell.cellIdentifier)
        collectionView.collectionViewLayout = configureSongLayout()
    }
    
    private func configureBlurView() {
        refreshBlurView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        refreshBlurView.layer.cornerRadius = refreshButton.frame.height / 2
        refreshBlurView.clipsToBounds = true
        cameraBlurView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        cameraBlurView.layer.cornerRadius = cameraBlurView.frame.height / 2
        cameraBlurView.clipsToBounds = true
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium, scale: .large)
        let largeBoldDoc = UIImage(systemName: "camera.fill", withConfiguration: largeConfig)
        cameraButton.setImage(largeBoldDoc, for: .normal)
    }
    
    private func configureTextFields() {
        searchImageTextField.placeholder = "Search Image"
        nameTextField.placeholder = "Name"
        nameTextField.bottomLineColor = editingContent == nil ? #colorLiteral(red: 0.8470588235, green: 0.2392156863, blue: 0.1882352941, alpha: 1) : #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        nameTextField.textField.addTarget(self, action: #selector(nameDidChanged(_:)), for: .editingChanged)
        searchImageTextField.textField.addTarget(self, action: #selector(searchImageDidChanged(_:)), for: .editingChanged)
    }
    
    private func configureSongLayout() -> UICollectionViewLayout {
        let section: NSCollectionLayoutSection
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalHeight(1), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        section = NSCollectionLayoutSection(group: group)
        section.supplementariesFollowContentInsets = true
        section.interGroupSpacing = 16
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        
        return layout
    }
    
    /// Changes the appearance of views based on what is specified in `contentType`.
    private func configureViewForCreating() {
        switch contentType {
        case .album:
            navigationItem.title = "Create Album"
            selectArtistButton.addTarget(self, action: #selector(selectArtistTapped), for: .touchUpInside)
            selectAlbumButtonView.isHidden = true
        case .artist:
            navigationItem.title = "Create Artist"
            selectAlbumButton.addTarget(self, action: #selector(selectAlbumsTapped), for: .touchUpInside)
            selectArtistView.isHidden = true
        case .playlist:
            navigationItem.title = "Create Playlist"
            selectArtistView.isHidden = true
            selectAlbumButtonView.isHidden = true
        case .song:
            navigationItem.title = "Create Song"
            selectAlbumButton.addTarget(self, action: #selector(selectAlbumTapped), for: .touchUpInside)
            selectArtistButton.addTarget(self, action: #selector(selectArtistTapped), for: .touchUpInside)
            selectSongsView.isHidden = true
        }
    }
    
    /// Changes the appearance of views based on what is specified in `contentType`.
    private func configureViewForEditing() {
        switch contentType {
        case .album:
            navigationItem.title = "Edit Album"
            selectArtistButton.addTarget(self, action: #selector(selectArtistTapped), for: .touchUpInside)
            selectAlbumButtonView.isHidden = true
        case .artist:
            navigationItem.title = "Edit Artist"
            selectAlbumButton.addTarget(self, action: #selector(selectAlbumsTapped), for: .touchUpInside)
            selectArtistView.isHidden = true
        case .playlist:
            navigationItem.title = "Edit Playlist"
            selectArtistView.isHidden = true
            selectAlbumButtonView.isHidden = true
        case .song:
            navigationItem.title = "Edit Song"
            selectAlbumButton.addTarget(self, action: #selector(selectAlbumTapped), for: .touchUpInside)
            selectArtistButton.addTarget(self, action: #selector(selectArtistTapped), for: .touchUpInside)
            selectSongsView.isHidden = true
        }
    }
    
    /// Adjusts the appearance of elements. Populates with data from an object.
    private func configureAlbumForEditing() {
        guard let content = editingContent as? Album,
              let url = content.thumbnails?.largeUrl else { return }
        imageView.af.setImage(withURL: url)
        nameTextField.text = content.name
        selectedSongs = content.songs?.allObjects as! [Song]
        selectedArtist = content.author
    }
    
    /// Adjusts the appearance of elements. Populates with data from an object.
    private func configureAristForEditing() {
        guard let content = editingContent as? Artist,
              let url = content.thumbnails?.largeUrl else { return }
        imageView.af.setImage(withURL: url)
        nameTextField.text = content.name
        selectedSongs = content.songs?.allObjects as! [Song]
        selectedAlbums = content.albums?.allObjects as! [Album]
    }
    
    /// Adjusts the appearance of elements. Populates with data from an object.
    private func configurePlaylistForEditing() {
        guard let content = editingContent as? Playlist,
              let url = content.thumbnails?.largeUrl else { return }
        imageView.af.setImage(withURL: url)
        nameTextField.text = content.name
        selectedSongs = content.songs?.allObjects as! [Song]
    }
    
    /// Adjusts the appearance of elements. Populates with data from an object.
    private func configureSongForEditing() {
        guard let content = editingContent as? Song,
              let url = content.thumbnails?.largeUrl else { return }
        imageView.af.setImage(withURL: url)
        nameTextField.text = content.name
        selectedArtist = content.author
        selectedAlbum = content.album
    }
    
    /// Adjusts the appearance of elements for editing. Populates with data from an object.
    private func configureContentForEditing() {
        imageViewBlur.isHidden = true
        activityIndicatiorView.stopAnimating()
        switch contentType {
        case .album:
            configureAlbumForEditing()
        case .artist:
            configureAristForEditing()
        case .playlist:
            configurePlaylistForEditing()
        case .song:
            configureSongForEditing()
        }
        
        createButton.title = "Save"
    }
}

//MARK: Setup Data
extension CreateOrEditContentViewController {
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, UnsplashResponse.Result> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: SquareImageCollectionViewCell.cellIdentifier, for: indexPath) as! SquareImageCollectionViewCell
            let imageUrl = self.results[indexPath.item].urls.small
            guard let url = URL(string: imageUrl) else { return cell }
            cell.imageView.af.setImage(withURL: url, placeholderImage: #imageLiteral(resourceName: "image_placeholder"))
            return cell
        })
        
        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, UnsplashResponse.Result>()
        snapshot.appendSections([0])
        snapshot.appendItems(results)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
    
    /// Creates the desired object in CoreData.
    private func createInCoreData() {
        guard let name = nameTextField.textField.text else { return }
        let th = compressImages()
        let thumbnail = Thumbnail.create(context: context, small: th?.small, medium: th?.medium, large: th?.large)
        switch contentType {
        case .album:
            Album.create(context: context, thumbnails: thumbnail, name: name, author: selectedArtist, songs: selectedSongs)
        case .artist:
            Artist.create(context: context, thumbnails: thumbnail, id: nil, name: name, songs: selectedSongs, albums: selectedAlbums)
        case .playlist:
            Playlist.create(context: context, thumbnails: thumbnail, name: nameTextField.textField.text, songs: selectedSongs)
        case .song: break
        }
    }
    
    /// Edit existing object in CoreData.
    private func editInCoreData() {
        guard let name = nameTextField.textField.text else { return }
        let th = compressImages()
        let thumbnail = Thumbnail.create(context: context, small: th?.small, medium: th?.medium, large: th?.large)
        
        switch contentType {
        case .album:
            guard let album = editingContent as? Album else { return }
            album.name = name
            album.author = selectedArtist
            album.songs = NSSet(array: selectedSongs as [Any])
            album.thumbnails?.removeImages()
            album.thumbnails = thumbnail
        case .artist:
            guard let artist = editingContent as? Artist else { return }
            artist.name = name
            artist.songs = NSSet(array: selectedSongs as [Any])
            artist.albums = NSSet(array: selectedAlbums as [Any])
            artist.thumbnails?.removeImages()
            artist.thumbnails = thumbnail
        case .playlist:
            guard let playlist = editingContent as? Playlist else { return }
            playlist.thumbnails?.removeImages()
            playlist.thumbnails = thumbnail
            playlist.name = name
            playlist.songs = NSSet(array: selectedSongs as [Any])
        case .song:
            guard let song = editingContent as? Song else { return }
            song.thumbnails?.removeImages()
            song.thumbnails = thumbnail
            song.name = name
            song.author = selectedArtist
            song.album = selectedAlbum
        }
    }
}

//MARK: - SelectSongsViewControllerDelegate
extension CreateOrEditContentViewController: SelectSongsViewControllerDelegate {
    func didSaveSelectedSongs(_ songs: [Song]) {
        selectedSongs = songs
    }
}

//MARK: - SelectArtistViewControllerDelegate
extension CreateOrEditContentViewController: SelectArtistViewControllerDelegate {
    func didSaveSelectedArtist(_ artist: Artist) {
        selectedArtist = artist
    }
}

//MARK: - SelectAlbumsViewControllerDelegate
extension CreateOrEditContentViewController: SelectAlbumsViewControllerDelegate {
    func didSaveSelectedAlbum(_ album: Album?) {
        selectedAlbum = album
    }
    
    func didSaveSelectedAlbums(_ albums: [Album]) {
        selectedAlbums = albums
    }
}

//MARK: - UICollectionViewDelegate
extension CreateOrEditContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = results[indexPath.item]
        guard let url = URL(string: item.urls.regular) else { return }
        imageView.af.setImage(withURL: url)
    }
}

//MARK: - UIImagePickerControllerDelegate
extension CreateOrEditContentViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
}
