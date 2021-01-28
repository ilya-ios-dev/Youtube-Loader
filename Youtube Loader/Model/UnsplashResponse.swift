//
//  UnsplashResponse.swift
//  Youtube Loader
//
//  Created by isEmpty on 26.01.2021.
//

import Foundation

struct UnsplashResponse: Codable, Hashable {
    let results: [Result]
    
    struct Result: Codable, Hashable {
        let urls: Urls
        
        struct Urls: Codable, Hashable {
            let raw, full, regular, small: String
            let thumb: String
        }
    }
}
