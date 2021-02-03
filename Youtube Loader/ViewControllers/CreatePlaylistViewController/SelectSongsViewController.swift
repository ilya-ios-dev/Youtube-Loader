//
//  SelectSongsViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 28.01.2021.
//

import UIKit
import CoreData

protocol SelectSongsViewControllerDelegate: class {
    func didSaveSelectedSongs(_ songs: [Song])
}

final class SelectSongsViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - Properties
    public weak var delegate: SelectSongsViewControllerDelegate?
    public var selectedSongs = [Song]()

    private var tableDataSource: UITableViewDiffableDataSource<Int, Song>!
    private var tableSnapshot: NSDiffableDataSourceSnapshot<Int, Song>!
    private var songs = [Song]()
    private var searchText = ""
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearchBar()
        configureTableView()
        setupTableDataSource()
        fetchSongs()
        
        let rightItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveSongs))
        navigationItem.setRightBarButton(rightItem, animated: true)
        
        tableView.contentInset = .init(top: searchBar.frame.height, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func saveSongs() {
        delegate?.didSaveSelectedSongs(selectedSongs)
        navigationController?.popToRootViewController(animated: true)
    }
    
}

//MARK: - Supporting Methods
extension SelectSongsViewController {
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
    
    private func fetchSongs() {
        let fetchRequest: NSFetchRequest = Song.fetchRequest()
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        if !searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "(name CONTAINS[c] %@) OR (author.name CONTAINS[c] %@)", searchText, searchText)
        }
        
        do {
            songs = try context.fetch(fetchRequest)
            setupTableSnapshot()
        } catch {
            print(error)
        }
    }
    
    private func configureTableView() {
        tableView.delegate = self
        let nib = UINib(nibName: String(describing: SelectArtistAlbumSongTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SelectArtistAlbumSongTableViewCell.cellIdentifier)
    }
    
    private func setupTableSnapshot() {
        tableSnapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        tableSnapshot.appendSections([0])
        tableSnapshot.appendItems(songs)
        DispatchQueue.main.async {
            self.tableDataSource?.apply(self.tableSnapshot, animatingDifferences: true)
            
            self.selectedSongs.forEach { (song) in
                let index = self.tableDataSource.indexPath(for: song)
                self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
            }
        }
    }
    
    private func setupTableDataSource() {
        tableDataSource = UITableViewDiffableDataSource<Int, Song>(tableView: tableView, cellProvider: { (tableView, indexPath, song) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: SelectArtistAlbumSongTableViewCell.cellIdentifier) as! SelectArtistAlbumSongTableViewCell
            
            if let imageUrl = song.thumbnails?.smallUrl {
                cell.songImageView.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "music_placeholder"))
                cell.backgroundBlurImage.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "music_placeholder"))
            }
            cell.titleLabel.text = song.name
            cell.descriptionLabel.text = song.author?.name
            cell.indexLabel.text = String(indexPath.row + 1)
            return cell
        })
        setupTableSnapshot()
    }
    
}

//MARK: - UITableViewDelegate
extension SelectSongsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedRows = tableView.indexPathsForSelectedRows, selectedRows.contains(indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            if let index = selectedSongs.firstIndex(of: songs[indexPath.row]) {
                selectedSongs.remove(at: index)
            }
            return nil
        }
        
        selectedSongs.append(songs[indexPath.row])
        return indexPath
    }
}

//MARK: - UISearchBarDelegate
extension SelectSongsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        fetchSongs()
    }
}
