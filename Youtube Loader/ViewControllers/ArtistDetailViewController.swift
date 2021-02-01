//
//  ArtistDetailViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 31.01.2021.
//

import UIKit
import CoreData

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
    
    private var imageView: UIImageView!
    private var headerContainerView: UIView!
    private var songs = [Song]()
    private var miniPlayer: MiniPlayerViewController!
    private var songsCollectionView: SongsCollectionViewController!
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
        guard let song = sourceProtocol.audioPlayer.currentSong else { return }
        songsCollectionView.selectItem(song)
        miniPlayerView.isHidden = false
        miniPlayerBottomView.isHidden = false
        scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + view.safeAreaInsets.bottom + 16, right: 0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        downButton.layer.cornerRadius = downButton.frame.height / 2
        configureSearchBar()
        scrollView.contentInset = .init(top: 0, left: 0, bottom: view.safeAreaInsets.bottom + 16, right: 0)
        configureMiniPlayer()
        miniPlayer?.songs = songs
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
            // SongsList
        } else if let destination = segue.destination as? SongsListViewController {
            destination.sourceProtocol = sourceProtocol
        }
    }
    
    @IBAction func downButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func songsListTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SongsList", bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? SongsListViewController else { return }
        vc.sourceProtocol = sourceProtocol
        present(vc, animated: true, completion: nil)
    }
}

//MARK: - Supporting Methods
extension ArtistDetailViewController {
    
    private func configureMiniPlayer() {
        miniPlayerView.isHidden = true
        miniPlayerView.layer.shadowColor = #colorLiteral(red: 0.5764705882, green: 0.6588235294, blue: 0.7019607843, alpha: 0.1611958471).cgColor
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
        searchTextField.textColor = .black
        
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
    
}

//MARK: - MiniPlayerDelegate
extension ArtistDetailViewController: MiniPlayerDelegate {
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: "Player", bundle: nil)
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
        miniPlayer?.songs = songs
    }
    
    func didSelectedItemAt(_ index: Int) {
        miniPlayer.play(at: index)
    }
}
