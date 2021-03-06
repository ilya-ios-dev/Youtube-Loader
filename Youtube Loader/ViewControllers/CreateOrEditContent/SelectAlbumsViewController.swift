//
//  SelectAlbumsViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 29.01.2021.
//

import UIKit
import CoreData

protocol SelectAlbumsViewControllerDelegate: class {
    func didSaveSelectedAlbums(_ albums: [Album])
    func didSaveSelectedAlbum(_ album: Album?)
}

/// A view controller that specializes in displaying and selecting an album for the entity being created.
final class SelectAlbumsViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - Properties
    public weak var delegate: SelectAlbumsViewControllerDelegate?
    public var selectedAlbums = [Album]()
    public var selectedAlbum: Album?
    public var isMultipleSelectionAllowed = true
    
    private var tableDataSource: UITableViewDiffableDataSource<Int, Album>!
    private var tableSnapshot: NSDiffableDataSourceSnapshot<Int, Album>!
    private var albums = [Album]()
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
        fetchAlbums()
        
        let rightItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveAlbums))
        navigationItem.setRightBarButton(rightItem, animated: true)
        tableView.allowsMultipleSelection = isMultipleSelectionAllowed
        tableView.contentInset = .init(top: searchBar.frame.height, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func saveAlbums() {
        if isMultipleSelectionAllowed {
            delegate?.didSaveSelectedAlbums(selectedAlbums)
        } else {
            delegate?.didSaveSelectedAlbum(selectedAlbum)
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
}

//MARK: - Supporting Methods
extension SelectAlbumsViewController {
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
    
    private func fetchAlbums() {
        let fetchRequest: NSFetchRequest = Album.fetchRequest()
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        if !searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "(name CONTAINS[c] %@) OR (author.name CONTAINS[c] %@)", searchText, searchText)
        }
        
        do {
            albums = try context.fetch(fetchRequest)
            setupTableSnapshot()
        } catch {
            print(error)
        }
    }
    
    private func configureTableView() {
        tableView.delegate = self
        let nib = UINib(nibName: String(describing: SelectingContentTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SelectingContentTableViewCell.cellIdentifier)
    }
    
    private func setupTableSnapshot() {
        tableSnapshot = NSDiffableDataSourceSnapshot<Int, Album>()
        tableSnapshot.appendSections([0])
        tableSnapshot.appendItems(albums)
        DispatchQueue.main.async {
            self.tableDataSource?.apply(self.tableSnapshot, animatingDifferences: true)
            self.selectAlbum()
        }
    }
    
    private func selectAlbum() {
        if isMultipleSelectionAllowed {
            selectedAlbums.forEach { (album) in
                let index = tableDataSource.indexPath(for: album)
                tableView.selectRow(at: index, animated: false, scrollPosition: .none)
            }
        } else {
            guard let album = selectedAlbum else { return }
            let index = tableDataSource.indexPath(for: album)
            tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        }
    }
    
    private func setupTableDataSource() {
        tableDataSource = UITableViewDiffableDataSource<Int, Album>(tableView: tableView, cellProvider: { (tableView, indexPath, album) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: SelectingContentTableViewCell.cellIdentifier) as! SelectingContentTableViewCell
            
            cell.configure(name: album.name, description: nil, url: album.thumbnails?.smallUrl, index: indexPath.row + 1)
            return cell
        })
        setupTableSnapshot()
    }
    
}

//MARK: - UITableViewDelegate
extension SelectAlbumsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedRows = tableView.indexPathsForSelectedRows, selectedRows.contains(indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            if let index = selectedAlbums.firstIndex(of: albums[indexPath.row]) {
                selectedAlbums.remove(at: index)
            }
            return nil
        }
        
        selectedAlbums.append(albums[indexPath.row])
        return indexPath
    }
}

//MARK: - UISearchBarDelegate
extension SelectAlbumsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        fetchAlbums()
    }
}
