//
//  ArtistCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

protocol ArtistCollectionViewControllerDelegate: class {
    func didSelectedArtist(_ artist: Artist)
}

final class ArtistCollectionViewController: UICollectionViewController {

    //MARK: - Properties
    public weak var delegate: ArtistCollectionViewControllerDelegate?
    
    private static let leadingKind = "Artist.leading"
    private var dataSource: UICollectionViewDiffableDataSource<Int, Artist>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, Artist>()
    private var fetchedResultsController: NSFetchedResultsController<Artist>!
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSongCollectionView()
        setupFetchedResultsController()
        configureDataSource()
    }
}

//MARK: - Supporting Methods
extension ArtistCollectionViewController {
    
    private func configureSongCollectionView() {
        let cellNib = UINib(nibName: String(describing: ArtistCollectionViewCell.self), bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: ArtistCollectionViewCell.cellIdentifier)
        collectionView.register(AddingCollectionReusableView.self, forSupplementaryViewOfKind: ArtistCollectionViewController.leadingKind, withReuseIdentifier: AddingCollectionReusableView.reuseIdentifier)
        collectionView.collectionViewLayout = configureSongLayout()
    }
    
    private func configureSongLayout() -> UICollectionViewLayout {
        let section: NSCollectionLayoutSection
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(150), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let leftSize = NSCollectionLayoutSize(widthDimension: .absolute(150.0), heightDimension: .fractionalHeight(1))
        let left = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: leftSize,
                                                               elementKind: ArtistCollectionViewController.leadingKind,
                                                               alignment: .leading)
        
        section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [left]
        section.supplementariesFollowContentInsets = true
        section.interGroupSpacing = 16
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        
        return layout
    }
    
    private func configureDataSource() {
        
        dataSource = UICollectionViewDiffableDataSource<Int, Artist> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: ArtistCollectionViewCell.cellIdentifier, for: indexPath) as! ArtistCollectionViewCell
            cell.configure(title: item.name, url: item.thumbnails?.mediumUrl)
            return cell
        })
        
        dataSource.supplementaryViewProvider = {(
            collectionView: UICollectionView, kind: String, indexPath: IndexPath) -> UICollectionReusableView? in
            let addingView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AddingCollectionReusableView.reuseIdentifier, for: indexPath) as! AddingCollectionReusableView
            addingView.button.addTarget(self, action: #selector(self.createPlaylistTapped), for: .touchUpInside)
            return addingView
        }
        setupSnapshot()
    }
    
    @objc private func createPlaylistTapped() {
        let storyboard = UIStoryboard(name: Storyboards.createOrEditContent, bundle: nil)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
        guard let vc = navigationController.topViewController as? CreateOrEditContentViewController else { return }
        vc.contentType = .artist
        present(navigationController, animated: true, completion: nil)
    }

    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Artist>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource.apply(self.snapshot, animatingDifferences: true) {
                self.dataSource.apply(self.snapshot, animatingDifferences: false)
            }
        }
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Artist.fetchRequest()
        
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            setupSnapshot()
        } catch {
            showAlert(alertText: error.localizedDescription)
        }
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension ArtistCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - UICollectionViewDelegate
extension ArtistCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let artist = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.didSelectedArtist(artist)
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if let cellItemIdentifier = dataSource.itemIdentifier(for: indexPath) {
            let identifier = NSString(string: String(describing: cellItemIdentifier))
            return UIContextMenuConfiguration(identifier: identifier, previewProvider: nil, actionProvider: { suggestedActions in
                let editAction = self.editAction(indexPath)
                let deleteAction = self.deleteAction(indexPath)
                return UIMenu(title: "", children: [editAction, deleteAction])
            })
            
        } else {
            return nil
        }
    }
    
    private func editAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: "Edit",
                        image: UIImage(systemName: "square.and.pencil")) { action in
            
            let storyboard = UIStoryboard(name: Storyboards.createOrEditContent, bundle: nil)
            guard let editingItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
            guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
            guard let vc = navigationController.topViewController as? CreateOrEditContentViewController else { return }
            vc.contentType = .artist
            vc.editingContent = editingItem
            self.present(navigationController, animated: true, completion: nil)
        }
    }

    private func deleteAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
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
        }
    }
}
