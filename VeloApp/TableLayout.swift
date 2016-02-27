//
//  TableLayout.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

struct TensorHelper {
    var dimensions: [Int] = [3, 3, 3]
    
//    func position(section:)
}


class TableLayout: UICollectionViewLayout {
    var config = TableConfig()
    
    var selected = true

    var indexWidth: CGFloat { return 100 }
    var mainWidths: [CGFloat] { return Array(count: config.columns, repeatedValue: 80) }
    var emptyWidths: [CGFloat] { return Array(count: config.emptyColumns, repeatedValue: 60) }
    var compWidths: [CGFloat] { return Array(count: config.compColumns, repeatedValue: 80) }
    var emptyCompWidths: [CGFloat] { return Array(count: config.emptyCompColumns, repeatedValue: 60) }
    
    var fieldHeight: CGFloat { return 30 }
    var mainHeights: [CGFloat] { return Array(count: config.rows, repeatedValue: 40) }
    var emptyHeights: [CGFloat] { return Array(count: config.emptyRows, repeatedValue: 40) }
    var compHeights: [CGFloat] { return Array(count: config.compRows, repeatedValue: 60) }
    
    private let borderMargin: CGFloat = 10
    private let largeMargin: CGFloat = 7
    private let smallMargin: CGFloat = 2
    
    private var columnOffsets: [CGFloat]!
    private var columnWidths: [CGFloat]!
    
    private var rowOffsets: [CGFloat]!
    private var rowHeights: [CGFloat]!
    
    var duplicate: TableLayout {
        let result = TableLayout()
        result.config = config
        
        return result
    }
    
    // MARK: Callbacks
    
    override func prepareLayout() {
        let widthsMain = [indexWidth, largeMargin] + splice(mainWidths + emptyWidths, with: smallMargin)
        let widthsComp = [largeMargin] + splice(compWidths + emptyCompWidths, with: smallMargin)
        
        columnOffsets = cumulate(widthsMain + widthsComp, from: borderMargin)
        columnWidths = [indexWidth] + mainWidths + emptyWidths + compWidths + emptyCompWidths
        
        let heightsMain = [fieldHeight, 0] + splice(mainHeights + emptyHeights, with: smallMargin)
        let heightsComp = [largeMargin] + splice(compHeights, with: smallMargin)
        
        rowOffsets = cumulate(heightsMain + heightsComp, from: borderMargin)
        rowHeights = [fieldHeight] + mainHeights + emptyHeights + compHeights
        
        print("## prepareLayout")
        print("total rows: \(config.totalRows)")
        print("total columns: \(config.totalColumns)")
        print("total cells: \(config.totalCells)")
        print("config:\n\(config)")
        
        print("columnOffsets: \(columnOffsets)")
        print("columnWidths: \(columnWidths)")
        
        print("rowOffsets: \(rowOffsets)")
        print(" -heightsMain: \(heightsMain)")
        print(" -heightsComp: \(heightsComp)")
        print("rowHeights: \(rowHeights)")
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
        let row = indexPath.item/config.totalColumns
        let column = indexPath.item % config.totalColumns
        
        print("attr: \(row):\(column)")
        
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attr.frame = CGRect(x: columnOffsets[column], y: rowOffsets[row], width: columnWidths[column], height: rowHeights[row])
        attr.alpha = config.isHidden(row, column: column) ? 0 : (config.isEmpty(row, column: column) ? 0.4 : 1)
        
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
    
//    private func alternate(value: CGFloat, with otherValue: CGFloat, count: Int) -> [CGFloat] {
//        guard count > 0 else { return [] }
//        
//        return (0..<count).reduce([]) { result, new in result + [value, otherValue] } + [value]
//    }

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
//override func prepareLayout() {
//    let offsetsMain = cumulate([indexWidth, largeMargin] + splice(mainWidths, with: smallMargin), from: borderMargin)
//    let offsetToComp = offsetsMain.last! + largeMargin + (selected ? mainWidths.last! : -smallMargin)
//    let offsetsComp = cumulate(splice(computedWidths, with: smallMargin), from: offsetToComp)
//    
//    columnOffsets = offsetsMain + offsetsComp
//    columnWidths = [indexWidth] + mainWidths + computedWidths
//    
//    let rowOffsetsMain = cumulate([fieldHeight, 0] + alternate(mainHeight, with: smallMargin, count: config.rows), from: borderMargin)
//    let rowOffsetToComp = rowOffsetsMain.last! + largeMargin + (selected ? mainHeight : -smallMargin)
//    let rowOffsetsComp = cumulate(alternate(computedHeight, with: smallMargin, count: config.computedRows), from: rowOffsetToComp)
//    
//    rowOffsets = rowOffsetsMain + rowOffsetsComp
//    
//    let mainHeights = Array(count: config.rows + config.emptyRows, repeatedValue: mainHeight)
//    let computedHeights = Array(count: config.computedRows, repeatedValue: computedHeight)
//    
//    rowHeights = [fieldHeight] + mainHeights + computedHeights
//}






