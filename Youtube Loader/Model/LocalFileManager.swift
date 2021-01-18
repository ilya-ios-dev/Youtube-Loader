//
//  LocalFileManager.swift
//  Youtube Loader
//
//  Created by isEmpty on 17.01.2021.
//

import Foundation

struct LocalFileManager {
    
    /// Returns the presence of a file in a document directory.
    /// - Parameter filename_ext: The filename along with the extension.
    ///   Example:` filename.txt`
    /// - Returns: true if the file is found.
    static func checkFileExist (_ filename_ext: String, path: String? = nil) -> Bool {
        let documentsDirectory: String
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        documentsDirectory = paths[0]
        let dataPathStr = documentsDirectory + "/" + filename_ext
        return FileManager.default.fileExists(atPath: dataPathStr)
    }
    
    /// Removes the file in the document directory.
    /// - Parameter filename_ext: The filename along with the extension.
    ///   Example:` filename.txt`
    /// - Returns: true if the file is successfully deleted.
    @discardableResult static func deleteFile(withNameAndExtension filename_ext: String) -> Bool {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let dataPathStr = documentsDirectory + "/" + filename_ext
        if FileManager.default.fileExists(atPath: dataPathStr) {
            do {
                try FileManager.default.removeItem(atPath: dataPathStr)
                print("Removed file: \(filename_ext)")
            } catch let removeError {
                print("couldn't remove file at path", removeError.localizedDescription)
                return false
            }
        }
        return true
    }

}
