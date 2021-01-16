//
//  CustomButton.swift
//  Youtube Loader
//
//  Created by isEmpty on 11.01.2021.
//

import UIKit

final class PlayButton: UIButton {
    
    //MARK: - Drawing
    override func draw(_ rect: CGRect) {
        
        let shadowPath = UIBezierPath(ovalIn: rect)
        let holePath = UIBezierPath(ovalIn: rect.insetBy(dx: 12, dy: 12)).reversing()
        shadowPath.append(holePath)
        layer.shadowColor = #colorLiteral(red: 0.5764705882, green: 0.6588235294, blue: 0.7019607843, alpha: 1).cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowPath = shadowPath.cgPath
        

        let path1 = UIBezierPath(ovalIn: rect.insetBy(dx: 12, dy: 12))
        UIColor.white.withAlphaComponent(0.4).setFill()
        path1.fill()
        
        let path2 = UIBezierPath(ovalIn: rect.insetBy(dx: 24, dy: 24))
        UIColor.white.setFill()
        path2.fill()
    }
}
