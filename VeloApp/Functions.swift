//
//  Functions.swift
//  Signalist
//
//  Created by Gustaf Kugelberg on 26/03/15.
//  Copyright (c) 2015 GreatApe. All rights reserved.
//

import UIKit

enum DataType: String, CustomStringConvertible {
    case CGFloat = "CGFloat"
    case CGPoint = "CGPoint"
    case Int = "Int"
    case CGFloats = "[CGFloat]"
    case CGPoints = "[CGPoint]"
    case Ints = "[Int]"
    
    static var all: Set<DataType> {
        return [.CGFloat, .CGPoint, Int, CGFloats, CGPoints, Ints]
    }
    
    static var scalars: Set<DataType> {
        return [.CGFloat, .CGPoint, Int]
    }
    
    static var vectors: Set<DataType> {
        return [.CGFloats, .CGPoints, Ints]
    }
    
    init(_ type: Any) {
        self = getType(type)
    }
    
    var description: String {
        return rawValue
    }
    
    var isVector: Bool { return DataType.vectors.contains(self) }
    
    var vector: DataType {
        switch self {
        case .CGFloat: return .CGFloats
        case .CGPoint: return .CGPoints
        case .Int: return .Ints
        default: fatalError("Not a scalar type")
        }
    }
}

func getType(type: Any) -> DataType {
    switch type {
    case _ as CGFloat.Type: return .CGFloat
    case _ as CGPoint.Type: return .CGPoint
    case _ as Int.Type: return .Int
    case _ as [CGFloat].Type: return .CGFloats
    case _ as [CGPoint].Type: return .CGPoints
    case _ as [Int].Type: return .Ints

    default: fatalError("Incorrect data type")
    }
}

// MARK: - Unary

func identity<T>(input: T) -> T { return input }

enum UnaryType: Equatable {
    case Group
    case Named
    case Prefix(precedence: Int)
    case Postfix(precedence: Int)
    
    var isGroup: Bool { if case .Group = self { return true } else { return false } }
    var isNamed: Bool { if case .Named = self { return true } else { return false } }
    var precedence: Int {
        switch self {
        case .Group, .Named: return 10
        case .Prefix(let p): return p
        case .Postfix(let p): return p
        }
    }
}

func ==(left: UnaryType, right: UnaryType) -> Bool {
    switch (left, right) {
    case (.Group, .Group), (.Named, .Named), (.Prefix, .Prefix), (.Postfix, .Postfix): return true
    default: return false
    }
}

func ==(left: BinaryType, right: BinaryType) -> Bool {
    switch (left, right) {
    case (.Named, .Named):
        return true
    case (.Infix, .Infix):
        return true
    default:
        return false
    }
}

struct UnaryFam: CustomStringConvertible {
    let name: String
    let type: UnaryType
    var ops: [(UnaryOperation, Bool)]
    
    var acceptedInputs: Set<DataType> {
        return Set(ops.filter(secundo).map { $0.0.inputType })
    }
    
    var acceptedOutputs: Set<DataType> {
        return Set(ops.filter(secundo).map { $0.0.outputType })
    }

    var acceptedOps: [UnaryOperation] {
        return ops.filter(secundo).map(primo)
    }
    
    var op: UnaryOperation? {
        if acceptedOps.count == 1 {
            return acceptedOps[0]
        }
        
        return nil
    }

    init() {
        self.init("[]", type: .Group, ops: UnaryOp { (x: Int) in x }, UnaryOp { (x: CGFloat) in x }, UnaryOp { (x: [CGFloat]) in x })
    }
    
    init(_ name: String, type: UnaryType, ops: UnaryOperation ...) {
        self.name = name
        self.type = type
        self.ops = ops.map { ($0, true) }
    }
    
    mutating func restrictInput(dataTypes: Set<DataType>) {
        ops = ops.map { ($0, $1 && dataTypes.contains($0.inputType)) }
    }
    
    mutating func restrictOutput(dataTypes: Set<DataType>) {
        ops = ops.map { ($0, $1 && dataTypes.contains($0.outputType)) }
    }
    
    mutating func unrestrict() {
        ops = ops.map { ($0.0, true) }
    }
    
    var description: String {
        var string = "UnaryFamily: \(name) (\(ops.count))"
        for op in ops {
            string += "\n    " + op.0.inputType.rawValue + " -> " + op.0.outputType.rawValue
            string += ": " + (op.1 ? "Y" : "x")
        }
        
        return string
    }
}

protocol UnaryOperation {
    var inputType: DataType { get }
    var outputType: DataType { get }
}

struct UnaryOp<I, O>: UnaryOperation {
    let inputType = DataType(I.self)
    let outputType = DataType(O.self)
    
    let f: I -> O
}

struct BinaryFam: CustomStringConvertible {
    let name: String
    let type: BinaryType

    var ops: [(BinaryOperation, Bool)]
    
    var acceptedLefts: Set<DataType> {
        return Set(ops.filter { $1 }.map { $0.0.leftType })
    }
    
    var acceptedRights: Set<DataType> {
        return Set(ops.filter { $1 }.map { $0.0.rightType })
    }
    
    var acceptedOutputs: Set<DataType> {
        return Set(ops.filter { $1 }.map { $0.0.outputType })
    }

    var acceptedOps: [BinaryOperation] {
        return ops.filter(secundo).map(primo)
    }
    
    var op: BinaryOperation? {
        if acceptedOps.count == 1 {
            return acceptedOps[0]
        }
        
        return nil
    }

    init(_ name: String, type: BinaryType, ops: BinaryOperation ...) {
        self.name = name
        self.type = type
        self.ops = ops.map { ($0, true) }
    }
    
    mutating func restrictLeft(dataTypes: Set<DataType>) {
        ops = ops.map { ($0, $1 && dataTypes.contains($0.leftType)) }
    }
    
    mutating func restrictRight(dataTypes: Set<DataType>) {
        ops = ops.map { ($0, $1 && dataTypes.contains($0.rightType)) }
    }
    
    mutating func restrictOutput(dataTypes: Set<DataType>) {
        ops = ops.map { ($0, $1 && dataTypes.contains($0.outputType)) }
    }
    
    mutating func unrestrict() {
        ops = ops.map { ($0.0, true) }
    }
    
    var description: String {
        var string = "BinaryFamily: \(name) (\(ops.count))"
        for op in ops {
            string += "\n    (" + op.0.leftType.rawValue + ", " + op.0.rightType.rawValue + ") -> " + op.0.outputType.rawValue
            string += ": " + (op.1 ? "Y" : "x")
        }
        
        return string
    }
}

enum Associativity {
    case Left
    case Right
    case None
}

enum BinaryType {
    case Named
    case Infix(precedence: Int, associativity: Associativity, commutative: Bool, stacked: Bool)

    var isNamed: Bool { if case .Named = self { return true } else { return false } }
    var isStacked: Bool { if case .Infix(_, _, _, let stacked) = self { return stacked } else { return false } }
    
    var precedence: Int { if case .Infix(let p, _, _, _) = self { return p } else { return 10 } }
    var associativity: Associativity { if case .Infix(_, let a, _, _) = self { return a } else { return .None } }
}

// Binary

protocol BinaryOperation {
    var leftType: DataType { get }
    var rightType: DataType { get }
    var outputType: DataType { get }
}

struct BinaryOp<L, R, O>: BinaryOperation {
    let leftType = DataType(L.self)
    let rightType = DataType(R.self)
    let outputType = DataType(O.self)
    
    let f: (L, R) -> O
}

struct Form<O> {
    let function: () -> O
    var value: O { return function() }
    
    init(value: O) {
        self.function = { value }
    }

    init(signal: Signal<O>) {
        self.function = { signal.value }
    }
    
    init<I>(op: UnaryOp<I, O>, input: Form<I>) {
        self.function = { op.f(input.value) }
    }
    
    init<L, R>(op: BinaryOp<L, R, O>, left: Form<L>, right: Form<R>) {
        self.function = { op.f(left.value, right.value) }
    }
}

func unaryForm<I, O>(op: UnaryOp<I, O>, _ tree: AbstractTree) -> Form<O>? {
    if let input: Form<I> = form(tree) {
        return Form<O>(op: op, input: input)
    }
    return nil
}

func binaryForm<L, R, O>(op: BinaryOp<L, R, O>, _ leftTree: AbstractTree, _ rightTree: AbstractTree) -> Form<O>? {
    if let left: Form<L> = form(leftTree), right: Form<R> = form(rightTree) {
        return Form<O>(op: op, left: left, right: right)
    }
    return nil
}

func trigger<S>(s: Signal<S>, with trigger: AnySignal) {
    print("Adding trigger for \(s): \(trigger.name)")
    
    switch trigger {
    case let trigger as Signal<CGFloat>: trigger.effect { _ in s.resend() }
    case let trigger as Signal<CGPoint>: trigger.effect { _ in s.resend() }
    case let trigger as Signal<Int>: trigger.effect { _ in s.resend() }
    case let trigger as Signal<[CGFloat]>: trigger.effect { _ in s.resend() }
    case let trigger as Signal<[CGPoint]>: trigger.effect { _ in s.resend() }
    case let trigger as Signal<[Int]>: trigger.effect { _ in s.resend() }

    default: fatalError("wrong trigger type")
    }
}

func printableValue(s: AnySignal) -> String {
    switch s {
    case let signal as Signal<CGFloat>: return "\(signal.value)"
    case let signal as Signal<Int>: return "\(signal.value)"
    default: return s.name
    }
}

func form<O>(tree: AbstractTree) -> Form<O>? {
    switch tree {
    case .Empty:
        return nil
    case let .Signal(anySignal):
        if let signal = anySignal as? Signal<O> {
            return Form<O>(signal: signal)
        }
    case let .Unary(unary, tree):
        switch unary.op {
        case let unary as UnaryOp<CGFloat, O>: return unaryForm(unary, tree)
        case let unary as UnaryOp<CGPoint, O>: return unaryForm(unary, tree)
        case let unary as UnaryOp<Int, O>: return unaryForm(unary, tree)
            
        case let unary as UnaryOp<[CGFloat], O>: return unaryForm(unary, tree)
        case let unary as UnaryOp<[CGPoint], O>: return unaryForm(unary, tree)
        case let unary as UnaryOp<[Int], O>: return unaryForm(unary, tree)
        default: return nil
        }

    case let .Binary(binary, leftTree, rightTree):
        switch binary.op {
        case let binary as BinaryOp<CGFloat, CGFloat, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<CGFloat, CGPoint, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<CGPoint, CGFloat, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<CGPoint, CGPoint, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<Int, Int, O>: return binaryForm(binary, leftTree, rightTree)
            
        case let binary as BinaryOp<[CGFloat], CGFloat, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[CGFloat], CGPoint, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[CGPoint], CGFloat, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[CGPoint], CGPoint, O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[Int], Int, O>: return binaryForm(binary, leftTree, rightTree)

        case let binary as BinaryOp<CGFloat, [CGFloat], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<CGFloat, [CGPoint], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<CGPoint, [CGFloat], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<CGPoint, [CGPoint], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<Int, [Int], O>: return binaryForm(binary, leftTree, rightTree)

        case let binary as BinaryOp<[CGFloat], [CGFloat], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[CGFloat], [CGPoint], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[CGPoint], [CGFloat], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[CGPoint], [CGPoint], O>: return binaryForm(binary, leftTree, rightTree)
        case let binary as BinaryOp<[Int], [Int], O>: return binaryForm(binary, leftTree, rightTree)
        default: return nil
        }
    }
    
    return nil
}

prefix operator • {}

prefix func •(signal: AnySignal) -> AbstractTree {
    return AbstractTree(signal)
}

infix operator • { precedence 130 associativity right}

//func •<I, O>(op: UnaryOp<I, O>, input: Form<I>) -> Form<O> {
//    return Form(op: op, input: input)
//}
//
//func •<L, R, O>(op: BinaryOp<L, R, O>, inputs: (Form<L>, Form<R>)) -> Form<O> {
//    return Form(op: op, left: inputs.0, right: inputs.1)
//}

func •(unary: UnaryFam, signal: AnySignal) -> AbstractTree {
    return AbstractTree(unary, AbstractTree(signal))
}

func •(unary: UnaryFam, tree: AbstractTree) -> AbstractTree {
    return AbstractTree(unary, tree)
}

func •(binary: BinaryFam, inputs: (AnySignal, AnySignal)) -> AbstractTree {
    return AbstractTree(binary, AbstractTree(inputs.0), AbstractTree(inputs.1))
}

func •(binary: BinaryFam, inputs: (AbstractTree, AbstractTree)) -> AbstractTree {
    return AbstractTree(binary, inputs.0, inputs.1)
}
