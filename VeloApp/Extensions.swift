//
//  Extensions.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

// [Int] operations

func *(lhs: [Int], rhs: [Int]) -> Int {
    return zip(lhs, rhs).map(*).reduce(0, combine: +)
}

// CGPoint operations

extension CGPoint: CustomStringConvertible {
    public var description: String {
        return "(\(x), \(y))"
    }
    
    var norm: CGFloat {
        return sqrt(self*self)
    }
    
    //    var slope: CGFloat {
    //        return (atan2(y, x) + 2.0*pi) % (2.0*pi)
    //    }
    
    func unit() -> CGPoint {
        if norm < 0.0001 {
            return CGPoint()
        }
        
        return (CGFloat(1.0)/norm)*self
    }
    
    func right(dx: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y)
    }
    
    func down(dy: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y + dy)
    }
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func += (inout lhs: CGPoint, rhs: CGPoint) {
    lhs = lhs + rhs
}

func -= (inout lhs: CGPoint, rhs: CGPoint) {
    lhs = lhs - rhs
}

func * (lhs: CGPoint, rhs: CGPoint) -> CGFloat {
    return lhs.x*rhs.x + lhs.y*rhs.y
}

func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs*rhs.x, y: lhs*rhs.y)
}

func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: rhs*lhs.x, y: rhs*lhs.y)
}

func | (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return rhs*((lhs*rhs)/(rhs*rhs))
}

// Scaling and clamping

func downscale(value: Float, between lowValue: Float, and highValue: Float) -> Float {
    return (value - lowValue)/(highValue - lowValue)
}

func downscale(value: CGFloat, between lowValue: CGFloat, and highValue: CGFloat) -> CGFloat {
    return (value - lowValue)/(highValue - lowValue)
}

func clamp(value: Float, between lowValue: Float = 0, and highValue: Float = 1) -> (value: Float, sign: Int) {
    if value > highValue {
        return (highValue, +1)
    }
    else if value < lowValue {
        return (lowValue, -1)
    }
    
    return (value, 0)
}

func clamp(value: CGFloat, above lowValue: CGFloat = 0, below highValue: CGFloat = 1) -> (value: CGFloat, sign: Int) {
    if value > highValue {
        return (highValue, +1)
    }
    else if value < lowValue {
        return (lowValue, -1)
    }
    
    return (value, 0)
}


func upscale(value: Float, between lowValue: Float, and highValue: Float) -> Float {
    return lowValue + value*(highValue - lowValue)
}

func upscale(value: CGFloat, between lowValue: CGFloat, and highValue: CGFloat) -> CGFloat {
    return lowValue + value*(highValue - lowValue)
}




