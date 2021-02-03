//
//  AddingButton.swift
//  Youtube Loader
//
//  Created by isEmpty on 24.01.2021.
//

import UIKit

final class AddingRoundedButton: UIButton {
    
    private func createBottomRightShadow(_ width: CGFloat, _ context: CGContext, _ height: CGFloat) {
        let shadow1Color = Colors.lightyBlueColor
        let shadow = NSShadow()
        shadow.shadowColor = shadow1Color
        shadow.shadowOffset = CGSize(width: width * 2, height: 3)
        shadow.shadowBlurRadius = 10
        
        context.saveGState()
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: (-width * 2) + 13, y: 13, width: width - 20, height: height - 20))
        context.saveGState()
        context.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: (shadow.shadowColor as! UIColor).cgColor)
        UIColor.white.setFill()
        ovalPath.fill()
        context.restoreGState()
        
        context.endTransparencyLayer()
        context.restoreGState()
    }
    
    private func createTopLeftShadow(_ width: CGFloat, _ context: CGContext, _ height: CGFloat) {
        let shadow1Color = UIColor.white
        let shadow = NSShadow()
        shadow.shadowColor = shadow1Color
        shadow.shadowOffset = CGSize(width: width * 2, height: -3)
        shadow.shadowBlurRadius = 10
        
        context.saveGState()
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: (-width * 2) + 7, y: 13, width: width - 20, height: height - 20))
        context.saveGState()
        context.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: (shadow.shadowColor as! UIColor).cgColor)
        UIColor.white.setFill()
        ovalPath.fill()
        context.restoreGState()
        
        context.endTransparencyLayer()
        context.restoreGState()
    }
    

    private func createPlus(_ rect: CGRect, _ width: CGFloat, _ height: CGFloat) {
        let centerColor = Colors.lighestBlueColor
        
        let plus2Width: CGFloat = rect.width * 0.47
        let plus2Height:CGFloat = plus2Width * 0.185
        
        let plus1Height:CGFloat = rect.width * 0.47
        let plus1Width: CGFloat = plus1Height * 0.185
        
        let centerX = (rect.minX + width) / 2
        let centerY = (rect.minY + height) / 2
        let rectangle1Path = UIBezierPath(roundedRect: CGRect(x: centerX - (plus1Width / 2), y: centerY - (plus1Height / 2), width: plus1Width, height: plus1Height), cornerRadius: plus1Width / 2)
        centerColor.setFill()
        rectangle1Path.fill()
        
        let rectangle2Path = UIBezierPath(roundedRect: CGRect(x: centerX - (plus2Width / 2), y: centerY - (plus2Height / 2), width: plus2Width, height: plus2Height), cornerRadius: plus2Height / 2)
        centerColor.setFill()
        rectangle2Path.fill()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.clear(rect)

        let width = rect.width
        let height = rect.height
        
        createBottomRightShadow(width, context, height)
        createTopLeftShadow(width, context, height)
    
        let oval = UIBezierPath(ovalIn: CGRect(x: 13, y: 13, width: width - 26, height: height - 26))
        Colors.whiteBlueColor.setFill()
        oval.fill()
        
        let centerColor = Colors.lighestBlueColor

        let plus2Width: CGFloat = rect.width * 0.47
        let plus2Height:CGFloat = plus2Width * 0.185

        let plus1Height:CGFloat = rect.width * 0.47
        let plus1Width: CGFloat = plus1Height * 0.185

        let centerX = (rect.minX + width) / 2
        let centerY = (rect.minY + height) / 2
        let rectangle1Path = UIBezierPath(roundedRect: CGRect(x: centerX - (plus1Width / 2), y: centerY - (plus1Height / 2), width: plus1Width, height: plus1Height), cornerRadius: plus1Width / 2)

        let rectangle2Path = UIBezierPath(roundedRect: CGRect(x: centerX - (plus2Width / 2), y: centerY - (plus2Height / 2), width: plus2Width, height: plus2Height), cornerRadius: plus2Height / 2)
        
        let overalPaths = UIBezierPath(cgPath: rectangle1Path.cgPath)
        overalPaths.append(rectangle2Path)
        centerColor.setFill()
        overalPaths.fill()
        
        let shadow = NSShadow()
        shadow.shadowColor = Colors.lightyBlueColor
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = CGSize(width: 2, height: 2)
        
        context.saveGState()
        context.clip(to: overalPaths.bounds)
        
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        let bezierOpaqueShadow = (shadow.shadowColor as! UIColor).withAlphaComponent(1)
        context.setShadow(offset: shadow.shadowOffset, blur: shadow.shadowBlurRadius, color: bezierOpaqueShadow.cgColor)
        context.setBlendMode(.sourceOut)
        context.beginTransparencyLayer(auxiliaryInfo: nil)

        bezierOpaqueShadow.setFill()
        overalPaths.fill()
        context.endTransparencyLayer()
        context.endTransparencyLayer()
        context.restoreGState()
    }
}
