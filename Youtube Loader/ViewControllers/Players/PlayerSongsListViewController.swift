//
//  PlayerSongsListViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 02.02.2021.
//

import UIKit
import CoreData

final class PlayerSongsListViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var downButton: UIButton!
    
    //MARK: - Properties
    public var sourceProtocol: PlayerSourceProtocol!
    public var songs = [Song]()
    private var filteredSongs = [Song]()
    
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
        guard let song = audioPlayer.currentSong else { return }
        guard let songIndex = dataSource.indexPath(for: song) else { return }
        tableView.selectRow(at: songIndex, animated: true, scrollPosition: .middle)
        tableView.contentInset = .init(top: searchBar.frame.height, left: 0, bottom: 0, right: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //UI
        configureSearchBar()
        configureTableView()
        downButton.layer.cornerRadius = downButton.frame.height / 2
        
        //Data
        setupDiffableDataSource()
    }
    
    //MARK: - Actions
    @IBAction private func downButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - Supporting Methods
extension PlayerSongsListViewController {
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
        let nib = UINib(nibName: "SongTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "songTableViewCell")
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        snapshot.appendSections([0])
        
        if !searchText.isEmpty {
            filteredSongs = songs.filter { $0.name!.range(of: searchText, options: .caseInsensitive) != nil }
        } else {
            filteredSongs = songs
        }
        
        snapshot.appendItems(filteredSongs)
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
    
    private func setupDiffableDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Song>(tableView: tableView, cellProvider: { (tableView, indexPath, song) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "songTableViewCell") as! SongTableViewCell
            cell.configure(name: song.name, author: song.author?.name, imageURL: song.thumbnails?.smallUrl, index: indexPath.row + 1)
            return cell
        })
        setupSnapshot()
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension PlayerSongsListViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - MiniPlayerDelegate
extension PlayerSongsListViewController: MiniPlayerDelegate {
    func didSelectedItem(_ item: Song?) {
        guard let song = item else { return }
        guard let songIndex = dataSource.indexPath(for: song) else { return }
        tableView.selectRow(at: songIndex, animated: true, scrollPosition: .middle)
    }
    
    func expandSong(song: Song?) {
        let storyboard = UIStoryboard(name: "Player", bundle: nil)
        guard let playerController = storyboard.instantiateInitialViewController() as? PlayerViewController else { return }
        playerController.sourceProtocol = sourceProtocol
        playerController.modalPresentationStyle = .currentContext
        present(playerController, animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate
extension PlayerSongsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        audioPlayer.setupPlayer(at: indexPath.row)
    }
}

//MARK: - UISearchBarDelegate
extension PlayerSongsListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 0.5)
    }
    
    @objc private func search() {
        setupSnapshot()
    }
}
