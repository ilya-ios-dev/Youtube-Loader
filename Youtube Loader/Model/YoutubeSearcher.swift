//
//  YoutubeSearcher.swift
//  Youtube Loader
//
//  Created by isEmpty on 22.01.2021.
//

import Alamofire

/// Searcher providing out-of-the-box methods for working with youtube api.
struct YoutubeSearcher {
    
    private static let apiKey = ApiKeys.youtubeApiKey
    
    /// Executes a request in Youtube V3 API, displays a list of results.
    /// - Parameter searchString: The string from which the request will be made.
    public static func performSearchVideo(with searchString: String, completion: @escaping (Error?, YoutubeVideoResponse?) -> Void) {
        // To use the program, you need to enter your Youtube V3 API Key.
        let safeString = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&videoCategoryId=10&maxResults=25&q=\(searchString)&key=\(apiKey)&type=video"
            .addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        AF.request(safeString).validate().responseDecodable(of: YoutubeVideoResponse.self, queue: .global()) { (response) in
            completion(response.error, response.value)
        }
    }

    /// Makes a request in api and displays a list of channels by id.
    /// - Parameters:
    ///   - channelID: id of the channel being searched for.
    ///   - completion: the block in which the error is transmitted if there is also a responsive.
    public static func performSearchChannel(with channelID: String, completion: @escaping (Error?, YoutubeChannelResponse?) -> Void) {
        let safeString = "https://youtube.googleapis.com/youtube/v3/channels?part=snippet%2CcontentDetails%2Cstatistics&id=\(channelID)&key=\(apiKey)"
        AF.request(safeString).validate().responseDecodable(of: YoutubeChannelResponse.self, queue: .global()) { (response) in
            completion(response.error, response.value)
        }
        
    }
    
    /// Searches for videos that might be interesting based on the specified video.
    /// - Parameters:
    ///   - videoID: ID of the video on the basis of which recommendations will be issued.
    ///   - completion: the block in which the error is transmitted if there is also a responsive.
    public static func performSearchRecommendations(relatedTo videoID: String, completion: @escaping (Error?, YoutubeVideoResponse?) -> Void) {
        let safeString = "https://youtube.googleapis.com/youtube/v3/search?part=snippet&maxResults=25&key=\(apiKey)&type=video&videoCategoryId=10&relatedToVideoId=\(videoID)"
        AF.request(safeString).validate().responseDecodable(of: YoutubeVideoResponse.self, queue: .global()) { (response) in
            completion(response.error, response.value)
        }
    }

}

