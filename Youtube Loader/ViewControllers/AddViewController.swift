//
//  AddViewController.swift
//  Youtube Loader
//
//  Created by isEmpty on 16.01.2021.
//

import UIKit
import CoreData
import Alamofire
import AlamofireImage
import XCDYouTubeKit

final class AddViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Properties
    private var searchText = ""
    private var searchResults = [Video]()
    private var activeDownloads: [String: DownloadRequest] = [:]
    private var pausedDownloads = [String]()
    
    private lazy var privateContext: NSManagedObjectContext = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = appDelegate.persistentContainer.viewContext
        return privateContext
    }()
    private lazy var mainContext: NSManagedObjectContext = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { fatalError() }
        return appDelegate.persistentContainer.viewContext
    }()
    
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: String(describing: AddSongTableViewCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: AddSongTableViewCell.cellIdentifier)
        tableView.dataSource = self
        configureSearchBar()
    }
}

//MARK: - Supporting Methods
extension AddViewController {
    
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
        
        searchBar.searchTextField.backgroundColor = .white
    }
    
    /// Executes a request in Youtube V3 API, displays a list of results.
    /// - Parameter searchString: The string from which the request will be made.
    private func performSearch(with searchString: String) {
        // To use the program, you need to enter your Youtube V3 API Key.
        let key = "key=" + ApiKeys.youtubeApiKey
        // TODO: - Add the ability to choose the categories that will be displayed during the search. -
        let safeString = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&videoCategoryId=10&maxResults=25&q=\(searchString)&\(key)&type=video".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        AF.request(safeString).validate().responseDecodable(of: YoutubeResponse.self, queue: .global()) { (response) in
            guard let value = response.value else { return }
            self.searchResults = value.items
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

//MARK: - UITableViewDataSource
extension AddViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddSongTableViewCell.cellIdentifier) as! AddSongTableViewCell
        cell.delegate = self
        
        let item = searchResults[indexPath.row]
        let nowDownloading = activeDownloads[item.id.videoID] != nil
        let nowPaused = pausedDownloads.contains(where: {$0 == item.id.videoID})
        
        cell.configure(video: item, downloading: nowDownloading, paused: nowPaused)
        
        if let url = URL(string: item.snippet.thumbnails.medium.url){
            cell.backgroundBlurImage.af.setImage(withURL: url)
            cell.songImageView.af.setImage(withURL: url)
        }
        return cell
    }        
}

//MARK: - AddSongTableViewCellDelegate
extension AddViewController: AddSongTableViewCellDelegate {
    func downloadTapped(_ cell: AddSongTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        downloadWith(videoID)
    }
    
    func cancelTapped(_ cell: AddSongTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        guard let task = activeDownloads[videoID] else { return }
        task.cancel()
        activeDownloads.removeValue(forKey: videoID)
        pausedDownloads.removeAll(where: {$0 == videoID})
    }
    
    func pauseTapped(_ cell: AddSongTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        guard let task = activeDownloads[videoID] else { return }
        task.suspend()
        pausedDownloads.append(videoID)
    }
    
    func resumeTapped(_ cell: AddSongTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let videoID = searchResults[indexPath.row].id.videoID
        guard let task = activeDownloads[videoID] else { return }
        task.resume()
        pausedDownloads.removeAll(where: {$0 == videoID})
    }
}

//MARK: - Downloading
extension AddViewController {
    /// Receives video id, downloads it and converts it to m4a format. Saves to CoreData.
    /// - Parameter videoID: Unique id of the downloaded video.
    private func downloadWith(_ videoID: String) {
        XCDYouTubeClient.default().getVideoWithIdentifier(videoID) { (video, error) in
            guard let video = video,
                  let downloadingUrl = video.streamURLs[140] else {
                print(error?.localizedDescription ?? "error")
                return
            }
            
            self.saveSong(videoURL: downloadingUrl, videoExtension: "mp4", filename: videoID) { err in
                if let err = err {
                    print(err)
                    return
                }
                DispatchQueue.main.async {
                    let song = Song(context: self.privateContext)
                    song.author = video.author
                    song.name = video.title
                    song.dateSave = Date()
                    let songUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(videoID).m4a")
                    song.song = try? Data(contentsOf: songUrl)
                    song.image = try? Data(contentsOf: video.thumbnailURLs!.last!)
                    song.id = videoID
                    self.save()
                    LocalFileManager.deleteFile(withNameAndExtension: "\(videoID).m4a")
                }
                self.activeDownloads.removeValue(forKey: videoID)
            }
        }
    }
    
    /// Download video from link and convert it to m4a file.
    /// - Parameters:
    ///   - songUrl: Link to download the video.
    ///   - videoExtension: The extension with which the video will be saved.
    ///   - filename: The name of the temporary file.
    ///   - completion: If an error occurs during download or during conversion, it returns it.
    private func saveSong(videoURL: URL, videoExtension: String, filename: String, completion: ((Error?) -> Void)? = nil) {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        // Download a file, temporarily save it to a local disk.
        self.downloadFile(from: videoURL, extension: videoExtension, filename: filename) { (error) in
            if error == nil {
                // Getting audio from video
                self.extractAudioFromVideo(filename: filename) { (error) in
                    LocalFileManager.deleteFile(withNameAndExtension: "\(filename).mp4")
                    completion?(nil)
                    dispatchGroup.leave()
                }
            } else {
                LocalFileManager.deleteFile(withNameAndExtension: "\(filename).mp4")
                dispatchGroup.leave()
                completion?(error)
                print(error?.localizedDescription ?? "error")
            }
        }
    }
    
    /// Downloads the file and saves it to the document directory with the specified name and extension.
    /// - Parameters:
    ///   - link: Download link.
    ///   - ext: The extension of the downloaded file.
    ///   - filename: The name of the file to be saved.
    ///   - completion: If an error occurs during loading, return it.
    func downloadFile(from link: URL, extension ext: String, filename: String, completion: ((Error?) -> Void)? = nil) {
        // The link where the file will be saved.
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(filename + "." + ext)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        // DownloadRequest is saved to the dictionary to control download during download.
        activeDownloads[filename] = AF.download(link, to: destination).downloadProgress(queue: .global()) { progress in
            guard let index = self.searchResults.firstIndex(where: {$0.id.videoID == filename}) else { return }
            DispatchQueue.main.async {
                if let trackCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? AddSongTableViewCell {
                    trackCell.updateDisplay(progress: Float(progress.fractionCompleted))
                    if progress.isFinished {
                        trackCell.finishDownload()
                    }
                }
            }
        }.response{ response in
            if response.error == nil, let filePath = response.fileURL?.path {
                print("Downloaded successfully to " + filePath)
                completion?(nil)
            } else {
                print("Error downlaoding file: " + (response.error?.localizedDescription ?? "Unknown error"))
                completion?(response.error)
            }
        }
    }
    
    /// Convert mp4 video to m4a audio.
    /// - Parameters:
    ///   - filename: The name of the loaded and saved file.
    ///   - completion: If an error occurs during conversion, it returns it.
    func extractAudioFromVideo(filename: String, completion: ((Error?) -> Void)? = nil) {
        let in_url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(filename).mp4")
        let out_url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(filename).m4a")
        
        // convert video to m4a
        AVURLAsset(url: in_url).writeAudioTrack(to: out_url) { (error) in
            completion?(error)
        }
    }
    
    
    /// Saves the changes made. Passes them to the main context.
    private func save(){
        do {
            try privateContext.save()
            privateContext.performAndWait {
                do {
                    try mainContext.save()
                } catch {
                    print(error)
                }
            }
        } catch {
            print(error)
        }
    }
}

//MARK: - UISearchBarDelegate
extension AddViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // to limit network activity, reload half a second after last key press.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
        self.searchText = searchText
        perform(#selector(search), with: nil, afterDelay: 2)
    }
    
    @objc private func search() {
        guard !searchText.isEmpty else { return }
        performSearch(with: searchText)
    }
}
