//
//  ViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 10.01.2021.
//

import UIKit
import CoreData

final class ViewController: UIViewController {

    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var miniPlayerView: UIView!
    
    //MARK: - Properties
    private var miniPlayer: MiniPlayerViewController!
    private var fetchedResultsController: NSFetchedResultsController<Song>!
    private var dataSource: UITableViewDiffableDataSource<Int, Song>!
    private var snapshot: NSDiffableDataSourceSnapshot<Int, Song>!
    private var searchText = ""
    
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let song = miniPlayer.audioplayer.currentSong else { return }
        guard let songIndex = dataSource.indexPath(for: song) else { return }
        tableView.selectRow(at: songIndex, animated: true, scrollPosition: .middle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //UI
        configureSearchBar()
        configureTableView()
        configureMiniPlayer()

        //Data
        setupFetchedResultsController()
        setupDiffableDataSource()
        miniPlayerView.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MiniPlayerViewController {
          miniPlayer = destination
          miniPlayer?.delegate = self
        }
    }
}

//MARK: - Supporting Methods
extension ViewController {    
    private func configureSearchBar() {
        searchBar.delegate = self
        
        searchBar.backgroundImage = UIImage()
        guard let searchTextField: UITextField = searchBar.value(forKey: "searchField") as? UITextField else { return }
        guard let imageView = searchTextField.leftView as? UIImageView else { return }
        searchTextField.textColor = .black
        
        let attributeDict = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.6705882353, green: 0.7254901961, blue: 0.7568627451, alpha: 1)]
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: attributeDict)
        
        imageView.tintColor = #colorLiteral(red: 0.6705882353, green: 0.7254901961, blue: 0.7568627451, alpha: 1)
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        
        searchBar.searchTextField.backgroundColor = .white
    }
    
    private func configureTableView() {
        tableView.delegate = self
        let nib = UINib(nibName: "SongTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "songTableViewCell")
    }
    
    private func configureMiniPlayer() {
        miniPlayerView.layer.shadowColor = #colorLiteral(red: 0.5764705882, green: 0.6588235294, blue: 0.7019607843, alpha: 0.1611958471).cgColor
        miniPlayerView.layer.shadowOffset = CGSize(width: 0, height: -11)
        miniPlayerView.layer.shadowRadius = 9
        miniPlayerView.layer.shadowOpacity = 1
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Song.fetchRequest()
        
        if !searchText.isEmpty {
            request.predicate = NSPredicate(format: "(name CONTAINS[c] %@) OR (author CONTAINS[c] %@)", searchText, searchText)
        }
        
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
        miniPlayer.audioplayer.songs = snapshot.itemIdentifiers
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
    
    private func setupDiffableDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Song>(tableView: tableView, cellProvider: { (tableView, indexPath, song) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "songTableViewCell") as! SongTableViewCell
            
            if let imageUrl = song.thumbnails?.smallUrl {
                cell.songImageView.af.setImage(withURL: imageUrl)
                cell.backgroundBlurImage.af.setImage(withURL: imageUrl)
            }
            cell.titleLabel.text = song.name
            cell.descriptionLabel.text = song.author?.name
            cell.indexLabel.text = String(indexPath.row + 1)
            
            return cell
        })
        setupSnapshot()
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - MiniPlayerDelegate
extension ViewController: MiniPlayerDelegate {
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: "Player", bundle: nil)
        guard let playerController = storyboard.instantiateInitialViewController() as? PlayerViewController else { return }
        playerController.sourceView = miniPlayer
        playerController.audioPlayer = miniPlayer.audioplayer
        playerController.modalPresentationStyle = .currentContext
        present(playerController, animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        miniPlayerView.isHidden = false
        if let song = miniPlayer.audioplayer.currentSong {
            guard let songIndex = dataSource.indexPath(for: song) else { return }
            guard songIndex != indexPath else { return }
        }
        miniPlayer.play(at: indexPath.row)
    }
}

//MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 0.5)
    }
    
    @objc private func search() {
        setupFetchedResultsController()
    }
}
