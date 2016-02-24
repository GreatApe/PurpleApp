//
//  TableLayout.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TableLayout: UICollectionViewLayout {
    var selected = true

    var indexWidth = CGFloat()
    var mainWidths = [CGFloat]()
    var computedWidths = [CGFloat]()

    var rows = 0
    var computedRows = 0
    
    var fieldHeight: CGFloat = 30
    var mainHeight: CGFloat = 40
    var computedHeight: CGFloat = 60
    
    private let borderMargin: CGFloat = 10
    private let largeMargin: CGFloat = 7
    private let smallMargin: CGFloat = 2
    
    private var columnOffsets = [CGFloat]()
    private var columnWidths = [CGFloat]()
    
    private var rowOffsets = [CGFloat]()
    private var rowHeights = [CGFloat]()
    
    var duplicate: TableLayout {
        let result = TableLayout()
        result.selected = selected
        result.indexWidth = indexWidth
        result.mainWidths = mainWidths
        result.computedWidths = computedWidths
        result.rows = rows
        result.computedRows = computedRows
        
        return result
    }
    
    // MARK: Callbacks
    
    override func prepareLayout() {
        let offsetsMain = cumulate([indexWidth, largeMargin] + splice(mainWidths, with: smallMargin), from: borderMargin)
        let offsetToComp = offsetsMain.last! + largeMargin + (selected ? mainWidths.last! : -smallMargin)
        let offsetsComp = cumulate(splice(computedWidths, with: smallMargin), from: offsetToComp)
        
        columnOffsets = offsetsMain + offsetsComp
        columnWidths = [indexWidth] + mainWidths + computedWidths
        
        let rowOffsetsMain = cumulate([fieldHeight, 0] + alternate(mainHeight, with: smallMargin, count: rows), from: borderMargin)
        let rowOffsetToComp = rowOffsetsMain.last! + largeMargin + (selected ? mainHeight : -smallMargin)
        let rowOffsetsComp = cumulate(alternate(computedHeight, with: smallMargin, count: computedRows), from: rowOffsetToComp)

        rowOffsets = rowOffsetsMain + rowOffsetsComp
        
        let mainHeights = Array(count: rows + 1, repeatedValue: mainHeight)
        let computedHeights = Array(count: computedRows, repeatedValue: computedHeight)
        
        rowHeights = [fieldHeight] + mainHeights + computedHeights
    }
    
    override func collectionViewContentSize() -> CGSize {
        let width = columnOffsets.last! + (selected ? columnWidths.last! : -smallMargin) + borderMargin
        let height = rowOffsets.last! + borderMargin
        return CGSize(width: width, height: height)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result = [UICollectionViewLayoutAttributes]()
        
        for item in 0..<rowHeights.count*columnWidths.count {
            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            if let attr = layoutAttributesForItemAtIndexPath(indexPath) {
                result.append(attr)
            }
        }
        
        return result
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let columnCount = columnWidths.count
        
        let row = indexPath.item/columnCount
        let column = indexPath.item % columnCount
        
        let hideColumn = !selected && (column == mainWidths.count || column == mainWidths.count + computedWidths.count)
        let hideRow = !selected && row == 1 + rows
        
        attr.alpha = hideColumn || hideRow ? 0.1 : 1
        attr.frame = CGRect(x: columnOffsets[column], y: rowOffsets[row], width: columnWidths[column], height: rowHeights[row])
                
        return attr
    }

//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
//        let x = CGFloat(Int(proposedContentOffset.x) % 60)
//        return proposedContentOffset
//    }
    
    // MARK: Pure functions
    
    private func splice(values: [CGFloat], with value: CGFloat) -> [CGFloat] {
        guard let last = values.last else { return [] }
        
        return values.dropLast().reduce([]) { result, new in result + [new, value] } + [last]
    }
    
    private func alternate(value: CGFloat, with otherValue: CGFloat, count: Int) -> [CGFloat] {
        guard count > 0 else { return [] }
        
        return (0..<count).reduce([]) { result, new in result + [value, otherValue] } + [value]
    }

    private func cumulate(distances: [CGFloat], from: CGFloat) -> [CGFloat] {
        var result = [CGFloat]()
        var cumulated = CGFloat()
        
        let dists = [from] + distances
        
        for i in 0..<dists.count/2 {
            cumulated += dists[2*i]
            result += [cumulated]
            cumulated += dists[2*i + 1]
        }
        
        return result
    }
}