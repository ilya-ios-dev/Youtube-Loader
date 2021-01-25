//
//  ArtistCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

final class ArtistCollectionViewController: UICollectionViewController {

    //MARK: - Properties
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
            return addingView
        }
        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Artist>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
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

