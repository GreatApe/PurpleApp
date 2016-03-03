//
//  Tensor.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 27/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation

struct Slice {
    let slicing: [Int?]
    let ordering: [Int]
    
    init(index: [Int]) {
        self.ordering = []
        self.slicing = index.map { $0 }
    }
    
    func freeing(dimension: Int) -> Slice {
        var newSlicing = slicing
        newSlicing[dimension] = nil
        
        let newOrdering = ordering + [dimension]
        return Slice(slicing: newSlicing, ordering: newOrdering)
    }
    
    func fixing(dimension: Int, at value: Int) -> Slice {
        var newSlicing = slicing
        newSlicing[dimension] = value
        
        var newOrdering = ordering
        if let oldFreeOrder = ordering.indexOf(dimension) {
            newOrdering.removeAtIndex(oldFreeOrder)
        }
        return Slice(slicing: newSlicing, ordering: newOrdering)
    }
    
    init(slicing: [Int?], ordering: [Int]) {
        self.ordering = ordering
        self.slicing = slicing
    }
    
    init(position: Int, alongDimension d: Int, dimensions: Int) {
        self.slicing = (0..<dimensions).map { $0 == d ? position : nil }
        self.ordering = (0..<dimensions).filter { $0 != d }
    }
    
    func contains(k: [Int]) -> Bool {
        return !zip(slicing, k).contains { si, ki in ki != si && si != nil }
    }
}

struct Tensor: CustomStringConvertible {
    // MARK: Public

    let size: [Int]
    private var slice: Slice
    
    init(size: [Int]) {
        self.init(size: size, sliceToOne: false)
    }
    
    init(size: [Int], sliceToOne: Bool) {
        self.size = size
        if sliceToOne {
            self.slice = Slice(index: Array(count: size.count, repeatedValue: 0))
        }
        else {
            self.slice = Slice(slicing: Array(count: size.count, repeatedValue: nil), ordering: Array(0..<size.count))
        }
    }

    init(size: [Int], slicing: [Int?], ordering: [Int]) {
        self.size = size
        self.slice = Slice(slicing: slicing, ordering: ordering)
    }
    
    // MARK: Public Mutation Methods
    
    mutating func free(dimension: Int) {
        slice = slice.freeing(dimension)
    }
    
    mutating func fix(dimension: Int, at value: Int) {
        slice = slice.fixing(dimension, at: value)
    }
    
    // MARK: Public Convenience Methods

    var ordering: [Int] {
        return slice.ordering
    }
    
    var slicing: [Int?] {
        return slice.slicing
    }

    func isFree(dimension: Int) -> Bool {
        return slice.slicing[dimension] == nil
    }

    var count: Int {
        return size.reduce(1, combine: *)
    }
    
    var dimension: Int {
        return size.count
    }
    
    var slicedSize: [Int] {
        return slice(size)
    }

    var sliced: Tensor {
        return Tensor(size: slicedSize)
    }

    // MARK: Public Operative Methods

    func normalise(index: [Int]) -> [Int] {
        let padded = index + Array(count: max(0, dimension - index.count), repeatedValue: 0)
        return Array(padded[0..<dimension])
    }
    
    func coords(s: Slice) -> [[Int]] {
        return (0..<count).map(vectorise).filter(s.contains)
    }
    
    func slice(x: [Int]) -> [Int] {
        return slice.ordering.map { x[$0] }
    }
    
    func unslice(s: [Int]) -> [Int] {
        var k = slice.slicing
        zip(s, slice.ordering).forEach { si, o in k[o] = si }
        
        return k.map { $0! }
    }
    
    func unslice(k: Int) -> Int {
        return k |> sliced.vectorise |> unslice |> linearise
    }
    
//    func unslice(s: [Int]) -> [Int] {
//        return slicing.enumerate().map { i, si in self.ordering.indexOf(i).map { s[$0] } ?? si! }
//    }
    
    func linearise(i: [Int]) -> Int {
        return i*multiplier
    }
    
    func vectorise(k: Int) -> [Int] {
        return zip(multiplier, size).map { n, s in k/n % s }
    }
    
    // MARK: Private Helpers

    private var multiplier: [Int] {
        return size.dropLast().reduce([1]) { result, dim in result + [result.last!*dim] }
    }
    
    var description: String {
        return "T(size: \(size), slicing: [\(slice.slicing.map { $0 == nil ? ":" : String($0!) }.joinWithSeparator(", "))], order: \(slice.ordering))"
    }
}




