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
    
    // MARK: Callbacks
    
    override func prepareLayout() {
    }
    
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: 600, height: 400)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let columnWidths = [indexWidth] + mainWidths + computedWidths
        
        let offsetsMain = cumulate([indexWidth, largeMargin] + splice(mainWidths, margin: smallMargin), from: borderMargin)
        let offsetToComp = offsetsMain.last! + largeMargin + (selected ? mainWidths.last! : -smallMargin)
        let offsetsComp = cumulate(splice(computedWidths, margin: smallMargin), from: offsetToComp)

        let columnOffsets = offsetsMain + offsetsComp
        
        var result = [UICollectionViewLayoutAttributes]()
        
        for item in 0..<rows*mainWidths.count {
            let indexPath = NSIndexPath(forItem: item, inSection: 0)
            let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            
            let columnCount = columnWidths.count
            if item < rows*mainWidths.count {
                let row = item/columnCount
                let column = item % columnCount
                
                attr.alpha = 0.3
                attr.frame = CGRect(x: columnOffsets[column], y: 10 + CGFloat(row)*50, width: columnWidths[column], height: 44)
            }
            
            result.append(attr)
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