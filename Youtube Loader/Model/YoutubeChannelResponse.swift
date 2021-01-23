//
//  YoutubeChannelResponse.swift
//  Youtube Loader
//
//  Created by isEmpty on 23.01.2021.
//

import Foundation

/// JSON response to a YouTube channel request, presented as a swift class.
struct YoutubeChannelResponse: Codable {
    let items: [Item]
    
    struct Item: Codable {
        let snippet: Snippet
        
        struct Snippet: Codable {
            let title: String
            let thumbnails: Thumbnails
        }
    }
}
