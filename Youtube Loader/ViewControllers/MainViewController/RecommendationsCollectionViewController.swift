//
//  RecommendationsCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

class RecommendationsCollectionViewController: UICollectionViewController {

    private var dataSource: UICollectionViewDiffableDataSource<Int, Song>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
    private var fetchedResultsController: NSFetchedResultsController<Song>!
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSongCollectionView()
        setupFetchedResultsController()
        configureDataSource()
    }
}

extension RecommendationsCollectionViewController {
    
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
            guard let imageData = item.image else { return nil }
            cell.configure(title: item.name, description: item.author, image: UIImage(data: imageData))
            return cell
        })
        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Song>()
        snapshot.appendSections([0])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
    private func setupFetchedResultsController() {
        let request: NSFetchRequest = Song.fetchRequest()
        
        
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
}

//MARK: - NSFetchedResultsControllerDelegate
extension RecommendationsCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}
