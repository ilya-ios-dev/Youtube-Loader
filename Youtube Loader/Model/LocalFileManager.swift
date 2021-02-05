//
//  LocalFileManager.swift
//  Youtube Loader
//
//  Created by isEmpty on 17.01.2021.
//

import Foundation

/// A file manager that provides methods for working with local files.
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
    
    /// Saves a file with the specified name and data in the document directory.
    /// - Parameters:
    ///   - filename_ext: Filename with extension.
    ///   - data: The data that will be saved.
    /// - Returns: Was it possible to save it or not.
    @discardableResult static func saveData(withNameAndExtension filename_ext: String, data: Data) -> Bool {
        do {
            let url = getDocumentsDirectory().appendingPathComponent("\(filename_ext)")
            try data.write(to: url)
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    /// Gets a link to a file if it exists in the document directory.
    /// - Parameter filename_ext: The filename along with the extension.
    static func getURLForFile(withNameAndExtension filename_ext: String) -> URL? {
        return FileManager.default.url(for: .documentDirectory, filename: filename_ext)
    }
    
    /// Gets a link to a file if it exists in the document directory.
    /// - Parameters:
    ///   - filename: The filename.
    ///   - ext: Extension of the desired file.
    static func getURLForFile(withNameAndExtension filename: String, ext: String) -> URL? {
        return FileManager.default.url(for: .documentDirectory, filename: "\(filename).\(ext)")
    }

}
