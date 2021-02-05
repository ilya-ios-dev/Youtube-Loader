//
//  ViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 10.01.2021.
//

import UIKit
import CoreData

final class SongsListViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var miniPlayerView: UIView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var downButton: UIButton!
    
    //MARK: - Properties
    public var sourceProtocol: PlayerSourceProtocol!
    public var artist: Artist?
    
    private var miniPlayer: MiniPlayerViewController!
    private var fetchedResultsController: NSFetchedResultsController<Song>!
    private var dataSource: UITableViewDiffableDataSource<Int, Song>!
    private var snapshot: NSDiffableDataSourceSnapshot<Int, Song>!
    private var searchText = ""
    private var audioPlayer: AudioPlayer {
        return sourceProtocol.audioPlayer
    }
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSelectedSong()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //UI
        configureSearchBar()
        configureTableView()
        configureMiniPlayer()
        miniPlayerView.isHidden = true
        bottomView.isHidden = true
        downButton.layer.cornerRadius = downButton.frame.height / 2
        tableView.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top + searchBar.frame.height,
                                              left: 0,
                                              bottom: view.safeAreaInsets.bottom,
                                              right: 0)

        //Data
        setupFetchedResultsController()
        setupDiffableDataSource()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MiniPlayerViewController {
            miniPlayer = destination
            miniPlayer.sourceProtocol = sourceProtocol
            miniPlayer?.delegate = self
        }
    }
    
    //MARK: - Actions
    @IBAction private func downButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - Supporting Methods
extension SongsListViewController {
    
    private func configureSelectedSong() {
        guard let song = audioPlayer.currentSong else { return }
        guard let songIndex = dataSource.indexPath(for: song) else { return }
        tableView.selectRow(at: songIndex, animated: true, scrollPosition: .top)
        miniPlayerView.isHidden = false
        bottomView.isHidden = false
        tableView.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top + searchBar.frame.height,
                                              left: 0,
                                              bottom: miniPlayerView.frame.height + 16 + view.safeAreaInsets.bottom,
                                              right: 0)
    }
    
    private func configureSearchBar() {
        searchBar.delegate = self
        
        searchBar.backgroundImage = UIImage()
        guard let searchTextField: UITextField = searchBar.value(forKey: "searchField") as? UITextField else { return }
        guard let imageView = searchTextField.leftView as? UIImageView else { return }
        searchTextField.textColor = .black
        
        let attributeDict = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: attributeDict)
        
        imageView.tintColor = UIColor.lightGray
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        
        searchBar.searchTextField.backgroundColor = .clear
        let view = UIVisualEffectView()
        view.effect = UIBlurEffect(style: .regular)
        view.backgroundColor = UIColor.white.withAlphaComponent(0.85)
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
    
    private func configureTableView() {
        tableView.delegate = self
        let nib = UINib(nibName: String(describing: SongTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SongTableViewCell.cellIdentifier)
    }
    
    private func configureMiniPlayer() {
        miniPlayerView.layer.shadowColor = Colors.darkTintColor.withAlphaComponent(0.13).cgColor
        miniPlayerView.layer.shadowOffset = CGSize(width: 0, height: -11)
        miniPlayerView.layer.shadowRadius = 9
        miniPlayerView.layer.shadowOpacity = 1
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Song.fetchRequest()
        
        var searchPredicate: NSPredicate?
        var artistPredicate: NSPredicate?
        if !searchText.isEmpty {
            searchPredicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
        }
        if let artist = artist {
            artistPredicate = NSPredicate(format: "author == %@", artist)
        }
        
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [searchPredicate, artistPredicate].compactMap{ $0 })
        
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            setupSnapshot()
        } catch {
            print(error)
        }
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true) {
                self.dataSource?.apply(self.snapshot, animatingDifferences: false)
            }
        }
    }
    
    private class DataSource: UITableViewDiffableDataSource<Int, Song> {
        // editing support
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
    }
    
    private func setupDiffableDataSource() {
        dataSource = DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, song) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: SongTableViewCell.cellIdentifier) as! SongTableViewCell
            cell.configure(name: song.name, author: song.author?.name, imageURL: song.thumbnails?.smallUrl, index: indexPath.row + 1)
            return cell
        })
        setupSnapshot()
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension SongsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - MiniPlayerDelegate
extension SongsListViewController: MiniPlayerDelegate {
    func didSelectedItem(_ item: Song?) {
        guard let song = item else { return }
        guard let songIndex = dataSource.indexPath(for: song) else { return }
        tableView.selectRow(at: songIndex, animated: true, scrollPosition: .middle)
    }
    
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: Storyboards.player, bundle: nil)
        guard let playerController = storyboard.instantiateInitialViewController() as? PlayerViewController else { return }
        playerController.sourceProtocol = sourceProtocol
        playerController.modalPresentationStyle = .currentContext
        present(playerController, animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate
extension SongsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if miniPlayer.songs != snapshot.itemIdentifiers {
            miniPlayer.songs = snapshot.itemIdentifiers
        }
        miniPlayer.play(at: indexPath.row)
        
        if miniPlayerView.isHidden {
            tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top, left: 0, bottom: miniPlayerView.frame.height + 16, right: 0)
            
            UIView.transition(with: miniPlayerView, duration: 0.3, options: .transitionCrossDissolve) {
                self.miniPlayerView.isHidden = false
                self.bottomView.isHidden = false
            } completion: { (_) in }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (_, _, completionHandler) in
            let storyboard = UIStoryboard(name: Storyboards.createOrEditContent, bundle: nil)
            guard let editingItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
            guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
            guard let vc = navigationController.topViewController as? CreateOrEditContentViewController else { return }
            vc.contentType = .song
            vc.editingContent = editingItem
            self.present(navigationController, animated: true, completion: nil)
            completionHandler(true)
        }
        editAction.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        editAction.image = UIImage(systemName: "square.and.pencil")
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
        
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
            guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
            if let thumbnail = item.thumbnails {
                thumbnail.removeImages()
                self.context.delete(thumbnail)
            }
            self.context.delete(item)

            do {
                try self.context.save()
            } catch {
                print(error)
                self.showAlert(alertText: error.localizedDescription)
            }
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

//MARK: - UISearchBarDelegate
extension SongsListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 0.5)
    }
    
    @objc private func search() {
        setupFetchedResultsController()
    }
}
