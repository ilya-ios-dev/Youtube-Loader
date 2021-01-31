//
//  SelectArtistViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 29.01.2021.
//

import UIKit
import CoreData

protocol SelectArtistViewControllerDelegate: class {
    func didSaveSelectedArtist(_ artist: Artist)
}

final class SelectArtistViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - Properties
    public weak var delegate: SelectArtistViewControllerDelegate?
    public var selectedArtist: Artist?

    private var tableDataSource: UITableViewDiffableDataSource<Int, Artist>!
    private var tableSnapshot: NSDiffableDataSourceSnapshot<Int, Artist>!
    private var artists = [Artist]()
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
        fetchartists()
        
        let rightItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveArtist))
        navigationItem.setRightBarButton(rightItem, animated: true)
        
        tableView.contentInset = .init(top: searchBar.frame.height, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func saveArtist() {
        if let artist = selectedArtist {
            delegate?.didSaveSelectedArtist(artist)
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
}

//MARK: - Supporting Methods
extension SelectArtistViewController {
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
    
    private func fetchartists() {
        let fetchRequest: NSFetchRequest = Artist.fetchRequest()
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        if !searchText.isEmpty {
            fetchRequest.predicate = NSPredicate(format: "(name CONTAINS[c] %@) OR (author.name CONTAINS[c] %@)", searchText, searchText)
        }
        
        do {
            artists = try context.fetch(fetchRequest)
            setupTableSnapshot()
        } catch {
            print(error)
        }
    }
    
    private func configureTableView() {
        tableView.delegate = self
        let nib = UINib(nibName: "SelectArtistAlbumSongTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "selectArtistTableViewCell")
    }
    
    private func setupTableSnapshot() {
        tableSnapshot = NSDiffableDataSourceSnapshot<Int, Artist>()
        tableSnapshot.appendSections([0])
        tableSnapshot.appendItems(artists)
        DispatchQueue.main.async {
            self.tableDataSource?.apply(self.tableSnapshot, animatingDifferences: true)
            
            guard let artist = self.selectedArtist else { return }
            let index = self.tableDataSource.indexPath(for: artist)
            self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        }
    }
    
    private func setupTableDataSource() {
        tableDataSource = UITableViewDiffableDataSource<Int, Artist>(tableView: tableView, cellProvider: { (tableView, indexPath, song) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "selectArtistTableViewCell") as! SelectArtistAlbumSongTableViewCell
            
            if let imageUrl = song.thumbnails?.smallUrl {
                cell.songImageView.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "artist_placeholder"))
                cell.backgroundBlurImage.af.setImage(withURL: imageUrl, placeholderImage: #imageLiteral(resourceName: "artist_placeholder"))
            }
            cell.titleLabel.text = song.name
            cell.descriptionLabel.isHidden = true
            cell.indexLabel.text = String(indexPath.row + 1)
            return cell
        })
        setupTableSnapshot()
    }
    
}

//MARK: - UITableViewDelegate
extension SelectArtistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedArtist = artists[indexPath.row]
    }
}

//MARK: - UISearchBarDelegate
extension SelectArtistViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        fetchartists()
    }
}
