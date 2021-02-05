//
//  RecommendationsCollectionViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 19.01.2021.
//

import UIKit
import CoreData

/// A view controller that specializes in displaying all featured songs as a collection view.
final class RecommendationsCollectionViewController: UICollectionViewController {

    //MARK: - Properties
    private var downloader = YoutubeDownloader()
    private var dataSource: UICollectionViewDiffableDataSource<Int, Video>!
    private var snapshot = NSDiffableDataSourceSnapshot<Int, Video>()
    private var searchResults = [Video]()
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSongCollectionView()
        fetchRecommendations()
        configureDataSource()
        downloader.delegate = self
    }
}

//MARK: - Supporting Methods
extension RecommendationsCollectionViewController {
    
    private func fetchRecommendations() {
        guard let songId = getLastSongId() else { return }
        YoutubeSearcher.performSearchRecommendations(relatedTo: songId) { (error, response) in
            DispatchQueue.main.async {
            guard let response = response else {
                self.showAlert(alertText: error?.localizedDescription)
                return
            }
            self.searchResults = response.items.filter{ $0.snippet != nil }
                self.setupSnapshot()
            }
        }
    }
    
    private func getLastSongId() -> String? {
        let songRequest: NSFetchRequest = Song.fetchRequest()
        let song = try? context.fetch(songRequest).first
        return song?.id
    }

    private func configureSongCollectionView() {
        let nib = UINib(nibName: String(describing: RecommendationsCollectionViewCell.self), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: RecommendationsCollectionViewCell.cellIdentifier)
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
        dataSource = UICollectionViewDiffableDataSource<Int, Video> (collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: RecommendationsCollectionViewCell.cellIdentifier, for: indexPath) as! RecommendationsCollectionViewCell
            cell.delegate = self
            let item = self.searchResults[indexPath.item]
            let nowDownloading = self.downloader.activeDownloads[item.id.videoID] != nil
            let nowPaused = self.downloader.pausedDownloads.contains(where: {$0 == item.id.videoID})
            let url = URL(string: item.snippet?.thumbnails.thumbnailsDefault.url ?? "")
            
            cell.configure(video: item, downloading: nowDownloading, paused: nowPaused, url: url)
            return cell
        })
        setupSnapshot()
    }
    
    private func setupSnapshot() {
        snapshot = NSDiffableDataSourceSnapshot<Int, Video>()
        snapshot.appendSections([0])
        snapshot.appendItems(searchResults)
        DispatchQueue.main.async {
            self.dataSource?.apply(self.snapshot, animatingDifferences: true)
        }
    }
}

//MARK: - RecommendationsCollectionViewCellDelegate
extension RecommendationsCollectionViewController: RecommendationsCollectionViewCellDelegate {
    func downloadTapped(_ cell: RecommendationsCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let video = searchResults[indexPath.item]
        let videoID = video.id.videoID
        downloader.downloadVideo(videoID, youtubeVideo: video){ error in
            guard let error = error else { return }
            guard let isExplisitlyCancelled = error.asAFError?.isExplicitlyCancelledError, !isExplisitlyCancelled else { return }
            self.showAlert(alertText: error.localizedDescription)
        }
    }
    
    func cancelTapped(_ cell: RecommendationsCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.item].id.videoID
        downloader.cancelDownloading(videoID)
    }
    
    func pauseTapped(_ cell: RecommendationsCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.item].id.videoID
        downloader.pauseDownloading(videoID)
    }
    
    func resumeTapped(_ cell: RecommendationsCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.item].id.videoID
        downloader.resumeDownloading(videoID)
    }
}

//MARK: - YoutubeDownloaderDelegate
extension RecommendationsCollectionViewController: YoutubeDownloaderDelegate {
    func download(_ progress: Progress, videoID: String) {
        guard let index = self.searchResults.firstIndex(where: {$0.id.videoID == videoID}) else { return }
        DispatchQueue.main.async {
            if let trackCell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? RecommendationsCollectionViewCell {
                trackCell.updateDisplay(progress: Float(progress.fractionCompleted))
                if progress.isFinished {
                    trackCell.finishDownload()
                }
            }
        }
    }
}
