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

struct Tensor {
    // MARK: Public

    let size: [Int]
    let slice: Slice
    
    init(size: [Int]) {
        self.size = size
        self.slice = Slice(slicing: Array(count: size.count, repeatedValue: nil), ordering: Array(0..<size.count))
    }

    init(size: [Int], slicing: [Int?], ordering: [Int]) {
        self.size = size
        self.slice = Slice(slicing: slicing, ordering: ordering)
    }
    
    // MARK: Public Convenience Methods

    var count: Int {
        return size.reduce(1, combine: *)
    }
    
    var dimension: Int {
        return size.count
    }
    
    var slicedSize: [Int] {
        return slice(size)
    }

    var slicedTensor: Tensor {
        return Tensor(size: slicedSize)
    }

    // MARK: Public Operative Methods

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
}