//
//  Tree.swift
//  Signalist
//
//  Created by Gustaf Kugelberg on 04/04/15.
//  Copyright (c) 2015 GreatApe. All rights reserved.
//

import UIKit

final class Box<T> {
    var content: T
    
    init(_ content: T) {
        self.content = content
    }
}

typealias Address = [Turn]

enum Turn {
    case Left
    case Right
    case Down
}

func +(left: Address, right: Turn) -> Address {
    return left + [right]
}

func parent(address: Address) -> Address? {
    return address.count == 0 ? nil : Array(address.dropLast())
}

enum AbstractTree: CustomStringConvertible {
    case Empty
    case Signal(AnySignal)
    indirect case Unary(UnaryFam, AbstractTree)
    indirect case Binary(BinaryFam, AbstractTree, AbstractTree)
    
    init() {
        self = .Empty
    }
    
    init(_ signal: AnySignal) {
        self = .Signal(signal)
    }
    
    init(_ unary: UnaryFam, _ tree: AbstractTree = AbstractTree()) {
        self = .Unary(unary, tree)
    }
    
    init(_ binary: BinaryFam, _ left: AbstractTree = AbstractTree(), _ right: AbstractTree = AbstractTree()) {
        self = .Binary(binary, left, right)
    }

    var hasEmptySpot: Bool { return firstEmpty() != nil }
    
    var isEmpty: Bool {
        if case .Empty = self { return true }
        else { return false }
    }
    
    var isSignal: Bool {
        if case .Signal = self { return true }
        else { return false }
    }

    var isOperation: Bool {
        switch self {
        case .Unary, .Binary: return true
        default: return false
        }
    }
    
    var isGrouping: Bool {
        if case .Unary(let unary, _) = self { return unary.type.isGroup }
        else { return false }
    }

    var isNamedOperation: Bool {
        switch self {
        case .Empty, .Signal:
            return false
        case let .Unary(unary, _):
            return unary.type.isNamed
        case let .Binary(binary, _, _):
            return binary.type.isNamed
        }
    }
    
    var signal: AnySignal? {
        if case let .Signal(s) = self {
            return s
        }

        return nil
    }
    
    func findRight(address: Address = [], condition: AbstractTree -> Bool) -> Address? {
        if condition(self) {
            return address
        }
        
        switch self {
        case .Empty, .Signal:
             return nil
        case let .Unary(_, tree):
            return tree.findRight(address + [.Down], condition: condition)
        case let .Binary(_, _, rightTree):
            return rightTree.findRight(address + [.Right], condition: condition)
        }
    }
    
    var copy: AbstractTree {
        switch self {
        case let .Unary(unary, tree):
            return .Unary(unary, tree.copy)
        case let .Binary(binary, leftTree, rightTree):
            return .Binary(binary, leftTree.copy, rightTree.copy)
        default:
            return self
        }
    }
    
    mutating func detach(address: Address) -> AbstractTree? {
        return replace(address, with: AbstractTree())
    }
    
    mutating func replace(address: Address, with tree: AbstractTree) -> AbstractTree? {
        fatalError()
        
        //        print("REPLACE: \(address) in \(self) with \(tree)")
//
//        if let nav = address.first {
//            let remainingNavs = Array(address.dropFirst())
//            
//            switch (self, nav) {
//            case (let .Unary(_, box), .Down):
//                return box.content.replace(remainingNavs, with: tree)
//            case (let .Binary(_, leftBox, _), .Left):
//                return leftBox.content.replace(remainingNavs, with: tree)
//            case (let .Binary(_, _, rightBox), .Right):
//                return rightBox.content.replace(remainingNavs, with: tree)
//            default:
////                break
//                return nil
//            }
//        }
//        
//        let rest = self
//        self = tree
//
//        return rest
    }
    
    func firstEmpty(address: Address = []) -> Address? {
        switch self {
        case .Empty:
            return address
        case let .Unary(_, tree):
            return tree.firstEmpty(address + [.Down])
        case let .Binary(_, leftTree, rightTree):
            return leftTree.firstEmpty(address + [.Left]) ?? rightTree.firstEmpty(address + [.Right])
        default:
            return nil
        }
    }
    
    subscript(address: Address) -> AbstractTree {
        return subtree(address)!
    }
    
    func subtree(address: Address) -> AbstractTree? {
        if let nav = address.first {
            let remainingNavs = Array(address.dropFirst())
            
            switch (self, nav) {
            case (let .Unary(_, tree), .Down):
                return tree.subtree(remainingNavs)
            case (let .Binary(_, leftTree, _), .Left):
                return leftTree.subtree(remainingNavs)
            case (let .Binary(_, _, rightTree), .Right):
                return rightTree.subtree(remainingNavs)
            default:
                return nil
            }
        }
        
        return self
    }
    
    var outputType: DataType? {
        if complete && acceptedOutputs.count == 1, let type = acceptedOutputs.first {
            return type
        }
        
        return nil
    }
    
    var acceptedOutputs: Set<DataType> {
        switch self {
        case .Empty: return DataType.all
        case let .Signal(signal): return [signal.outputType]
        case let .Unary(unary, _): return unary.acceptedOutputs
        case let .Binary(binary, _, _): return binary.acceptedOutputs
        }
    }
    
    var precedence: Int {
        switch self {
        case .Empty: return 0
        case .Signal: return 10
        case let .Unary(unary, _): return unary.type.precedence
        case let .Binary(binary, _, _): return binary.type.precedence
        }
    }
    
    mutating func rerestrict() {
        unrestrict()
        restrictDown()
        restrictUp()
    }
    
    mutating func unrestrict() {
        switch self {
        case .Empty:
            return
        case .Signal:
            return
        case .Unary(var unary, var tree):
            unary.unrestrict()
            tree.unrestrict()
            self = .Unary(unary, tree)
        case .Binary(var binary, var leftTree, var rightTree):
            binary.unrestrict()
            leftTree.unrestrict()
            rightTree.unrestrict()
            self = .Binary(binary, leftTree, rightTree)
        }
    }
    
    mutating func restrictUp() -> Set<DataType> {
        switch self {
        case .Empty:
            return DataType.all
        case let .Signal(signal):
            return [signal.outputType]
        case .Unary(var unary, var tree):
            unary.restrictInput(tree.restrictUp())
            self = .Unary(unary, tree)
            return unary.acceptedOutputs
        case .Binary(var binary, var leftTree, var rightTree):
            binary.restrictLeft(leftTree.restrictUp())
            binary.restrictRight(rightTree.restrictUp())
            self = .Binary(binary, leftTree, rightTree)
            return binary.acceptedOutputs
        }
    }
    
    mutating func restrictDown(types: Set<DataType> = DataType.all) {
        switch self {
        case .Empty:
            return
        case .Signal:
            return
        case .Unary(var unary, var tree):
            unary.restrictOutput(types)
            tree.restrictDown(unary.acceptedInputs)
            self = .Unary(unary, tree)
        case .Binary(var binary, var leftTree, var rightTree):
            binary.restrictOutput(types)
            leftTree.restrictDown(binary.acceptedLefts)
            rightTree.restrictDown(binary.acceptedRights)
            self = .Binary(binary, leftTree, rightTree)
        }
    }
    
    var height: Int {
        switch self {
        case .Empty, .Signal:
            return 0
        case let .Unary(_, tree):
            return 1 + tree.height
        case let .Binary(_, leftTree, rightTree):
            return 1 + max(leftTree.height, rightTree.height)
        }
    }
    
    var name: String {
        switch self {
        case .Empty: return "•"
        case let .Signal(signal): return signal.name
        case let .Unary(unary, _): return unary.name
        case let .Binary(binary, _, _): return binary.name
        }
    }
    
    var complete: Bool {
        switch self {
        case .Empty:
            return false
        case .Signal:
            return true
        case let .Unary(_, tree):
            return tree.complete
        case let .Binary(_, leftTree, rightTree):
            return leftTree.complete && rightTree.complete
        }
    }
    
    var empties: [AbstractTree] {
        switch self {
        case .Empty:
            return [self]
        case .Signal:
            return []
        case let .Unary(_, tree):
            return tree.empties
        case let .Binary(_, leftTree, rightTree):
            return leftTree.empties + rightTree.empties
        }
    }
    
    var description: String {
        switch self {
        case .Empty:
            return "•"
        case let .Signal(signal):
            return signal.name
        case let .Unary(unary, tree):
            switch unary.type {
            case .Group: return "[\(tree)]"
            case .Named: return unary.name + "(\(tree))"
            case .Prefix: return unary.name + "(\(tree))"
            case .Postfix: return "(\(tree))" + unary.name
            }
        case let .Binary(binary, leftTree, rightTree):
            switch binary.type {
            case .Named: return binary.name + "(\(leftTree), \(rightTree))"
            case .Infix: return "(\(leftTree) " + binary.name + " \(rightTree))"
            }
        }
    }
}



