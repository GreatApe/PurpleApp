//
//  Extensions.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

let π = CGFloat(M_PI)

// Composition

infix operator >>> { associativity left }
func >>><A, B, C>(f: A -> B, g: B-> C) -> A -> C {
    return { x in g(f(x)) }
}

// Forward Pipe

infix operator |> { associativity left precedence 81 }

func |> <T, U>(value: T, function: (T -> U)) -> U {
    return function(value)
}

func |> <T, U, V>(value: T, functions: (T -> U, T -> V)) -> (U, V) {
    return (functions.0(value), functions.1(value))
}

func |> <S, T, U, V>(values: (S, T), functions: (S -> U, T -> V)) -> (U, V) {
    return (functions.0(values.0), functions.1(values.1))
}

func |> <T, U, V, W>(value: T, functions: (T -> U, T -> V, T -> W)) -> (U, V, W) {
    return (functions.0(value), functions.1(value), functions.2(value))
}

func |> <R, S, T, U, V, W>(values: (R, S, T), functions: (R -> U, S -> V, T -> W)) -> (U, V, W) {
    return (functions.0(values.0), functions.1(values.1), functions.2(values.2))
}

func |> <T, U, V, W, X>(value: T, functions: (T -> U, T -> V, T -> W, T -> X)) -> (U, V, W, X) {
    return (functions.0(value), functions.1(value), functions.2(value), functions.3(value))
}

// [Int] operations

func *(lhs: [Int], rhs: [Int]) -> Int {
    return zip(lhs, rhs).map(*).reduce(0, combine: +)
}

// CGPoint operations

func norm(p: CGPoint) -> CGFloat {
    return p.norm
}

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

func * (lhs: (Int, Int), rhs: CGPoint) -> CGPoint {
    return CGPoint(x: CGFloat(lhs.0)*rhs.x, y: CGFloat(lhs.1)*rhs.y)
}

// CGSize

func * (lhs: (Int, Int), rhs: CGSize) -> CGSize {
    return CGSize(width: CGFloat(lhs.0)*rhs.width, height: CGFloat(lhs.1)*rhs.height)
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

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: 1)
    }
    
    convenience init(hex: Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }

    class func random() -> UIColor {
        func randomFloat() -> CGFloat { return CGFloat(arc4random() % 256)/256 }
        return UIColor(red: randomFloat(), green: randomFloat(), blue: randomFloat(), alpha: 1.0)
    }
    
    class func menu() -> UIColor {
        return UIColor(hex: 0x4F6067)
    }

    class func normalCell() -> UIColor {
        return UIColor(hex: 0xEFF0F1)
    }
    
    class func indexCell() -> UIColor {
        return UIColor(hex: 0xDDE0E1)
    }
    
    class func headerCell() -> UIColor {
        return UIColor(hex: 0xC5CBCC)
    }
    
    class func cellText() -> UIColor {
        return UIColor(hex: 0x203035)
    }

    class func computedCell() -> UIColor {
        return UIColor(hex: 0x849095)
    }
    
    class func newComputedCell() -> UIColor {
        return UIColor(hex: 0xD3D6D7)
    }
    
    class func background() -> UIColor {
        return UIColor(hex: 0xffffff)
    }
    
    class func canvas() -> UIColor {
        return UIColor(hex: 0xdddddd)
    }
}

// MARK: From Signalist

extension CGPoint {
    var polar: Polar {
        return Polar(r: norm, phi: atan2(y, x))
    }
    
    init(polar: Polar) {
        x = polar.cartesian.x
        y = polar.cartesian.y
    }
    
    init(r: CGFloat, phi: CGFloat) {
        self.init(polar: Polar(r: r, phi: phi))
    }
    
    func approach(goal: CGPoint, by factor: CGFloat) -> CGPoint {
        return (1 - factor)*self + factor*goal
    }
}

prefix func -(value: CGPoint) -> CGPoint {
    return CGPoint() - value
}

struct Polar {
    var r: CGFloat
    var phi: CGFloat
    
    var cartesian: CGPoint {
        return CGPoint(x: r*cos(phi), y: r*sin(phi))
    }
    
    func cartesian(center: CGPoint) -> CGPoint {
        return CGPoint(x: center.x + r*cos(phi), y: center.y + r*sin(phi))
    }
    
    func rotated(phi: CGFloat) -> Polar {
        return self*Polar(r: 1, phi: phi)
    }
}

func * (lhs: Polar, rhs: Polar) -> Polar {
    return Polar(r: lhs.r*rhs.r, phi: lhs.phi + rhs.phi)
}

func rotate(phi: CGFloat)(p: Polar) -> Polar {
    return p*Polar(r: 1, phi: phi)
}

extension CGSize {
    func heighten(dh: CGFloat) -> CGSize { return CGSize(width: width, height: height + dh) }
    func widen(dw: CGFloat) -> CGSize { return CGSize(width: width + dw, height: height) }
}

extension CGRect {
    func down(dy: CGFloat) -> CGRect { return CGRect(origin: origin.down(dy), size: size) }
    func right(dx: CGFloat) -> CGRect { return CGRect(origin: origin.right(dx), size: size) }
    
    func padUp(dy: CGFloat) -> CGRect { return CGRect(origin: origin.down(-dy), size: size.heighten(dy)) }
    func padDown(dy: CGFloat) -> CGRect { return CGRect(origin: origin, size: size.heighten(dy)) }
    func padLeft(dx: CGFloat) -> CGRect { return CGRect(origin: origin.right(-dx), size: size.widen(dx)) }
    func padRight(dx: CGFloat) -> CGRect { return CGRect(origin: origin, size: size.widen(dx)) }
    
    var mid: CGPoint { return CGPoint(x: midX, y: midY) }
    
    init(center: CGPoint, size: CGSize) {
        self.init(origin: CGPoint(x: center.x - size.width/2, y: center.y - size.height/2), size: size)
    }
    
    func grow(delta: CGFloat) -> CGRect {
        let dw = delta*width
        let dh = delta*height
        
        return CGRect(x: origin.x - dw, y: origin.y - dh, width: width + 2*dw, height: height + 2*dh)
    }
    
    var center: CGPoint { return CGPoint(x: midX, y: midY) }
    
    var lowerRight: CGPoint { return CGPoint(x: maxX, y: maxY) }
    
    var lowerMid: CGPoint { return CGPoint(x: midX, y: maxY) }
    
    var lowerLeft: CGPoint { return CGPoint(x: minX, y: maxY) }
    
    var midLeft: CGPoint { return CGPoint(x: minX, y: midY) }
    
    var upperRight: CGPoint { return CGPoint(x: maxX, y: minY) }
    
    var upperMid: CGPoint { return CGPoint(x: midX, y: minY) }
    
    var upperLeft: CGPoint { return CGPoint(x: minX, y: minY) }
    
    var midRight: CGPoint { return CGPoint(x: maxX, y: midY) }
    
    func insetX(dx: CGFloat) -> CGRect {
        return CGRect(x: origin.x + dx, y: origin.y, width: width - 2*dx, height: height)
    }
    
    func insetY(dy: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y + dy, width: width, height: height - 2*dy)
    }
    
    func move(dr: CGPoint) -> CGRect {
        return CGRect(origin: origin + dr, size: size)
    }
    
    func moveX(value: CGFloat) -> CGRect {
        return CGRect(origin: origin + CGPoint(x: value, y: 0), size: size)
    }
    
    func moveY(value: CGFloat) -> CGRect {
        return CGRect(origin: origin + CGPoint(x: 0, y: value), size: size)
    }
    
    func newWidth(value: CGFloat) -> CGRect {
        return CGRect(origin: origin, size: CGSize(width: value, height: height))
    }
    
    func newHeight(value: CGFloat) -> CGRect {
        return CGRect(origin: origin, size: CGSize(width: width, height: value))
    }
}

// MARK: - CGSize Operators

func *(lhs: CGFloat, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs*rhs.width, height: lhs*rhs.height)
}

func *(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width*rhs.width, height: lhs.height*rhs.height)
}

func +(lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width+rhs.width, height: lhs.height+rhs.height)
}

func +(lhs: CGSize, rhs: CGPoint) -> CGSize {
    return CGSize(width: lhs.width + rhs.x, height: lhs.height + rhs.y)
}




