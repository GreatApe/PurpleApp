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
    
    var slicedSize: [Int] {
        return slice(size)
    }

    var slicedTensor: Tensor {
        return Tensor(size: slicedSize)
    }

    func coords(inSlice: Slice) -> [[Int]] {
        fatalError()
    }
    
    // MARK: Public Operation Methods
    
    func slice(x: [Int]) -> [Int] {
        return slice.ordering.map { x[$0] }
    }
    
    func unslice(s: [Int]) -> [Int] {
        var k = slice.slicing
        zip(s, slice.ordering).forEach { si, o in k[o] = si }
        
        return k.map { $0! }
    }
    
//    func unslice2(s: [Int]) -> [Int] {
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

//struct Tensor {
//    // MARK: Public
//    
//    let size: [Int]
//    
//    init(size: [Int]) {
//        self.init(size: size, indices: Array(0..<size.reduce(1, combine: *)))
//    }
//    
//    subscript(j: [Int?]) -> Tensor {
//        return slice(j)
//    }
//    
//    subscript(i: [Int]) -> Int {
//        return linearIndex(i)
//    }
//    
//    subscript(k: Int) -> [Int] {
//        return vectorIndex(k)
//    }
//    
//    var count: Int {
//        return size.reduce(1, combine: *)
//    }
//    
//    // MARK: Private
//    
//    private init(size: [Int], indices: [Int]) {
//        self.size = size
//        self.indices = indices
//    }
//    
//    private var indices: [Int]
//    
//    private func slice(j: [Int?]) -> Tensor {
//        func includeIndex(i: [Int], j: [Int?]) -> Bool {
//            return zip(i, j).reduce(true) { out, ij in out && (ij.1 == nil || ij.0 == ij.1) }
//        }
//        
//        func sliceIndices(j: [Int?]) -> [Int] {
//            return (0..<count).filter { k in includeIndex(vectorIndex(k), j: j) }
//        }
//        
//        func sliceSize(j: [Int?]) -> [Int] {
//            return zip(j, size).reduce([]) { out, js in out + (js.0 == nil ? [js.1] : []) }
//        }
//        
//        return Tensor(size: sliceSize(j), indices: sliceIndices(j))
//    }
//    
//    private func linearIndex(i: [Int]) -> Int {
//        return i*multiplier
//    }
//    
//    private func vectorIndex(k: Int) -> [Int] {
//        return zip(multiplier, size).map { n, s in k/n % s }
//    }
//    
//    private var multiplier: [Int] {
//        return size.dropLast().reduce([1]) { result, dim in result + [result.last!*dim] }
//    }
//}
//
