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
