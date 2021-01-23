//
//  Data+UIImageCompression.swift
//  Youtube Loader
//
//  Created by isEmpty on 23.01.2021.
//

import UIKit

extension Data {
    public enum Size: Int {
        case small = 30_000, medium = 100_000, large = 200_000
        
        func imageSize() -> CGFloat {
            switch self {
            case .small:
                return 200
            case .medium:
                return 500
            case .large:
                return 1000
            }
        }
    }
    
    /// Compresses the image to reduce its size.
    /// - Parameter size: The type of compression to which it will be compressed.
    public func compressImage(size: Size) -> Data? {
        let expectedSize = Float(size.rawValue)
        guard self.count > Int(expectedSize) else { return self }
        if var image = UIImage(data: self) {
            image = image.decreaseImageFit(to: size.imageSize()) ?? image
            guard let receivedImageData = image.jpegData(compressionQuality : 1) else { return nil }
            // Если получившийся размер попадает под критерии
            guard receivedImageData.count > Int(expectedSize) else { return receivedImageData }
            
            let compressionPercent = (expectedSize / Float(receivedImageData.count))
            guard let newValue = image.jpegData(compressionQuality: CGFloat(compressionPercent)) else { return nil }
            return newValue.count > self.count ? self : newValue
        } else {
            return nil
        }
    }
}
