//
//  MatrixView.swift
//  HomylonMonitor3
//
//  Created by RobSQ Ista on 2/6/23.
//  Copyright © 2023 Rob Ista. All rights reserved.
//

import Foundation
import UIKit

class MatrixView: UIView {
   
    var animation: CAAnimation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
        self.matrix()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func startAnimation() {
        // Configure and start the animation
        animation = CAKeyframeAnimation(keyPath: "position")
        // add configuration for the animation
        layer.add(animation!, forKey: "position")
    }
    
    func stopAnimation() {
        // Stop or pause the animation
        layer.removeAnimation(forKey: "position")
    }
    

    func restart() {
        // layer.sublayers?.forEach { $0.removeFromSuperlayer() }  // Remove all sublayers
        self.clearMatrix()
        self.matrix()
    }
    //...
    func clearMatrix() {
        if let sublayers = self.layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeAllAnimations() // This removes all animations from the layer
                sublayer.removeFromSuperlayer()
            }
        }
    }

    func matrix() {
        // let characters = ["在", "自", "由", "世", "界", "中", "开", "放", "互", "联", "网", "是", "我", "的", "梦", "想"] // "In the free world, opening up the internet is my dream".
        let characters = ["愛", "和", "平", "喜", "樂", "友", "美", "光", "夢", "希", "福", "祥", "康", "慈", "善"] // peace, love, good, etc etc
        //let characters = ["𝔅", "ℭ", "𝔇", "𝔊", "ℌ", "𝔐", "𝔓", "ℜ", "𝔗", "𝔛", "𝔞", "𝔟", "𝔡", "𝔣", "𝔨", "𝔱"] /// no real meaning at all


        #if os(macOS)
            self.wantsLayer = true
        #endif
        
        #if os(macOS)
            self.wantsLayer = true
            let rootLayer = CALayer()
            rootLayer.frame = self.bounds
            rootLayer.backgroundColor = NSColor.black.cgColor
            self.layer = rootLayer
        #elseif os(iOS)
            self.layer.frame = self.bounds
            self.layer.backgroundColor = UIColor.black.cgColor
        #endif

        let offset = CGFloat(20.0)
        let noOfColumns = Int(self.frame.size.width/offset)
        let noOfRows = Int(self.frame.size.height/offset)
        for i in 0...10 {
            for j in 0..<noOfColumns + 1 {
                let textLayer = CATextLayer()
                let index = Int(arc4random() % UInt32(characters.count))
                
                let transform = CATransform3DIdentity
                if arc4random_uniform(5) == 0 { // 50% chance to flip
                    let flipAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.y")
                    flipAnimation.values = [0, Double.pi, 2 * Double.pi]  // rotate by 180 degrees and then back to 0
                    flipAnimation.duration = CFTimeInterval(Float.random(in: 4...12))
                    flipAnimation.repeatCount = .infinity  // repeat forever
                    textLayer.add(flipAnimation, forKey: nil)
                }
                
                
                if j == noOfColumns / 2 && i < noOfRows / 10 {
                    #if os(iOS)
                    textLayer.foregroundColor = UIColor.yellow.cgColor
                    #elseif os(macOS)
                    textLayer.foregroundColor = NSColor.yellow.cgColor
                    #endif
                    
                    let randomX = CGFloat(arc4random_uniform(UInt32(self.frame.size.width - 75))) + 75
                    textLayer.frame = CGRect(x: randomX, y: 0, width: CGFloat(160.0), height: CGFloat(20.0))
                    textLayer.string = "HOMYLON"
                } else {
                    #if os(iOS)
                    textLayer.foregroundColor = UIColor.green.cgColor
                    #elseif os(macOS)
                    textLayer.foregroundColor = NSColor.green.cgColor
                    #endif
                    
                    let startPoint = CGPoint(x: CGFloat(j) * offset, y: 0)
                    textLayer.frame = CGRect(x: startPoint.x, y: startPoint.y, width: CGFloat(20.0), height: CGFloat(20.0))
                    textLayer.string = characters[index]
                }
                
                textLayer.transform = transform
                
                textLayer.fontSize = CGFloat(Float(arc4random()) / Float(UINT32_MAX) * (16 - 8) + 8)
                textLayer.opacity = Float(arc4random()) / Float(UINT32_MAX) * (0.8 - 0.4) + 0.4
                self.layer.addSublayer(textLayer)
                
                let positionAnimation = CABasicAnimation(keyPath: "position")
                let point1 = CGPoint(x: textLayer.frame.origin.x, y: textLayer.frame.origin.y)
                let point2 = CGPoint(x: textLayer.frame.origin.x, y: self.layer.frame.size.height)
                positionAnimation.fromValue = NSValue(cgPoint: point1)
                positionAnimation.toValue = NSValue(cgPoint: point2)
                positionAnimation.duration = CFTimeInterval(Float(arc4random()) / Float(UINT32_MAX) * (12 - 4) + 4)
                positionAnimation.repeatCount = .infinity
                textLayer.add(positionAnimation, forKey: nil)
            }
        }

    }
}

