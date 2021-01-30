//
//  MainViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

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
        guard miniPlayer.audioplayer.currentSong != nil else { return }
        miniPlayerView.isHidden = false
    }
    
    override func viewDidLoad() {
        configureMiniPlayer()
        miniPlayer?.songs = songs
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // MiniPlayer
        if let destination = segue.destination as? MiniPlayerViewController {
          miniPlayer = destination
          miniPlayer?.delegate = self
        // SongsCollectionView
        } else if let destination = segue.destination as? SongsCollectionViewController {
            songsCollectionView = destination
            songsCollectionView.delegate = self
        // SongsList
        } else if let destination = segue.destination as? SongsListViewController {
            destination.audioPlayer = miniPlayer.audioplayer
        }
    }
    
    private func configureMiniPlayer() {
        miniPlayerView.isHidden = true
        miniPlayerView.layer.shadowColor = #colorLiteral(red: 0.5764705882, green: 0.6588235294, blue: 0.7019607843, alpha: 0.1611958471).cgColor
        miniPlayerView.layer.shadowOffset = CGSize(width: 0, height: -11)
        miniPlayerView.layer.shadowRadius = 9
        miniPlayerView.layer.shadowOpacity = 1
    }
}

//MARK: - MiniPlayerDelegate
extension MainViewController: MiniPlayerDelegate {
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: "Player", bundle: nil)
        guard let playerController = storyboard.instantiateInitialViewController() as? PlayerViewController else { return }
        playerController.sourceView = miniPlayer
        playerController.audioPlayer = miniPlayer.audioplayer
        playerController.modalPresentationStyle = .currentContext
        present(playerController, animated: true, completion: nil)
    }
}

//MARK: - SongsCollectionViewControllerDelegate
extension MainViewController: SongsCollectionViewControllerDelegate {
    func updateSongsArray(_ songs: [Song]) {
        self.songs = songs
        miniPlayer?.songs = songs
    }
    
    func didSelectedItemAt(_ index: Int) {
        miniPlayer.play(at: index)
        
        if miniPlayerView.isHidden {
            scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + 8, right: 0)
            
            UIView.transition(with: miniPlayerView, duration: 0.3, options: .transitionCrossDissolve) {
                self.miniPlayerView.isHidden = false
            } completion: { (_) in }
        }
    }
}
