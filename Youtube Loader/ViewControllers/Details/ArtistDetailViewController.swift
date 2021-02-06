//
//  ArtistDetailViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 31.01.2021.
//

import UIKit
import CoreData

/// A view controller that specializes in displaying a list of all songs and albums by an artist
final class ArtistDetailViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var downButton: UIButton!
    @IBOutlet private weak var miniPlayerView: UIView!
    @IBOutlet private weak var miniPlayerBottomView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var stackView: UIStackView!
    
    //MARK: - Properties
    public var artist: Artist!
    public var sourceProtocol: PlayerSourceProtocol!
    
    private var searchText = ""
    private var imageView: UIImageView!
    private var headerContainerView: UIView!
    private var songs = [Song]()
    private var miniPlayer: MiniPlayerViewController!
    private var songsCollectionView: SongsCollectionViewController!
    private var albumsCollectionView: AlbumsCollectionViewController!
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // If the song is in the audio player, then the player should be shown
        scrollView.contentInset = .init(top: 0, left: 0, bottom: scrollView.contentInset.bottom + 16, right: 0)
        guard let song = sourceProtocol.audioPlayer.currentSong else { return }
        songsCollectionView.selectItem(song)
        miniPlayerView.isHidden = false
        miniPlayerBottomView.isHidden = false
        scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + miniPlayerBottomView.frame.height + 16, right: 0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        downButton.layer.cornerRadius = downButton.frame.height / 2
        configureSearchBar()
        configureMiniPlayer()
        configureHeaderView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // MiniPlayer
        if let destination = segue.destination as? MiniPlayerViewController {
            miniPlayer = destination
            miniPlayer.sourceProtocol = sourceProtocol
            miniPlayer?.delegate = self
            // SongsCollectionView
        } else if let destination = segue.destination as? SongsCollectionViewController {
            songsCollectionView = destination
            songsCollectionView.delegate = self
            let authorPredicate = NSPredicate(format: "author == %@", artist)
            songsCollectionView.predicate = NSCompoundPredicate(type: .and, subpredicates: [authorPredicate])
            // AlbumsCollectionView
        } else if let destination = segue.destination as? AlbumsCollectionViewController {
            albumsCollectionView = destination
            albumsCollectionView.delegate = self
            let authorPredicate = NSPredicate(format: "author == %@", artist)
            albumsCollectionView.predicate = NSCompoundPredicate(type: .and, subpredicates: [authorPredicate])
        }
    }
    
    @IBAction func downButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func songsListTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: Storyboards.songsList, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? SongsListViewController else { return }
        vc.sourceProtocol = sourceProtocol
        vc.artist = artist
        present(vc, animated: true, completion: nil)
    }
}

//MARK: - Supporting Methods
extension ArtistDetailViewController {
    
    private func configureMiniPlayer() {
        miniPlayerView.isHidden = true
        miniPlayerView.layer.shadowColor = Colors.darkTintColor.withAlphaComponent(0.13).cgColor
        miniPlayerView.layer.shadowOffset = CGSize(width: 0, height: -11)
        miniPlayerView.layer.shadowRadius = 9
        miniPlayerView.layer.shadowOpacity = 1
    }

    private func configureHeaderView() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        if let url = artist.thumbnails?.largeUrl {
            imageView.af.setImage(withURL: url)
        }
        
        headerContainerView = UIView()
        
        scrollView.addSubview(headerContainerView)
        headerContainerView.addSubview(imageView)
        
        // Header Container Constraints
        let headerContainerViewBottom : NSLayoutConstraint!
        
        self.headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.headerContainerView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.headerContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.headerContainerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        headerContainerViewBottom = self.headerContainerView.bottomAnchor.constraint(equalTo: self.stackView.topAnchor, constant: -10)
        headerContainerViewBottom.priority = UILayoutPriority(rawValue: 900)
        headerContainerViewBottom.isActive = true
        
        // ImageView Constraints
        let imageViewTopConstraint: NSLayoutConstraint!
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.leadingAnchor.constraint(equalTo: self.headerContainerView.leadingAnchor),
            self.imageView.trailingAnchor.constraint(equalTo: self.headerContainerView.trailingAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.headerContainerView.bottomAnchor)
        ])
        
        imageViewTopConstraint = self.imageView.topAnchor.constraint(equalTo: self.view.topAnchor)
        imageViewTopConstraint.priority = UILayoutPriority(rawValue: 900)
        imageViewTopConstraint.isActive = true
    }

    private func configureSearchBar() {
        searchBar.delegate = self
        
        searchBar.backgroundImage = UIImage()
        guard let searchTextField: UITextField = searchBar.value(forKey: "searchField") as? UITextField else { return }
        guard let imageView = searchTextField.leftView as? UIImageView else { return }
        searchTextField.textColor = .white
        
        let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.white]
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: attributeDict)
        
        imageView.tintColor = UIColor.white
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        
        searchBar.searchTextField.backgroundColor = .clear
        let view = UIVisualEffectView()
        view.effect = UIBlurEffect(style: .regular)
        view.backgroundColor = UIColor.white.withAlphaComponent(0)
        view.clipsToBounds = true
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        searchBar.insertSubview(view, at: 0)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: searchTextField.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: searchTextField.bottomAnchor),
            view.topAnchor.constraint(equalTo: searchTextField.topAnchor)
        ])
    }
}

//MARK: - UISearchBarDelegate
extension ArtistDetailViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 0.5)
    }
    
    @objc private func search() {
        let andPredicate: NSCompoundPredicate
        
        if searchText.isEmpty {
            let authorPredicate = NSPredicate(format: "author == %@", artist)
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [authorPredicate])
        } else {
            let namePredicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
            let authorPredicate = NSPredicate(format: "author == %@", artist)
            andPredicate = NSCompoundPredicate(type: .and, subpredicates: [authorPredicate, namePredicate])
        }
        
        albumsCollectionView.predicate = andPredicate
        albumsCollectionView.reloadData()
        
        songsCollectionView.predicate = andPredicate
        songsCollectionView.reloadData()
    }
}

//MARK: - MiniPlayerDelegate
extension ArtistDetailViewController: MiniPlayerDelegate {
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: Storyboards.player, bundle: nil)
        guard let playerController = storyboard.instantiateInitialViewController() as? PlayerViewController else { return }
        playerController.sourceProtocol = sourceProtocol
        playerController.modalPresentationStyle = .currentContext
        present(playerController, animated: true, completion: nil)
    }
    
    func didSelectedItem(_ item: Song?) {
        guard let song = item else { return }
        songsCollectionView.selectItem(song)
        if miniPlayerView.isHidden {
            scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + view.safeAreaInsets.bottom + 16, right: 0)
            
            UIView.transition(with: miniPlayerView, duration: 0.325, options: .transitionCrossDissolve) {
                self.miniPlayerView.isHidden = false
                self.miniPlayerBottomView.isHidden = false
            } completion: { (_) in }
        }
    }
}

//MARK: - SongsCollectionViewControllerDelegate
extension ArtistDetailViewController: SongsCollectionViewControllerDelegate {
    func updateSongsArray(_ songs: [Song]) {
        self.songs = songs
    }
    
    func didSelectedItemAt(_ index: Int) {
        if miniPlayer.songs != songs {
            miniPlayer.songs = songs
        }
        miniPlayer.play(at: index)
    }
}

//MARK: - AlbumsCollectionViewControllerDelegate
extension ArtistDetailViewController: AlbumsCollectionViewControllerDelegate {
    func didSelectedAlbum(_ album: Album) {
        let storyboard = UIStoryboard(name: Storyboards.albumDetail, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? AlbumDetailViewController else { return }
        vc.sourceProtocol = sourceProtocol
        vc.album = album
        vc.modalPresentationStyle = .fullScreen
        show(vc, sender: true)
    }
}
