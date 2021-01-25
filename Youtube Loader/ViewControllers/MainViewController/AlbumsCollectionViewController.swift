//
//  AlbumsCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

final class AlbumsCollectionViewController: UICollectionViewController {

    //MARK: - Properties
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
            return addingView
        }

        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Album>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
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
