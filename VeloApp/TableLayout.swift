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
    
    private let borderMargin: CGFloat = 10
    private let largeMargin: CGFloat = 7
    private let smallMargin: CGFloat = 2
    
    private var columnWidths = [CGFloat]()
    private var columnOffsets = [CGFloat]()
    
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
        columnWidths = [indexWidth] + mainWidths + computedWidths
        
        let offsetsMain = cumulate([indexWidth, largeMargin] + splice(mainWidths, margin: smallMargin), from: borderMargin)
        let offsetToComp = offsetsMain.last! + largeMargin + (selected ? mainWidths.last! : -smallMargin)
        let offsetsComp = cumulate(splice(computedWidths, margin: smallMargin), from: offsetToComp)
        
        columnOffsets = offsetsMain + offsetsComp
    }
    
    override func collectionViewContentSize() -> CGSize {
        let width = columnOffsets.last! + (selected ? columnWidths.last! : -smallMargin) + borderMargin
        return CGSize(width: width, height: 400)
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let columnCount = columnWidths.count
        
        let row = indexPath.item/columnCount
        let column = indexPath.item % columnCount
        
        let hide = !selected && (column == mainWidths.count || column == mainWidths.count + computedWidths.count)
        attr.alpha = hide ? 0 : 1
        attr.frame = CGRect(x: columnOffsets[column], y: 10 + CGFloat(row)*50, width: columnWidths[column], height: 44)
        
        return attr
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result = [UICollectionViewLayoutAttributes]()
        
        for item in 0..<rows*columnWidths.count {
            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            if let attr = layoutAttributesForItemAtIndexPath(indexPath) {
                result.append(attr)
            }
        }
        
        return result
    }
    
//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
//        let x = CGFloat(Int(proposedContentOffset.x) % 60)
//        return proposedContentOffset
//    }
    
    // MARK: Pure functions
    
    private func splice(widths: [CGFloat], margin: CGFloat) -> [CGFloat] {
        guard let last = widths.last else { return [] }
        
        return widths.dropLast().reduce([]) { result, new in result + [new, margin] } + [last]
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