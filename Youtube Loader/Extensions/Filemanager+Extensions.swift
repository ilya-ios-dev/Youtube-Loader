//
//  Filemanager+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 23.01.2021.
//

import Foundation

extension FileManager {
    /// Returns links to all files in the specified directory.
    /// - Parameters:
    ///   - directory: The directory to search in.
    ///   - skipsHiddenFiles: Show hidden files or not.
    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
    
    /// Returns a link to the file, if any, in the specified directory with the specified name.
    /// - Parameters:
    ///   - directory: The directory to search in.
    ///   - filename: File name with extension.
    ///   - skipsHiddenFiles: Show hidden files or not.
    func url(for directory: FileManager.SearchPathDirectory, filename: String, skipsHiddenFiles: Bool = true) -> URL? {
        let directoryString = urls(for: directory, in: .userDomainMask)[0].absoluteString
        return urls(for: directory)?.first(where: { (url) -> Bool in
            let fn = url.absoluteString.deletingPrefix(directoryString)
            return fn == filename
        })
    }
}
