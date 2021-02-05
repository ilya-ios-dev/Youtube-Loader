//
//  UIView+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 12.01.2021.
//

import UIKit

extension UIView {
    /// Creates a CAGradientLayer with the given parameters.
    /// - Parameters:
    ///   - colours: List of colors used in the gradient.
    ///   - locations: The gradient stops are specified as values between 0 and 1. The values must be monotonically increasing.
    ///     If nil, the stops are spread uniformly across the range. Defaults to nil.
    ///   - startPoint: Where the gradient starts. Accepts enum Point elements.
    ///   - endPoint: Where the gradient starts. Accepts enum Point elements.
    /// - Returns: Returns and applies the generated `CAGradientLayer`.
    @discardableResult func applyGradient(colours: [UIColor], locations: [NSNumber]? = nil, startPoint: Point = .topLeft, endPoint: Point = .bottomLeft) -> CAGradientLayer {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        
        gradient.startPoint = startPoint.point
        gradient.endPoint = endPoint.point
        
        gradient.cornerRadius = self.layer.cornerRadius
        self.layer.insertSublayer(gradient, at: 0)
        return gradient
    }

    public func fillSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let superview = superview {
            leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
            rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        }
    }
    
    public func fillView(_ view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

public enum Point {
    case topRight, topLeft
    case bottomRight, bottomLeft
    case custom(point: CGPoint)
    
    var point: CGPoint {
        switch self {
        case .topRight: return CGPoint(x: 1, y: 0)
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .bottomRight: return CGPoint(x: 1, y: 1)
        case .bottomLeft: return CGPoint(x: 0, y: 1)
        case .custom(let point): return point
        }
    }
}

extension UIView{
    /// Rotates the UIView around its axis
    /// - Parameter duration: How long will the rotation animation take
    func rotate(duration: CFTimeInterval, reversed: Bool = false) {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = reversed ? NSNumber(value: -Double.pi * 2) : NSNumber(value: Double.pi * 2)
        rotation.duration = duration
        rotation.isCumulative = true
        rotation.repeatCount = 0
        rotation.timingFunction =  CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}

extension UIView  {
    /// Render the view within the view's bounds, then capture it as image.
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: frame.size)
        return renderer.image { _ in drawHierarchy(in: bounds, afterScreenUpdates: true) }
    }
}
