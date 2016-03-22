//
//  InputController.swift
//  Signalist
//
//  Created by Gustaf Kugelberg on 25/08/15.
//  Copyright © 2015 GreatApe. All rights reserved.
//

import UIKit

class InputController {
    var unaries = [String : UnaryFam]()
    var binaries = [String : BinaryFam]()
    
    init() {
        addOperations()
    }
    
    func addOperations() {
        let hlvf = UnaryOp { (x: CGFloat) in x/2 }
        let hlvF = UnaryOp { (x: [CGFloat]) in x.map { $0/2 } }
        
        let dblf = UnaryOp { (x: CGFloat) in 2*x }
        let dblF = UnaryOp { (x: [CGFloat]) in x.map { 2*$0 } }
        
        let dbli = UnaryOp { (x: Int) in 2*x }
        let dblI = UnaryOp { (x: [Int]) in x.map { 2*$0 } }
        
        let sinF = UnaryOp { (x: CGFloat) in sin(x) }
        let sinf = UnaryOp { (x: [CGFloat]) in componentwise(sin)(x) }
        
        let cosf = UnaryOp { (x: CGFloat) in cos(x) }
        let cosF = UnaryOp { (x: [CGFloat]) in componentwise(cos)(x) }
        
        let tanf = UnaryOp { (x: CGFloat) in tan(x) }
        let tanF = UnaryOp { (x: [CGFloat]) in componentwise(tan)(x) }

        func binaryFam(name: String, _ type: BinaryType, _ function: (CGFloat, CGFloat) -> CGFloat) -> BinaryFam {
            let functionff = BinaryOp<CGFloat, CGFloat, CGFloat>(f: function)
            let functionfF = BinaryOp<CGFloat, [CGFloat], [CGFloat]>(f: componentwiseRight(function))
            let functionFf = BinaryOp<[CGFloat], CGFloat, [CGFloat]>(f: componentwiseLeft(function))
            let functionFF = BinaryOp<[CGFloat], [CGFloat], [CGFloat]>(f: componentwiseBoth(function))

            return BinaryFam(name, type: type, ops: functionff, functionfF, functionFf, functionFF)
        }

        func binaryIntFam(name: String, _ type: BinaryType, _ function: (Int, Int) -> Int) -> BinaryFam {
            let functionii = BinaryOp<Int, Int, Int>(f: function)
            let functioniI = BinaryOp<Int, [Int], [Int]>(f: componentwiseRight(function))
            let functionIi = BinaryOp<[Int], Int, [Int]>(f: componentwiseLeft(function))
            let functionII = BinaryOp<[Int], [Int], [Int]>(f: componentwiseBoth(function))
            
            return BinaryFam(name, type: type, ops: functionii, functioniI, functionIi, functionII)
        }

        addBinary(binaryFam("+", .Infix(precedence: 1, associativity: .Left, commutative: true, stacked: false), +))
        addBinary(binaryFam("-", .Infix(precedence: 1, associativity: .Left, commutative: false, stacked: false), -))
        addBinary(binaryFam("×", .Infix(precedence: 3, associativity: .Left, commutative: true, stacked: false), *))
        addBinary(binaryFam("/", .Infix(precedence: 3, associativity: .Left, commutative: false, stacked: true), /))
        addBinary(binaryFam("^", .Infix(precedence: 4, associativity: .Right, commutative: false, stacked: false), pow))
        
        let lenp = UnaryOp { (p: CGPoint) in norm(p) }
        let lenP = UnaryOp { (p: [CGPoint]) in componentwise(norm)(p) }

        let negf = UnaryOp { (x: CGFloat) in -x }
        let negF = UnaryOp { (x: [CGFloat]) in x.map(-) }

        let sqrtf = UnaryOp { (x: CGFloat) in sqrt(x) }
        let sqrtF = UnaryOp { (x: [CGFloat]) in x.map(sqrt) }

        addUnary(UnaryFam("-", type: .Prefix(precedence: 2), ops: negf, negF))
        addUnary(UnaryFam("len", type: .Named, ops: lenp, lenP))
        
        addUnary(UnaryFam("dbl", type: .Named, ops: dbli, dblI))
        addUnary(UnaryFam("hlv", type: .Named, ops: hlvf, hlvF))
        addUnary(UnaryFam("sin", type: .Named, ops: sinf, sinF))
        addUnary(UnaryFam("cos", type: .Named, ops: cosf, cosF))
        addUnary(UnaryFam("tan", type: .Named, ops: tanf, tanF))
        
        addUnary(UnaryFam("√", type: .Prefix(precedence: 9), ops: sqrtf, sqrtF))
    }
    
    func test1() -> (Signal<Double>, Form<Double>)? {
        guard let sinus = unaries["sin"] else {
            return nil
        }
        
        let a = Signal(value: 0.0)
        
        return (a, form(sinus•a)!)
    }
    
    func test2() -> (Signal<Double>, Signal<Double>, Signal<Double>, Form<Double>)? {
        guard let plus = binaries["+"], times = binaries["*"], sinus = unaries["sin"] else {
            return nil
        }

        let a = Signal(value: 0.0)
        let b = Signal(value: 0.0)
        let c = Signal(value: 0.0)
        
        let tree = sinus•times•(plus•(a, b), •c)
        
        return (a, b, c, form(tree)!)
    }
    
    func addBinary(binary: BinaryFam) { binaries[binary.name] = binary }
    
    func addUnary(unary: UnaryFam) { unaries[unary.name] = unary }
}