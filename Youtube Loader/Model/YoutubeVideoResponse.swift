//
//  Youtube.swift
//  Youtube Loader
//
//  Created by isEmpty on 16.01.2021.
//

import UIKit
import CoreData

/// JSON response to a YouTube video request, presented as a swift class.
struct YoutubeVideoResponse: Codable, Hashable {
    let items: [Video]
}

// MARK: - Item
struct Video: Codable, Hashable {
    let id: ID
    let snippet: Snippet?
}

extension Video {
    public var isDownloaded: Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest = Song.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", self.id.videoID)
        return (try? privateContext.fetch(request).first != nil) ?? false
    }
}

// MARK: - ID
struct ID: Codable, Hashable {
    let videoID: String
    enum CodingKeys: String, CodingKey {
        case videoID = "videoId"
    }
}

// MARK: - Snippet
struct Snippet: Codable, Hashable {
    let title: String
    let snippetDescription: String
    let thumbnails: Thumbnails
    let channelTitle: String
    let channelID: String
    enum CodingKeys: String, CodingKey {
        case title
        case channelID = "channelId"
        case snippetDescription = "description"
        case thumbnails, channelTitle
    }
}

// MARK: - Thumbnails
struct Thumbnails: Codable, Hashable {
    let thumbnailsDefault, medium, high: Default
    
    enum CodingKeys: String, CodingKey {
        case thumbnailsDefault = "default"
        case medium, high
    }
}

// MARK: - Default
struct Default: Codable, Hashable {
    let url: String
}
