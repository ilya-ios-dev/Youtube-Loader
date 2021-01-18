//
//  TimeInterval+Extensions.swift
//  Youtube Loader
//
//  Created by isEmpty on 18.01.2021.
//

import Foundation

extension TimeInterval {
    func stringFromTimeInterval() -> String {
        
        let time = NSInteger(self)
        let seconds = time % 60
        var minutes = (time / 60) % 60
        minutes += Int(time / 3600) * 60  // to account for the hours as minutes
        
        return String(format: "%0.2d:%0.2d",minutes,seconds)
    }
}
