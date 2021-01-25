//
//  UIImage+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 23.01.2021.
//

import UIKit

extension UIImage {
    /// Resizes the image by the specified percentage.
    /// - Parameter percentage: By what percentage the picture should be enlarged or reduced.
    /// - Returns: Returns the image if it succeeded to create it.
    public func resizeWithPercent(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    /// Shrinks the image so that the large side does not exceed the size provided.
    /// - Parameter size: Larger side size.
    /// - Returns: Returns the image if it succeeded to create it.
    public func decreaseImageFit(to size: CGFloat) -> UIImage? {
        let smallerSide = [self.size.width, self.size.height].min() ?? self.size.width
        guard size < smallerSide else { return nil }
        return fit(size: size)
    }
    
    /// Enlarges the image so that the smaller side fills the expected size.
    /// - Parameter size: The size of the smallest side.
    /// - Returns: Returns the image if it succeeded to create it.
    public func fit(size: CGFloat) -> UIImage? {
        let smallerSide = [self.size.width, self.size.height].min() ?? self.size.width
        let difference = size / smallerSide
        return self.resizeWithPercent(percentage: difference)
    }
}

//MARK: - Color Extension
extension UIImage {
    /// Returns the average color over the entire image.
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
