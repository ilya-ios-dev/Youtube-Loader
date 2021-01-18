//
//  AVAsset+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 17.01.2021.
//

import AVFoundation

extension AVAsset {
    
    // Provide a URL for where you wish to write
    // the audio file if successful
    func writeAudioTrack(to url: URL, completion: @escaping (Error?) -> ()) {
        do {
            let asset = try audioAsset()
            asset.write(to: url, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    private func write(to url: URL, completion: @escaping (Error?) -> ()) {
        // Create an export session that will output an
        // audio track (M4A file)
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            // This is just a generic error
            let error = NSError(domain: "domain", code: 0, userInfo: nil)
            completion(error)
            return
        }
        
        exportSession.outputFileType = .m4a
        exportSession.outputURL = url
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(nil)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                completion(error)
            @unknown default:
                let error = NSError(domain: "domain", code: 0, userInfo: nil)
                completion(error)
            }
        }
    }
    
    
    private func audioAsset() throws -> AVAsset {
        // Create a new container to hold the audio track
        let composition = AVMutableComposition()
        // Create an array of audio tracks in the given asset
        // Typically, there is only one
        let audioTracks = tracks(withMediaType: .audio)
        
        // Iterate through the audio tracks while
        // Adding them to a new AVAsset
        for track in audioTracks {
            let compositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                               preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                // Add the current audio track at the beginning of
                // the asset for the duration of the source AVAsset
                try compositionTrack?.insertTimeRange(track.timeRange,
                                                      of: track,
                                                      at: track.timeRange.start)
            } catch {
                throw error
            }
        }
        return composition
    }
}
