//
//  DownloadSongsViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 16.01.2021.
//

import UIKit

/// A view controller that specializes in finding and downloading songs.
final class DownloadSongsViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    
    //MARK: - Properties
    private var searchText = ""
    private var searchResults = [Video]()
    private var downloader = YoutubeDownloader()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: String(describing: DownloadSongsTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: DownloadSongsTableViewCell.cellIdentifier)
        tableView.dataSource = self
        configureSearchBar()
        
        tableView.contentInset = UIEdgeInsets(top: searchBar.frame.height, left: 0, bottom: 0, right: 0)
        downloader.delegate = self
    }
    
    //MARK: - Supporting Methods
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
}

//MARK: - UITableViewDataSource
extension DownloadSongsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DownloadSongsTableViewCell.cellIdentifier) as! DownloadSongsTableViewCell
        cell.delegate = self
        let item = searchResults[indexPath.row]
        let nowDownloading = downloader.activeDownloads[item.id.videoID] != nil
        let nowPaused = downloader.pausedDownloads.contains(where: {$0 == item.id.videoID})
        let url = URL(string: item.snippet?.thumbnails.thumbnailsDefault.url ?? "")
        
        cell.configure(video: item, downloading: nowDownloading, paused: nowPaused, url: url)
        return cell
    }        
}

//MARK: - AddSongTableViewCellDelegate
extension DownloadSongsViewController: AddSongTableViewCellDelegate {
    
    func downloadTapped(_ cell: DownloadSongsTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let video = searchResults[indexPath.row]
        let videoID = video.id.videoID
        downloader.downloadVideo(videoID, youtubeVideo: video){ [weak self] error in
            guard let error = error else { return }
            guard let isExplisitlyCancelled = error.asAFError?.isExplicitlyCancelledError, !isExplisitlyCancelled else { return }
            self?.showAlert(alertText: error.localizedDescription)
        }
    }
    
    func cancelTapped(_ cell: DownloadSongsTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        downloader.cancelDownloading(videoID)
    }
    
    func pauseTapped(_ cell: DownloadSongsTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        downloader.pauseDownloading(videoID)
    }
    
    func resumeTapped(_ cell: DownloadSongsTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        downloader.resumeDownloading(videoID)
    }
}

//MARK: - YoutubeDownloaderDelegate
extension DownloadSongsViewController: YoutubeDownloaderDelegate {
    func download(_ progress: Progress, videoID: String) {
        guard let index = self.searchResults.firstIndex(where: {$0.id.videoID == videoID}) else { return }
        DispatchQueue.main.async { [weak self] in
            if let trackCell = self?.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? DownloadSongsTableViewCell {
                trackCell.updateDisplay(progress: Float(progress.fractionCompleted))
                if progress.isFinished {
                    trackCell.finishDownload()
                }
            }
        }
    }
}

//MARK: - UISearchBarDelegate
extension DownloadSongsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 2)
    }
    
    @objc private func search() {
        guard !searchText.isEmpty else { return }
        YoutubeSearcher.performSearchVideo(with: searchText) { [weak self] (error, response) in
            guard let items = response?.items else {
                print(error ?? "Unknown error")
                self?.showAlert(alertText: error?.localizedDescription)
                return
            }
            self?.searchResults = items
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
}
