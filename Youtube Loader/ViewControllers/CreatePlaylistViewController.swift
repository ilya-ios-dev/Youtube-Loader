//
//  CreatePlaylistViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 26.01.2021.
//

import UIKit
import CoreData
import Alamofire

final class CreatePlaylistViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var refreshBlurView: UIVisualEffectView!
    @IBOutlet private weak var refreshButton: UIButton!
    @IBOutlet private weak var cameraBlurView: UIVisualEffectView!
    @IBOutlet private weak var cameraButton: UIButton!
    @IBOutlet private weak var searchImageTextField: CustomTextField!
    @IBOutlet private weak var nameTextField: CustomTextField!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var createButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicatiorView: UIActivityIndicatorView!
    
    //MARK: - Properties
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    private var imageName = ""
    private var dataSource: UICollectionViewDiffableDataSource<Int, UnsplashResponse.Result>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, UnsplashResponse.Result>()
    private var searchText = ""
    private var results = [UnsplashResponse.Result]() {
        didSet {
            UIView.animate(withDuration: 1) {
                self.collectionView.isHidden = false
                self.stackView.layoutIfNeeded()
            }
            setupSnapshot()
        }
    }
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        createButton.isEnabled = false
        configureBlurView()
        imageView.layer.cornerRadius = 13
        configureTextFields()
        configureCollectionView()
        configureDataSource()
        refreshTapped(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        LocalFileManager.deleteFile(withNameAndExtension: "\(imageName).jpg")
    }
    
    @objc private func nameDidChanged(_ textField: UITextView) {
        if let text = textField.text, text.isEmpty {
            nameTextField.bottomLineColor = #colorLiteral(red: 0.8470588235, green: 0.2392156863, blue: 0.1882352941, alpha: 1)
            createButton.isEnabled = false
        } else {
            nameTextField.bottomLineColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            createButton.isEnabled = true
        }
    }
    
    @objc private func searchImageDidChanged(_ textField: UITextView) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = textField.text
        perform(#selector(search), with: nil, afterDelay: 2)
    }
    
    @objc private func search() {
        guard !searchText.isEmpty else { return }
        searchImage(by: searchText) { (error, response) in
            if let error = error {
                print(error)
                self.showAlert(alertText: error.localizedDescription)
                return
            }
            
            guard let results = response?.results else { return }
            self.results = results
        }
    }
    
    
    private func searchImage(by string: String, completion: ((Error?, UnsplashResponse?) -> Void)? = nil) {
        let safeString = "https://api.unsplash.com/search/photos?page=1&query=\(string)&client_id=\(ApiKeys.unsplashApiKey)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        AF.request(safeString).validate().responseDecodable(of: UnsplashResponse.self) { response in
            completion?(response.error, response.value)
        }
    }

    //MARK: - Actions
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createTapped(_ sender: Any) {
        compressAndSaveImages()
    }
    
    private func compressAndSaveImages() {
        if imageName.isEmpty { imageName = UUID().uuidString }
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.8) else { return }
        guard let largeData = imageData.compressImage(size: .large) else { return }
        guard let mediumData = imageData.compressImage(size: .medium) else { return }
        guard let smallData = imageData.compressImage(size: .small) else { return }
        LocalFileManager.saveData(withNameAndExtension: "\(imageName)Large.jpg", data: largeData)
        LocalFileManager.saveData(withNameAndExtension: "\(imageName)Medium.jpg", data: mediumData)
        LocalFileManager.saveData(withNameAndExtension: "\(imageName)Small.jpg", data: smallData)
    }
    
    @IBAction func refreshTapped(_ sender: Any) {
        activityIndicatiorView.startAnimating()
        refreshButton.isHidden = true
        let string = "https://source.unsplash.com/random"
        guard let url = URL(string: string) else { return }
        
        let destination: DownloadRequest.Destination = { _, _ in
            LocalFileManager.deleteFile(withNameAndExtension: "\(self.imageName).jpg")
            self.imageName = UUID().uuidString
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(self.imageName).jpg")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download(url, to: destination).validate().response { (response) in
            if let error = response.error {
                print(error)
                self.showAlert(alertText: error.localizedDescription)
                return
            }
            
            if let url = response.fileURL {
                print("\(url)")
                self.imageView.af.setImage(withURL: url)
            }
            self.activityIndicatiorView.stopAnimating()
            self.refreshButton.isHidden = false
        }
    }
    
    @IBAction func selectPhotoTapped(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
        present(pickerController, animated: true, completion: nil)
    }
}

//MARK: - Supporting Methods
extension CreatePlaylistViewController {
    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.register(UnsplashImagesCollectionViewCell.self, forCellWithReuseIdentifier: UnsplashImagesCollectionViewCell.cellIdentifier)
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
        nameTextField.bottomLineColor = #colorLiteral(red: 0.8470588235, green: 0.2392156863, blue: 0.1882352941, alpha: 1)
        nameTextField.usernameTextField.addTarget(self, action: #selector(nameDidChanged(_:)), for: .editingChanged)
        searchImageTextField.usernameTextField.addTarget(self, action: #selector(searchImageDidChanged(_:)), for: .editingChanged)
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
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, UnsplashResponse.Result> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: UnsplashImagesCollectionViewCell.cellIdentifier, for: indexPath) as! UnsplashImagesCollectionViewCell
            let imageUrl = self.results[indexPath.item].urls.small
            guard let url = URL(string: imageUrl) else { return cell }
            cell.imageView.af.setImage(withURL: url)
            return cell
        })
        
        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, UnsplashResponse.Result>()
        snapshot.appendSections([0])
        snapshot.appendItems(results)
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
}

//MARK: - UICollectionViewDelegate
extension CreatePlaylistViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = results[indexPath.item]
        guard let url = URL(string: item.urls.regular) else { return }
        imageView.af.setImage(withURL: url)
    }
}

//MARK: - UIImagePickerControllerDelegate
extension CreatePlaylistViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
        }

        dismiss(animated: true, completion: nil)
    }
}
