//
//  YoutubeDownloader.swift
//  Youtube Loader
//
//  Created by isEmpty on 22.01.2021.
//

import CoreData
import Alamofire
import XCDYouTubeKit

protocol YoutubeDownloaderDelegate: class {
    func download(_ progress: Progress, videoID: String)
}

/// YouTube song downloader providing methods to download, convert and save songs from youtube.
final class YoutubeDownloader {
    
    //MARK: - Properties
    public weak var delegate: YoutubeDownloaderDelegate?
    public var activeDownloads: [String: DownloadRequest] = [:]
    public var pausedDownloads = [String]()
    private var context: NSManagedObjectContext = {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }()
    
    /// Pause downloading specified video.
    /// - Parameter videoID: id of the video to be paused.
    /// - Returns: Was it successful or not to paues the video downloading.
    @discardableResult public func pauseDownloading(_ videoID: String) -> Bool {
        guard let task = activeDownloads[videoID] else { return false }
        task.suspend()
        pausedDownloads.append(videoID)
        return true
    }
    
    /// Resume downloading specified video.
    /// - Parameter videoID: id of the video to be resumed.
    /// - Returns: Was it successful or not to resume the video downloading.
    @discardableResult public func resumeDownloading(_ videoID: String) -> Bool {
        guard let task = activeDownloads[videoID] else { return false }
        task.resume()
        pausedDownloads.removeAll(where: {$0 == videoID})
        return true
    }
    
    /// Cancel downloading specified video.
    /// - Parameter videoID: id of the video to be canceled.
    /// - Returns: Was it successful or not to cancel the video downloading.
    @discardableResult public func cancelDownloading(_ videoID: String) -> Bool {
        guard let task = activeDownloads[videoID] else { return false }
        task.cancel()
        activeDownloads.removeValue(forKey: videoID)
        pausedDownloads.removeAll(where: {$0 == videoID})
        return true
    }
    
    /// Receives video id, downloads it and converts it to m4a format. Saves to CoreData.
    /// - Parameter videoID: Unique id of the downloaded video.
    /// - Parameter youtubeVideo: The video object to be loaded.
    /// - Parameter completion: If an error occurs during download or during conversion, it returns it.
    public func downloadVideo(_ videoID: String, youtubeVideo: Video, completion: ((Error?) -> Void)? = nil) {
        XCDYouTubeClient.default().getVideoWithIdentifier(videoID) { [weak self] (video, error) in
            guard let video = video, let downloadingUrl = video.streamURLs[140] else {
                print(error?.localizedDescription ?? "error")
                completion?(error)
                return
            }

            let group = DispatchGroup()
            // The song is downloading, after it actions should be performed.
            self?.saveSong(videoURL: downloadingUrl, videoExtension: "mp4", filename: videoID) { [weak self] (error) in
                if let error = error {
                    print(error)
                    completion?(error)
                    return
                }
                guard let self = self else {
                    completion?(nil)
                    return
                }
                // If the song has been downloaded, then you need to download images for the song.
                group.enter()
                
                // If possible, get links from XCDYouTubeClient for better quality
                // From the youtube v3 api, the images are obtained with black bars at the top and bottom.
                if let thumbnailURLs = video.thumbnailURLs {
                    let smallURL = thumbnailURLs.first
                    let mediumURL = thumbnailURLs[thumbnailURLs.count / 2]
                    let highUrl = thumbnailURLs.last
                    
                    let images = [smallURL, mediumURL, highUrl]
                    self.downloadImages(from: images, named: youtubeVideo.id.videoID) { _ in
                        group.leave()
                    }
                    
                } else {
                    self.downloadImages(from: youtubeVideo.snippet?.thumbnails, named: youtubeVideo.id.videoID) { _ in
                        group.leave()
                    }
                }
                
                
                // Find the channel and get the artist object from it.
                group.enter()
                var artist: Artist? = nil
                YoutubeSearcher.performSearchChannel(with: video.channelIdentifier) { (error, response) in
                    if let error = error {
                        print(error)
                        completion?(error)
                        group.leave()
                        return
                    }
                    
                    guard let channel = response?.items.first else {
                        group.leave()
                        return
                    }
                    self.createArtistIfNeed(channelID: video.channelIdentifier, channel: channel) { art in
                        artist = art
                        group.leave()
                    }
                }
                
                // When everything is done, a song object is created and stored in coreData.
                group.notify(queue: .main) {
                    let songUrl = LocalFileManager.getURLForFile(withNameAndExtension: "\(videoID).m4a")
                    let largeImage = "\(videoID)Large.jpg"
                    let mediumImage = "\(videoID)Medium.jpg"
                    let smallImage = "\(videoID)Small.jpg"
                    let thumbnail = Thumbnail.create(context: self.context, small: smallImage, medium: mediumImage, large: largeImage)
                    Song.create(context: self.context, thumbnails: thumbnail, songURL: songUrl, id: videoID, name: video.title, artist: artist)
                    do {
                        try self.context.save()
                        completion?(nil)
                    } catch {
                        completion?(error)
                        print(error)
                    }
                }
            }
        }
    }
    
    /// Checks for the presence of an artist. If so, it returns to completion, if not, it creates it.
    /// - Parameters:
    ///   - channelID: Link to the channel to which the artist will be linked.
    ///   - channel: The object from which the data will be received.
    ///   - completion: If it succeeds to create or get an object, it returns it.
    private func createArtistIfNeed(channelID: String, channel: YoutubeChannelResponse.Item, completion: ((Artist?) -> Void)? = nil) {
        let fetchRequest: NSFetchRequest = Artist.fetchRequest()
        let predicate = NSPredicate(format: "id == %@", channelID)
        fetchRequest.predicate = predicate
        let artist = try? context.fetch(fetchRequest).first
        // if the artist is already created.
        guard artist == nil else {
            completion?(artist)
            return
        }
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async(group: group) { [weak self] in
            self?.downloadImages(from: channel.snippet.thumbnails, named: channelID) { _ in
                group.leave()
            }
        }
        let _ = group.wait(timeout: .now() + 15)
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let largeImage = "\(channelID)Large" + ".jpg"
            let mediumImage = "\(channelID)Medium" + ".jpg"
            let smallImage = "\(channelID)Small" + ".jpg"
            var artist: Artist?
            let thumbnail = Thumbnail.create(context: self.context, small: smallImage, medium: mediumImage, large: largeImage)
            artist = Artist.createIfNotExist(context: self.context, thumbnails: thumbnail, id: channelID, name: channel.snippet.title)
            completion?(artist)
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
        downloadFile(from: videoURL, extension: videoExtension, filename: filename) { [weak self] (error) in
            if error == nil {
                // Getting audio from video
                self?.extractAudioFromVideo(filename: filename) { (error) in
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
    private func downloadFile(from link: URL, extension ext: String, filename: String, completion: ((Error?) -> Void)? = nil) {
        // The link where the file will be saved.
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(filename + "." + ext)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        // DownloadRequest is saved to the dictionary to control download during download.
        activeDownloads[filename] = AF.download(link, to: destination).downloadProgress(queue: .global()) { [weak self] progress in
            self?.delegate?.download(progress, videoID: filename)
        }.response{ response in
            if response.error == nil {
                print("Downloaded successfully \(filename).\(ext)")
                completion?(nil)
            } else {
                print("Error downlaoding file: " + (response.error?.localizedDescription ?? "Unknown error"))
                completion?(response.error)
            }
        }
    }
    
    /// Accepts thumbnail object and downloads images from urls.
    /// - Parameters:
    ///   - thumbnail: The object from which links to images will be obtained.
    ///   - named: How the pictures will be called.
    ///   - completion: If an error occurs during conversion, it returns it.
    private func downloadImages(from thumbnail: Thumbnails?, named: String, completion: ((Error?) -> Void)? = nil) {
        let large = thumbnail?.high.url
        let medium = thumbnail?.medium.url
        let small = thumbnail?.thumbnailsDefault.url
        let urls = [small, medium, large]
        downloadImages(from: urls, named: named, completion: completion)
    }
    
    /// Uploads pictures and signs them accordingly.
    /// - Parameters:
    ///   - urlsString: List of download links presented as strings.
    ///   - named: How the pictures will be called.
    ///   - completion: If an error occurs during conversion, it returns it.
    private func downloadImages(from urlsString: [String?], named: String, completion: ((Error?) -> Void)? = nil) {
        // gets non nil URL from strings
        let urls = urlsString.compactMap{$0}.compactMap{ URL(string: $0) }
        // create names and urls where images will be saved.
        let destitaionations = (0..<urls.count).map { (index) -> DownloadRequest.Destination in
            return { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let size: String
                switch index {
                case 0 : size = "Small"
                case 1: size = "Medium"
                default: size = "Large"
                }
                let fileURL = documentsURL.appendingPathComponent(named + "\(size)" + "." + "jpg")
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        }
        
        (0..<urls.count).forEach { (index) in
            let link = urls[index]
            let destination = destitaionations[index]
            AF.download(link, to: destination).validate().response(queue: .global()) {
                response in
                if response.error == nil, let filePath = response.fileURL?.path {
                    print("Downloaded successfully to " + filePath)
                } else {
                    print("Error downlaoding file: " + (response.error?.localizedDescription ?? "Unknown error"))
                    completion?(response.error)
                }
                // If everything worked out, return an empty completion.
                if index == urls.count - 1 {
                    completion?(nil)
                }
            }
        }
    }
    
    /// Uploads pictures and signs them accordingly.
    /// - Parameters:
    ///   - urls: List of download links.
    ///   - named: How the pictures will be called.
    ///   - completion: If an error occurs during conversion, it returns it.
    private func downloadImages(from urls: [URL?], named: String, completion: ((Error?) -> Void)? = nil) {
        // gets non nil URL
        let urls = urls.compactMap{$0}
        // create names and urls where images will be saved.
        let destitaionations = (0..<urls.count).map { (index) -> DownloadRequest.Destination in
            return { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let size: String
                switch index {
                case 0 : size = "Small"
                case 1: size = "Medium"
                default: size = "Large"
                }
                let fileURL = documentsURL.appendingPathComponent(named + "\(size)" + "." + "jpg")
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        }
        
        (0..<urls.count).forEach { (index) in
            let link = urls[index]
            let destination = destitaionations[index]
            AF.download(link, to: destination).validate().response(queue: .global()) {
                response in
                if response.error == nil, let filePath = response.fileURL?.path {
                    print("Downloaded successfully to " + filePath)
                } else {
                    print("Error downlaoding file: " + (response.error?.localizedDescription ?? "Unknown error"))
                    completion?(response.error)
                }
                // If everything worked out, return an empty completion.
                if index == urls.count - 1 {
                    completion?(nil)
                }
            }
        }
    }
    
    /// Convert mp4 video to m4a audio.
    /// - Parameters:
    ///   - filename: The name of the loaded and saved file.
    ///   - completion: If an error occurs during conversion, it returns it.
    private func extractAudioFromVideo(filename: String, completion: ((Error?) -> Void)? = nil) {
        let in_url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(filename).mp4")
        let out_url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(filename).m4a")
        
        // convert video to m4a
        AVURLAsset(url: in_url).writeAudioTrack(to: out_url) { (error) in
            completion?(error)
        }
    }
}
