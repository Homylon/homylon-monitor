//
//  Public extensions.swift
//  HomylonMonitor2
//
//  Created by Rob on 22/05/2023.
//

import Foundation

public extension Float {
    static var random:Float {
        get {
            return Float(arc4random()) / 0xFFFFFFFF
        }
    }
    static func random(min: Float, max: Float) -> Float {
        return Float.random * (max - min) + min
    }
    
}
