//
//  SongsCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

protocol SongsCollectionViewControllerDelegate: class {
    func updateSongsArray(_ songs: [Song])
    func didSelectedItemAt(_ index: Int)
}

final class SongsCollectionViewController: UICollectionViewController {

    //MARK: - Properties
    public weak var delegate: SongsCollectionViewControllerDelegate?
    public var predicate: NSCompoundPredicate?
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, Song>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
    private var fetchedResultsController: NSFetchedResultsController<Song>!
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectedItemAt(indexPath.item)
    }
}

//MARK: - Supporting Methods
extension SongsCollectionViewController {
    
    public func reloadData() {
        setupFetchedResultsController()
    }

    public func selectItem(_ item: Song) {
        guard let index = dataSource.indexPath(for: item) else { return }
        collectionView.selectItem(at: index, animated: true, scrollPosition: .centeredHorizontally)
    }
    
    private func configureSongCollectionView() {
        let nib = UINib(nibName: String(describing: SongCollectionViewCell.self), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: SongCollectionViewCell.cellIdentifier)
        collectionView.collectionViewLayout = configureSongLayout()
    }
    
    private func configureSongLayout() -> UICollectionViewLayout {
        let sectionProvider = {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let section: NSCollectionLayoutSection
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 4, leading: 0, bottom: 4, trailing: 0)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 3)
            section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Song> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: SongCollectionViewCell.cellIdentifier, for: indexPath) as! SongCollectionViewCell
            
            if let url = item.thumbnails?.smallUrl {
                cell.configure(title: item.name, description: item.author?.name, imageURL: url)
            }
            return cell
        })
        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        delegate?.updateSongsArray(snapshot.itemIdentifiers)
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true) {
                self.dataSource?.apply(self.snapshot, animatingDifferences: false)
            }
        }
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Song.fetchRequest()
        
        let sort = NSSortDescriptor(key: "dateSave", ascending: true)
        request.sortDescriptors = [sort]
        
        if let predicate = predicate {
            request.predicate = predicate
        }
        
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
extension SongsCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

//MARK: - UICollectionViewDelegate
extension SongsCollectionViewController {
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
            vc.contentType = .song
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
