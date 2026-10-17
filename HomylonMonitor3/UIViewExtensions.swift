//
//  UIViewExtensions.swift
//  TestApp
//
//  Created by Rob on 27/10/2020.
//  Copyright © 2020 Rob Ista. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func fadeIn(withDuration duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, delay: 1.0, animations: {
            self.alpha = 1.0
        })
    }

    func fadeOut(withDuration duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, delay: 2.0, animations: {
            self.alpha = 0.0
        })
    }
    func showAndFadeOut() {
        let duration : TimeInterval = 2.0
        self.alpha = 1.0
        UIView.animate(withDuration: duration, delay: 3.0, animations: {
                   self.alpha = 0.0
               })
    }
    
}


