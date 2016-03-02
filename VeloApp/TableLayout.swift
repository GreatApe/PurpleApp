//
//  TableLayout.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TableLayout: UICollectionViewLayout {

    // MARK: Input parameters
    
    // General
    
    var tensor: Tensor
    var tableConfig: TableConfig
    var rowConfigs: [RowConfig] // Indexed by the unsliced index, unlike other arrays
    
    var squeezeRows = false
    var squeezeColumns = false
    
    // Row heights
    
    var fieldHeight: CGFloat = 30
    var cellHeight: CGFloat = 40
    var compHeight: CGFloat = 80

    // Column widths

    var indexWidth: CGFloat = 100
    var mainWidths: [CGFloat] { return Array(count: tableConfig.columns, repeatedValue: 80) }
    var emptyWidths: [CGFloat] { return Array(count: tableConfig.emptyColumns, repeatedValue: 60) }
    var compWidths: [CGFloat] { return Array(count: tableConfig.compColumns, repeatedValue: 80) }
    var emptyCompWidths: [CGFloat] { return Array(count: tableConfig.emptyCompColumns, repeatedValue: 60) }
    
    // MARK: Internal parameters

    // General
    
    private let borderMargin: CGFloat = 10
    private let largeMargin: CGFloat = 7
    private let smallMargin: CGFloat = 2

    private var tableNameHeight: CGFloat = 40
    private var metaIndexWidth: CGFloat = 100
    private var metaHeaderHeight: CGFloat = 40
    
    // MARK: Initialisation

    required init?(coder aDecoder: NSCoder) {
        self.tensor = Tensor(size: [])
        let tableConfig = TableConfig(columns: 1)
        self.tableConfig = tableConfig
        self.rowConfigs = [tableConfig.rowConfig(1)]
        super.init(coder: aDecoder)
    }
    
    init(tensor: Tensor, tableConfig: TableConfig, rowConfigs: [RowConfig]) {
        self.tensor = tensor
        self.tableConfig = tableConfig
        self.rowConfigs = rowConfigs
        super.init()
    }

    // MARK: Convenience methods
    
    var duplicate: TableLayout { return TableLayout(tensor: tensor, tableConfig: tableConfig, rowConfigs: rowConfigs) }

    // MARK: Updating input parameters

    func update(size: [Int], tableConfig: TableConfig, rowCounts: [Int]) {
        self.tensor = Tensor(size: size, sliceToOne: true)
        self.tableConfig = tableConfig
        self.rowConfigs = rowCounts.map { tableConfig.rowConfig($0) }
    }
    
    // MARK: Computed parameters

    var metaColumns: Int { return tensor.slicedSize.count > 0 ? tensor.slicedSize[0] : 1 }
    var metaRows: Int { return tensor.slicedSize.count > 1 ? tensor.slicedSize[1] : 1 }

    // MARK: Parameters calculated in prepare layout
    
    // Columns

    private var columnOffsets: [CGFloat]!
    private var columnWidths: [CGFloat]!

    // Rows
    
    private var rowOffsets: [[CGFloat]]!
    private var rowHeights: [[CGFloat]]!
    
    // Table
    
    private var tableWidth: CGFloat = 0
    private var tableHeights: [CGFloat] = []
    private var tableOffsets: [CGFloat] = []
    
    // MARK: Other parameters

    // Scrolling
    
    private var scrollingOffset = CGPoint()
    private var merelyScrolled = false
    
    func updateScrollOffset(offset: CGPoint) {
        scrollingOffset = offset
        invalidateLayout()
    }
    
    // Meta labels

    private var startGuide: CGPoint { return CGPoint(x: metaIndexWidth, y: metaHeaderHeight + tableNameHeight) }
    private var permanentGuide: CGPoint { return CGPoint(x: 0, y: tableNameHeight) }
    
    // MARK: Callbacks
    
    override func prepareLayout() {
        if !merelyScrolled {
            prepareColumns()
            prepareRows()
            prepareTableSizes()
        }
        
        merelyScrolled = false
    }
    
    private func prepareColumns() {
        let widthsMain = [indexWidth, largeMargin] + splice(mainWidths + emptyWidths, with: smallMargin)
        let widthsComp = [largeMargin] + splice(compWidths + emptyCompWidths, with: smallMargin)

        columnOffsets = cumulate(widthsMain + widthsComp, from: borderMargin)
        columnWidths = [indexWidth]
        columnWidths.appendContentsOf(mainWidths)
        columnWidths.appendContentsOf(emptyWidths)
        columnWidths.appendContentsOf(compWidths)
        columnWidths.appendContentsOf(emptyCompWidths)
        //        columnWidths = [indexWidth] + mainWidths + emptyWidths + compWidths + emptyCompWidths
    }

    private func prepareRows() {
        let compHeights = Array(count: rowConfigs.first!.compRows, repeatedValue: compHeight)
        rowOffsets = []
        rowHeights = []

        for metaRow in 0..<metaRows {
            for metaColumn in 0..<metaColumns {
                let index = [metaColumn, metaRow] |> tensor.sliced.normalise |> tensor.unslice |> tensor.linearise
                let rowConfig = rowConfigs[index]
                let mainHeights = Array(count: rowConfig.rows, repeatedValue: cellHeight)
                let emptyHeights = Array(count: rowConfig.emptyRows, repeatedValue: cellHeight)
                
                let heightsMain = [fieldHeight, 0] + splice(mainHeights + emptyHeights, with: smallMargin)
                let heightsComp = [largeMargin] + splice(compHeights, with: smallMargin)
                
                rowOffsets.append(cumulate(heightsMain + heightsComp, from: borderMargin))
                var theseRowHeights = [fieldHeight]
                theseRowHeights.appendContentsOf(mainHeights)
                theseRowHeights.appendContentsOf(emptyHeights)
                theseRowHeights.appendContentsOf(compHeights)
                rowHeights.append(theseRowHeights)
                
//                let a = [metaColumn, metaRow]
//                let b = a |> tensor.sliced.normalise
//                let c = b |> tensor.unslice
//                let d = c |> tensor.linearise
//                print("Making rows for \(a) -> \(b) -> \(c) -> \(d): \(rowConfig.totalRows)")
            }
        }

        print("Made rows \(rowHeights.map { $0.count } ) - \(self)")
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
        let width = startGuide.x + permanentGuide.x + CGFloat(metaColumns)*tableWidth
        let height = startGuide.y + permanentGuide.y + tableOffsets.last! + tableHeights.last!
        return CGSize(width: width, height: height)
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var result = [UICollectionViewLayoutAttributes]()

//        print("self: \(self)")
//        print("tensor: \(tensor)")
//        print("columns: \(columnOffsets.count), rows: \(rowOffsets.count) - \(rowOffsets.map { $0.count })")
        
        for metaRow in 0..<metaRows {
            for metaColumn in 0..<metaColumns {
                let s = [metaColumn, metaRow] |> tensor.sliced.normalise |> tensor.sliced.linearise
//
//                let n = [metaColumn, metaRow] |> tensor.sliced.normalise
//                let j = n |> tensor.unslice
//                let jj = j |> tensor.linearise
                
//                print("- (\([metaColumn, metaRow]) > \(n) > \(j) > \(jj))  --- cells[\(s)] : rows:\(rowHeights[s].count)")
                
                for item in 0..<rowHeights[s].count*columnWidths.count {
                    let indexPath = NSIndexPath(forItem: item, inSection: s)
                    if let attr = layoutAttributesForItemAtIndexPath(indexPath) {
                        result.append(attr)
                    }
                    else {
                        print("Invalid cell indexPath: \(indexPath)")
                    }
                }
            }
        }
        
        let tableCount = metaRows*metaColumns
        
        for (category, categorySize) in tensor.size.enumerate() {
            for value in 0..<categorySize {
                let indexPath = NSIndexPath(forItem: value, inSection: tableCount + category)
                if let attr = layoutAttributesForItemAtIndexPath(indexPath) {
                    result.append(attr)
                }
                else {
                    print("Invalid category indexPath: \(indexPath)")
                }
            }
        }
        
        let indexPath = NSIndexPath(forItem: 0, inSection: tableCount + tensor.dimension)
        if let attr = layoutAttributesForItemAtIndexPath(indexPath) {
            result.append(attr)
        }
        else {
            print("Invalid name indexPath: \(indexPath)")
        }

        return result
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let tableCount = metaRows*metaColumns
        
        switch indexPath.section {
        case 0..<tableCount: return layoutAttributesForCell(indexPath)
        case tableCount..<tableCount + tensor.dimension: return layoutAttributesForCategory(indexPath)
        case tableCount + tensor.dimension: return layoutAttributesForName(indexPath)
        default: fatalError("Impossible section")
        }
    }
    
    func adjust(p: CGPoint, stopScroll: CGPoint, dimension: (x: Bool, y: Bool)) -> CGPoint {
        let subtractAdd = permanentGuide + scrollingOffset
        let x = dimension.x ? adjust(p.x, stopScroll: stopScroll.x, subtractAdd: subtractAdd.x) : p.x
        let y = dimension.y ? adjust(p.y, stopScroll: stopScroll.y, subtractAdd: subtractAdd.y) : p.y
        return CGPoint(x: x, y: y)
    }
    
    func adjust(r: CGFloat, stopScroll: CGFloat, subtractAdd: CGFloat) -> CGFloat {
        return delay(r - subtractAdd, untilBelow: -stopScroll) + subtractAdd
    }

    func layoutAttributesForCell(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let section = indexPath.section
        let metaRow = section/metaColumns
        let metaColumn = section % metaColumns
        
        let row = indexPath.item/tableConfig.totalColumns
        let column = indexPath.item % tableConfig.totalColumns
        
        let isHeader = row == 0
        let isIndex = column == 0
        
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let cellOffset = CGPoint(x: columnOffsets[column], y: rowOffsets[section][row])
        let tableOffset = CGPoint(x: CGFloat(metaColumn)*tableWidth, y: tableOffsets[metaRow])
        
        let stopX = columnOffsets.last! - indexWidth - borderMargin - smallMargin
        let stopY = rowOffsets[section].last! - smallMargin - cellHeight
        
        let pos = adjust(cellOffset + tableOffset + startGuide, stopScroll: CGPoint(x: stopX, y: stopY), dimension: (isIndex, isHeader))
        
        let size = CGSize(width: columnWidths[column], height: rowHeights[section][row])
        
        attr.frame = CGRect(origin: pos, size: size)
        
        let isEmptyRow = rowConfigs[section |> tensor.unslice].isEmptyRow(row)
        let isEmptyColumn = tableConfig.isEmptyColumn(column)
        
        attr.alpha = (isEmptyRow ? 0 : 0.5) + (isEmptyColumn ? 0 : 0.5)
        attr.zIndex = (isHeader ? 5 : 0) + (isIndex ? 10 : 0)
        
        return attr
    }
    
    func layoutAttributesForCategory(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let dimension = indexPath.section - metaRows*metaColumns
        let value = indexPath.item

        if let order = tensor.ordering.indexOf(dimension) {
            if order == 0 {
                let preX = CGFloat(value)*tableWidth + startGuide.x + borderMargin
                let stopScrollX = tableWidth - metaIndexWidth - 2*borderMargin
                let x = adjust(preX, stopScroll: stopScrollX, subtractAdd: permanentGuide.x + scrollingOffset.x)
                let y = scrollingOffset.y + tableNameHeight
                attr.frame.origin = CGPoint(x: x, y: y)
                attr.zIndex = 25
            }
            else {
                let x = scrollingOffset.x
                let preY = tableOffsets[value] + startGuide.y + borderMargin
                let stopScrollY = tableHeights[value] - metaHeaderHeight - 2*borderMargin
                let y = adjust(preY, stopScroll: stopScrollY, subtractAdd: permanentGuide.y + scrollingOffset.y)
                attr.frame.origin = CGPoint(x: x, y: y)
                attr.zIndex = 30
            }
        }
        else {
            let x = CGFloat(dimension + 3)*100
            let y = CGFloat(indexPath.item)*0
            let pos = CGPoint(x: x, y: y)
            attr.zIndex = 50
            attr.frame.origin = scrollingOffset + pos
        }
        attr.frame.size = CGSize(width: metaIndexWidth, height: metaHeaderHeight)
        return attr
    }

    func layoutAttributesForName(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attr.frame.origin = scrollingOffset
        attr.frame.size = CGSize(width: 1000, height: tableNameHeight)
        attr.zIndex = 40
        return attr
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        scrollingOffset = newBounds.origin
        merelyScrolled = true

        return true
    }
    
//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
//        let x = CGFloat(Int(proposedContentOffset.x) % 60)
//        return proposedContentOffset
//    }
    
    // MARK: Pure helper functions
    
    func delay(value: CGFloat, untilBelow lowerBound: CGFloat) -> CGFloat {
        if value > 0 {
            return value
        }
        else if value < lowerBound {
            return value - lowerBound
        }
        
        return 0
    }

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
