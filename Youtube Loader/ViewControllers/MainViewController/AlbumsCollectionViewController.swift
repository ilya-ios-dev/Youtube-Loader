//
//  AlbumsCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

protocol AlbumsCollectionViewControllerDelegate: class {
    func didSelectedAlbum(_ album: Album)
}

final class AlbumsCollectionViewController: UICollectionViewController {

    //MARK: - Properties
    public weak var delegate: AlbumsCollectionViewControllerDelegate?
    
    private static let leadingKind = "Album.leading"
    private var dataSource: UICollectionViewDiffableDataSource<Int, Album>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, Album>()
    private var fetchedResultsController: NSFetchedResultsController<Album>!
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

//MARK: - Supprting Methods
extension AlbumsCollectionViewController {
    
    private func configureSongCollectionView() {
        let nib = UINib(nibName: String(describing: AlbumCollectionViewCell.self), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: AlbumCollectionViewCell.cellIdentifier)
        collectionView.register(AddingCollectionReusableView.self, forSupplementaryViewOfKind: AlbumsCollectionViewController.leadingKind, withReuseIdentifier: AddingCollectionReusableView.reuseIdentifier)
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
                                                               elementKind: AlbumsCollectionViewController.leadingKind,
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
        dataSource = UICollectionViewDiffableDataSource<Int, Album> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: AlbumCollectionViewCell.cellIdentifier, for: indexPath) as! AlbumCollectionViewCell
            cell.configure(title: item.name, imageUrl: item.thumbnails?.mediumUrl)
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
        let storyboard = UIStoryboard(name: "CreateOrEditContent", bundle: nil)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
        guard let vc = navigationController.topViewController as? CreateOrEditContentViewController else { return }
        vc.contentType = .album
        present(navigationController, animated: true, completion: nil)
    }

    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Album>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource.apply(self.snapshot, animatingDifferences: true) {
                self.dataSource.apply(self.snapshot, animatingDifferences: false)
            }
        }
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Album.fetchRequest()
        
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
extension AlbumsCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - UICollectionViewDelegate
extension AlbumsCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = dataSource.itemIdentifier(for: indexPath) else { return }
        delegate?.didSelectedAlbum(album)
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
    
    ///Adds the ability to edit `transactions`.
    private func editAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: "Edit",
                        image: UIImage(systemName: "square.and.pencil")) { action in
            
            let storyboard = UIStoryboard(name: "CreateOrEditContent", bundle: nil)
            guard let editingItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
            guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else { return }
            guard let vc = navigationController.topViewController as? CreateOrEditContentViewController else { return }
            vc.contentType = .album
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
