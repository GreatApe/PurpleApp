//
//  TableLayout.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TableLayout: UICollectionViewLayout {
    var metaColumns = 3
    var metaRows = 4
    
//    var tensor: Tensor
    
    // Columns
    
    var columnConfig = ColumnConfig()
    
    var indexWidth: CGFloat { return 100 }
    var mainWidths: [CGFloat] { return Array(count: columnConfig.columns, repeatedValue: 80) }
    var emptyWidths: [CGFloat] { return Array(count: columnConfig.emptyColumns, repeatedValue: 60) }
    var compWidths: [CGFloat] { return Array(count: columnConfig.compColumns, repeatedValue: 80) }
    var emptyCompWidths: [CGFloat] { return Array(count: columnConfig.emptyCompColumns, repeatedValue: 60) }
    
    private var columnOffsets: [CGFloat]!
    private var columnWidths: [CGFloat]!

    // Rows
    
    var rowConfigs = [RowConfig]()

    var fieldHeight: CGFloat = 30
    var cellHeight: CGFloat = 40
    var compHeight: CGFloat = 80
    
    private var rowOffsets: [[CGFloat]]!
    private var rowHeights: [[CGFloat]]!
    
    // General
    
    private let borderMargin: CGFloat = 10
    private let largeMargin: CGFloat = 7
    private let smallMargin: CGFloat = 2

    private var tableWidth: CGFloat = 0
    private var tableHeights: [CGFloat] = []
    private var tableOffsets: [CGFloat] = []
    
    // Scrolling
    
    private var scrollingOffset = CGPoint()
    
//    var duplicate: TableLayout {
//        let result = TableLayout()
//        result.config = config
//        
//        return result
//    }
    
    
    // MARK: Scrolling
    
    func scrolled(offset: CGPoint) {
        scrollingOffset = offset
        invalidateLayout() // FIXME: Optimise
    }
    
    // MARK: Callbacks
    
    override func prepareLayout() {
        prepareColumns()
        prepareRows()
        prepareTableSizes()
    }
    
    private func prepareColumns() {
        let widthsMain = [indexWidth, largeMargin] + splice(mainWidths + emptyWidths, with: smallMargin)
        let widthsComp = [largeMargin] + splice(compWidths + emptyCompWidths, with: smallMargin)
        
        columnOffsets = cumulate(widthsMain + widthsComp, from: borderMargin)
        columnWidths = [indexWidth] + mainWidths + emptyWidths + compWidths + emptyCompWidths
    }

    private func prepareRows() {
        let compHeights = Array(count: rowConfigs.first!.compRows, repeatedValue: compHeight)
        rowOffsets = []
        rowHeights = []
        
        for rowConfig in rowConfigs {
            let mainHeights = Array(count: rowConfig.rows, repeatedValue: cellHeight)
            let emptyHeights = Array(count: rowConfig.emptyRows, repeatedValue: cellHeight)
            
            let heightsMain = [fieldHeight, 0] + splice(mainHeights + emptyHeights, with: smallMargin)
            let heightsComp = [largeMargin] + splice(compHeights, with: smallMargin)
            
            rowOffsets.append(cumulate(heightsMain + heightsComp, from: borderMargin))
            rowHeights.append([fieldHeight] + mainHeights + emptyHeights + compHeights)
        }
    }
    
    private func prepareTableSizes() {
        tableWidth = (columnOffsets.last! + columnWidths.last! + borderMargin)
        
        tableHeights = []
        tableOffsets = [0]
        
        for metaRow in 0..<metaRows {
            let indicesInMetaRow = (metaRow*metaColumns..<(metaRow + 1)*metaColumns)
            let heightsInMetaRow = indicesInMetaRow.map { self.rowOffsets[$0].last! + self.rowHeights[$0].last! + self.borderMargin }
            let maxHeightInMetaRow = heightsInMetaRow.maxElement()!
            tableHeights.append(maxHeightInMetaRow)
            tableOffsets.append(tableOffsets.last! + maxHeightInMetaRow)
        }
        
        tableOffsets.removeLast()
    }
    
    override func collectionViewContentSize() -> CGSize {
        return (metaColumns, 1)*CGSize(width: tableWidth, height: tableOffsets.last! + tableHeights.last!)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result = [UICollectionViewLayoutAttributes]()
        
        for section in 0..<metaRows*metaColumns {
            for item in 0..<rowHeights[section].count*columnWidths.count {
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                if let attr = layoutAttributesForItemAtIndexPath(indexPath) {
                    result.append(attr)
                }
            }
        }
        
        return result
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let section = indexPath.section
        let metaRow = section/metaColumns
        let metaColumn = section % metaColumns

        let row = indexPath.item/columnConfig.totalColumns
        let column = indexPath.item % columnConfig.totalColumns
        
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let origin = CGPoint(x: columnOffsets[column], y: rowOffsets[section][row])
        let offset = (metaColumn, 1)*CGPoint(x: tableWidth, y: tableOffsets[metaRow])
        
        let isHeader = row == 0
        
        func adjustY(y: CGFloat) -> CGFloat {
            let stopScrollY = rowOffsets[section].last! - fieldHeight - largeMargin
            return isHeader ? delay(y - scrollingOffset.y, untilBelow: -stopScrollY) + scrollingOffset.y : y
        }
        
        let isIndex = column == 0

        func adjustX(x: CGFloat) -> CGFloat {
            let stopScrollX = columnOffsets.last! - indexWidth  - largeMargin
            return isIndex ? delay(x - scrollingOffset.x, untilBelow: -stopScrollX) + scrollingOffset.x : x
        }

        let pos = CGPoint(x: adjustX(origin.x + offset.x), y: adjustY(origin.y + offset.y))
        
        
        let size = CGSize(width: columnWidths[column], height: rowHeights[section][row])

        attr.frame = CGRect(origin: pos, size: size)
        
        let isEmptyRow = rowConfigs[section].isEmptyRow(row)
        let isEmptyColumn = columnConfig.isEmptyColumn(column)
        
        attr.alpha = (isEmptyRow ? 0 : 0.5) + (isEmptyColumn ? 0 : 0.5)
        attr.zIndex = (isHeader ? 5 : 0) + (isIndex ? 10 : 0)
        
        return attr
    }
    
    func delay(value: CGFloat, untilBelow lowerBound: CGFloat) -> CGFloat {
        if value > 0 {
            return value
        }
        else if value < lowerBound {
            return value - lowerBound
        }
        
        return 0
    }
    
    //        let stopWidth = addComputedColumnsWidth.constant + (computedColumns.frame.width == 0 ? mainStack.spacing : 0)
    //        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - stopWidth)


//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
//        let x = CGFloat(Int(proposedContentOffset.x) % 60)
//        return proposedContentOffset
//    }
    
    // MARK: Pure helper functions
    
    private func splice(values: [CGFloat], with value: CGFloat) -> [CGFloat] {
        guard let last = values.last else { return [] }
        
        return values.dropLast().reduce([]) { result, new in result + [new, value] } + [last]
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

//        print("## prepareLayout")
//        print("total rows: \(config.totalRows)")
//        print("total columns: \(config.totalColumns)")
//        print("total cells: \(config.totalCells)")
//        print("config:\n\(config)")
//
//        print("columnOffsets: \(columnOffsets)")
//        print("columnWidths: \(columnWidths)")
//
//        print("rowOffsets: \(rowOffsets)")
//        print(" -heightsMain: \(heightsMain)")
//        print(" -heightsComp: \(heightsComp)")
//        print("rowHeights: \(rowHeights)")

