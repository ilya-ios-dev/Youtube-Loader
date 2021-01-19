//
//  PlaylistCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

class PlaylistCollectionViewController: UICollectionViewController {

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

extension PlaylistCollectionViewController {
    
    private func configureSongCollectionView() {
        let nib = UINib(nibName: "PlaylistCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "playlist")
        collectionView.collectionViewLayout = configureSongLayout()
    }
    
    private func configureSongLayout() -> UICollectionViewLayout {
        let sectionProvider = {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let section: NSCollectionLayoutSection
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(150), heightDimension: .fractionalHeight(1))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Song> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "playlist", for: indexPath) as? PlaylistCollectionViewCell else { print("эта хуета не получается"); return nil }
            
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
extension PlaylistCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }
}

