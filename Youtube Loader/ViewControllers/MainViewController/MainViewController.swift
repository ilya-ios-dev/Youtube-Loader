//
//  MainViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

/// In this application, a player can be open on many screens, so the child and parent views,
/// in which the song can be selected, must contain a field to pass the `shared audioplayer`.
/// There is only one `AudioPlayer` in this application, and it only initializes on the first screen.
protocol PlayerSourceProtocol: class {
    var audioPlayer: AudioPlayer { get }
}

/// The main in-app view controller that specializes in displaying all songs, albums, artists, playlists and recommendations
final class MainViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var songsContainerView: UIView!
    @IBOutlet private weak var albumsContainerView: UIView!
    @IBOutlet private weak var artistsContainerView: UIView!
    @IBOutlet private weak var playlistsContainerView: UIView!
    @IBOutlet private weak var recommendationsContainerView: UIView!
    @IBOutlet private weak var miniPlayerView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    //MARK: - Properties
    private var songs = [Song]()
    private var miniPlayer: MiniPlayerViewController!
    private var songsCollectionView: SongsCollectionViewController!
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // If the song is in the audio player, then the player should be shown
        guard let song = audioPlayer.currentSong else { return }
        songsCollectionView.selectItem(song)
        miniPlayerView.isHidden = false
        scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + 8, right: 0)
    }
    
    override func viewDidLoad() {
        configureMiniPlayer()
        configureTabBarSubview()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // MiniPlayer
        if let destination = segue.destination as? MiniPlayerViewController {
            miniPlayer = destination
            miniPlayer.sourceProtocol = self
            miniPlayer?.delegate = self
            // SongsCollectionView
        } else if let destination = segue.destination as? SongsCollectionViewController {
            songsCollectionView = destination
            songsCollectionView.delegate = self
            // SongsList
        } else if let destination = segue.destination as? SongsListViewController {
            destination.sourceProtocol = self
            // ArtistCollectionView
        } else if let destination = segue.destination as? ArtistCollectionViewController {
            destination.delegate = self
            // AlbumsCollection
        } else if let destination = segue.destination as? AlbumsCollectionViewController {
            destination.delegate = self
            // PlaylistCollection
        } else if let destination = segue.destination as? PlaylistCollectionViewController {
            destination.delegate = self
        }
    }
    
    private func configureMiniPlayer() {
        miniPlayerView.isHidden = true
        miniPlayerView.layer.shadowColor = Colors.darkTintColor.withAlphaComponent(0.13).cgColor
        miniPlayerView.layer.shadowOffset = CGSize(width: 0, height: -11)
        miniPlayerView.layer.shadowRadius = 9
        miniPlayerView.layer.shadowOpacity = 1
    }
    
    private func configureTabBarSubview() {
        guard let tabBar = tabBarController?.tabBar else { return }
        let barView = UIView()
        barView.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        tabBarController?.view.insertSubview(barView, belowSubview: tabBar)
        barView.fillView(tabBar)
    }
}

//MARK: - MiniPlayerDelegate
extension MainViewController: MiniPlayerDelegate {
    func didSelectedItem(_ item: Song?) {
        guard let song = item else { return }
        songsCollectionView.selectItem(song)
        if miniPlayerView.isHidden {
            scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + 8, right: 0)
            
            UIView.transition(with: miniPlayerView, duration: 0.3, options: .transitionCrossDissolve) {
                self.miniPlayerView.isHidden = false
            } completion: { (_) in }
        }
    }
    
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: Storyboards.player, bundle: nil)
        guard let playerController = storyboard.instantiateInitialViewController() as? PlayerViewController else { return }
        playerController.sourceProtocol = self
        playerController.modalPresentationStyle = .currentContext
        present(playerController, animated: true, completion: nil)
    }
}

//MARK: - SongsCollectionViewControllerDelegate
extension MainViewController: SongsCollectionViewControllerDelegate {
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

//MARK: - ArtistCollectionViewControllerDelegate
extension MainViewController: ArtistCollectionViewControllerDelegate {
    func didSelectedArtist(_ artist: Artist) {
        let storyboard = UIStoryboard(name: Storyboards.artistDetail, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? ArtistDetailViewController else { return }
        vc.artist = artist
        vc.sourceProtocol = self
        vc.modalPresentationStyle = .fullScreen
        show(vc, sender: true)
    }
}

//MARK: - AlbumsCollectionViewController
extension MainViewController: AlbumsCollectionViewControllerDelegate {
    func didSelectedAlbum(_ album: Album) {
        let storyboard = UIStoryboard(name: Storyboards.albumDetail, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? AlbumDetailViewController else { return }
        vc.sourceProtocol = self
        vc.album = album
        vc.modalPresentationStyle = .fullScreen
        show(vc, sender: true)
    }
}

//MARK: - PlaylistCollectionViewControllerDelegate
extension MainViewController: PlaylistCollectionViewControllerDelegate {
    func didSelectedPlaylist(_ playlist: Playlist) {
        let storyboard = UIStoryboard(name: Storyboards.playlistDetail, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() as? PlaylistDetailViewController else { return }
        vc.sourceProtocol = self
        vc.playlist = playlist
        vc.modalPresentationStyle = .fullScreen
        show(vc, sender: true)
    }
}

//MARK: - PlayerSourceProtocol
extension MainViewController: PlayerSourceProtocol {
    var audioPlayer: AudioPlayer {
        return AudioPlayer.shared
    }
}
