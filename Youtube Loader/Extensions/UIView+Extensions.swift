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
