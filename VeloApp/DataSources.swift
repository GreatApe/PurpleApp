//
//  DataSources.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 20/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

extension UIColor {
    class func random() -> UIColor {
        func randomFloat() -> CGFloat {
            return CGFloat(arc4random() % 256)/256
        }
        
        return UIColor(red: randomFloat(), green: randomFloat(), blue: randomFloat(), alpha: 1.0)
    }
    
    class func coreHeaderCell() -> UIColor {
        return UIColor(white: 0.6, alpha: 1)
    }

    class func coreCell() -> UIColor {
        return UIColor(white: 0.7, alpha: 1)
    }
    
    class func indexCell() -> UIColor {
        return UIColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1)
    }
    
    class func computedHeaderCell() -> UIColor {
        return UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1)
    }

    class func computedCell() -> UIColor {
        return UIColor(red: 0.8, green: 0.8, blue: 0.9, alpha: 1)
    }
}
