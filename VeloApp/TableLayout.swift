//
//  TableLayout.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

//struct IndexPath: Hashable {
//    let section: Int
//    let item: Int
//    
//    var hashValue: Int {
//        return section*1000 + item
//    }
//}
//
//func == (lhs: IndexPath, rhs: IndexPath) -> Bool {
//    return lhs.item == rhs.item && lhs.section == rhs.section
//}

class TableLayout: UICollectionViewLayout {

    // MARK: Input parameters
    
    // General
    
    var tensor: Tensor
    var tableConfig: TableConfig
    var rowConfigs: [RowConfig] // Indexed by the unsliced index, unlike other arrays
    
    // Row heights
    
    var fieldHeight: CGFloat = 30
    var cellHeight: CGFloat = 40
    var compHeight: CGFloat = 80

    // Column widths

    var indexWidth: CGFloat = 200
    var mainWidths: [CGFloat] { return [170] + Array(count: max(0, tableConfig.columns - 1), repeatedValue: 110) }
    var emptyWidths: [CGFloat] { return Array(count: tableConfig.emptyColumns, repeatedValue: 60) }
    var compWidths: [CGFloat] { return Array(count: tableConfig.compColumns, repeatedValue: 120) }
    var emptyCompWidths: [CGFloat] { return Array(count: tableConfig.emptyCompColumns, repeatedValue: 60) }
    
    // MARK: Internal parameters

    // General
    
    private let borderMargin: CGFloat = 10
    private let largeMargin: CGFloat = 2
    private let smallMargin: CGFloat = 2

    private var metaIndexWidth: CGFloat = 100
    private var metaHeaderHeight: CGFloat = 30
    
    // MARK: Cache
    
    private var cachedAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
    
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

    func updateRowCounts(rowCounts: [Int]) {
        self.rowConfigs = rowCounts.map { tableConfig.rowConfig($0) }
    }
    
    func update(size: [Int], tableConfig: TableConfig, rowCounts: [Int]) {
        self.tensor = Tensor(size: size, sliceToOne: true)
        self.tableConfig = tableConfig
        self.rowConfigs = rowCounts.map { tableConfig.rowConfig($0) }
    }
    
    // MARK: Computed parameters

//    var metaColumns: Int { return tensor.slicedSize.count > 0 ? tensor.slicedSize[0] : 1 }
//    var metaRows: Int { return tensor.slicedSize.count > 1 ? tensor.slicedSize[1] : 1 }
    var metaColumns = 0
    var metaRows = 0

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
    var merelyChanged = false
    
    func updateScrollOffset(offset: CGPoint) {
        scrollingOffset = offset
        invalidateLayout()
    }
    
    // Meta labels

//    private var showMetaHeader: Bool { return tensor.slicedSize.count > 0 }
//    private var showMetaIndex: Bool { return tensor.slicedSize.count > 1 }
//    
//    private var guide: CGPoint { return CGPoint(x: showMetaIndex ? metaHeaderHeight : 0, y: showMetaHeader ? metaHeaderHeight : 0) }

    private var showMetaHeader = false
    private var showMetaIndex = false
    private var guide = CGPoint()

    // MARK: Callbacks
     
    override func prepareLayout() {
        if !merelyScrolled && !merelyChanged {
            print("preparing layout")
            
            let slicedSize = tensor.slicedSize
            metaColumns = slicedSize.count > 0 ? slicedSize[0] : 1
            metaRows = slicedSize.count > 1 ? slicedSize[1] : 1

            showMetaHeader = slicedSize.count > 0
            showMetaIndex = slicedSize.count > 1
            
            guide = CGPoint(x: showMetaIndex ? metaHeaderHeight : 0, y: showMetaHeader ? metaHeaderHeight : 0)
            
            prepareColumns()
            prepareRows()
            prepareTableSizes()
            
            cachedAttributes.removeAll(keepCapacity: true)
        }
        
        merelyChanged = false
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
//                let index = [metaColumn, metaRow] |> tensor.sliced.normalise |> tensor.unslice |> tensor.linearise
                let index = tensor.linearise(tensor.unslice(tensor.sliced.normalise([metaColumn, metaRow])))
                let rowConfig = rowConfigs[index]
                let mainHeights = Array(count: rowConfig.rows, repeatedValue: cellHeight)
                let emptyHeights = Array(count: rowConfig.emptyRows, repeatedValue: cellHeight)
                
                let heightsMain = [fieldHeight, smallMargin] + splice(mainHeights + emptyHeights, with: smallMargin)
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

//        print("Made rows \(rowHeights.map { $0.count } ) - \(self)")
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
    
    var contentSize: CGSize? {
        guard let lastTableOffset = tableOffsets.last, lastTableHeight = tableHeights.last else {
            return nil
        }
        
        let width = guide.x + CGFloat(metaColumns)*tableWidth
        let height = guide.y + lastTableOffset + lastTableHeight
        return CGSize(width: width, height: height)
    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize ?? CGSize()
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let (firstMetaColumn, lastMetaColumn, firstMetaRow, lastMetaRow) = metaRowsColumnsInRect(rect)
        
//        print("\(rect.minX)-\(rect.maxX) -> \(firstMetaColumn)-\(lastMetaColumn)")
//        print("\(rect.minY)-\(rect.maxY) -> \(firstMetaRow)-\(lastMetaRow)")

        var paths = [NSIndexPath]()
        
        for metaRow in firstMetaRow...lastMetaRow {
            for metaColumn in firstMetaColumn...lastMetaColumn {
//                let s = [metaColumn, metaRow] |> tensor.sliced.normalise |> tensor.sliced.linearise
                let s = tensor.sliced.linearise(tensor.sliced.normalise([metaColumn, metaRow]))

//                print("Section: \(s) \(rowHeights.count)")
                
                for item in 0..<rowHeights[s].count*columnWidths.count {
                    paths.append(NSIndexPath(forItem: item, inSection: s))
                }
            }
        }
        
        let tableCount = metaRows*metaColumns
        
        for (category, categorySize) in tensor.size.enumerate() {
            for value in 0..<categorySize {
                paths.append(NSIndexPath(forItem: value, inSection: tableCount + category))
            }
        }
        
        let masksSection = tableCount + tensor.dimension
        paths.append(NSIndexPath(forItem: 0, inSection: masksSection))
        paths.append(NSIndexPath(forItem: 1, inSection: masksSection))

//        print("layoutAttributesForElementsInRect \(paths.count)")
        
        return paths.flatMap(layoutAttributesForItemAtIndexPath)
    }

    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if let attribute = cachedAttributes[indexPath] {
            return attribute
        }

        let tableCount = metaRows*metaColumns
        
        let attribute: UICollectionViewLayoutAttributes
        
        switch indexPath.section {
        case 0..<tableCount: attribute = layoutAttributesForCell(indexPath)
        case tableCount..<tableCount + tensor.dimension: attribute = layoutAttributesForCategory(indexPath)
        case tableCount + tensor.dimension..<tableCount + tensor.dimension + 2: attribute = layoutAttributesForMasks(indexPath)
        default: fatalError("Impossible section")
        }
        cachedAttributes[indexPath] = attribute

//        print("created attribute \(indexPath)")
        
        return attribute
    }
    
    func adjust(p: CGPoint, stopScroll: CGPoint, dimension: (x: Bool, y: Bool)) -> CGPoint {
        let subtractAdd = guide + scrollingOffset
        let x = dimension.x ? adjust(p.x, stopScroll: stopScroll.x, subtractAdd: subtractAdd.x) : p.x
        let y = dimension.y ? adjust(p.y, stopScroll: stopScroll.y, subtractAdd: subtractAdd.y) : p.y
        return CGPoint(x: x, y: y)
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
        
        let pos = adjust(cellOffset + tableOffset + guide, stopScroll: CGPoint(x: stopX, y: stopY), dimension: (isIndex, isHeader))
        
        let size = CGSize(width: columnWidths[column], height: rowHeights[section][row])
        
        attr.frame = CGRect(origin: pos, size: size)
        
//        let isEmptyRow = rowConfigs[section |> tensor.unslice].isEmptyRow(row)
        let isEmptyRow = rowConfigs[tensor.unslice(section)].isEmptyRow(row)
        let isEmptyColumn = tableConfig.isEmptyColumn(column)
        
        attr.alpha = (isEmptyRow ? 0 : 0.5) + (isEmptyColumn ? 0 : 0.5)
        attr.zIndex = (isHeader ? 5 : 0) + (isIndex ? 10 : 0)
        
//        print("layoutAttributesForCell: \(indexPath.section) \(indexPath.item)")
        
        return attr
    }
    
    func layoutAttributesForCategory(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        let dimension = indexPath.section - metaRows*metaColumns
        let value = indexPath.item
        
        if let order = tensor.ordering.indexOf(dimension) {
            let x, y: CGFloat
            let z: Int
            let a: CGFloat
            let r: CGFloat
            let o: CGPoint

            let subtractAdd = guide + scrollingOffset
            
            if order == 0 {
                let preX = (CGFloat(value) + 1/2)*tableWidth + guide.x - metaIndexWidth/2
                let stopScrollX = tableWidth/2 - metaIndexWidth/2 - borderMargin
                x = adjust(preX, stopScroll: stopScrollX, subtractAdd: subtractAdd.x)
                y = max(scrollingOffset.y, 0)
                z = 50
                a = ease(guide.x - metaIndexWidth/2, to: guide.x)(x: x - scrollingOffset.x)
                r = 0
                o = CGPoint()
            }
            else {
                x = max(scrollingOffset.x, 0)
//                let preY = tableOffsets[value] + tableHeights[value]/2 + guide.y - metaIndexWidth/2
//                let stopScrollY = tableHeights[value]/2 - metaIndexWidth/2 - borderMargin
                let preY = tableOffsets[value] + guide.y
                let stopScrollY = tableHeights[value] - metaIndexWidth - borderMargin
                y = adjust(preY, stopScroll: stopScrollY, subtractAdd: subtractAdd.y)
                z = 55
                a = ease(guide.y - metaIndexWidth/2, to: guide.y)(x: y - scrollingOffset.y)
                r = -π/2
                o = CGPoint(x: (metaHeaderHeight - metaIndexWidth)/2, y: (metaIndexWidth - metaHeaderHeight)/2)
            }
            
            attr.transform = CGAffineTransformMakeRotation(r)
            attr.frame.origin = CGPoint(x: x, y: y) + o
            attr.zIndex = z
            attr.alpha = tensor.ordering.count == 2 ? a : 1
        }
        else {
            attr.zIndex = 0
            attr.frame.origin = CGPoint(x: -200, y: -200)
        }
        
        attr.frame.size = CGSize(width: metaIndexWidth, height: metaHeaderHeight)
        
        return attr
    }

    func layoutAttributesForMasks(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        guard let size = collectionView?.frame.size else { return attr }
        
        attr.frame.origin = scrollingOffset
        
        if indexPath.item == 0 {
            attr.frame.size = CGSize(width: guide.x, height: size.height)
        }
        else if indexPath.item == 1 {
            attr.frame.size = CGSize(width: size.width, height: guide.y)
        }
        
        attr.zIndex = 40
        return attr
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        scrollingOffset = newBounds.origin
        merelyScrolled = true

        invalidateLayoutWithContext(invalidationContextForBoundsChange(newBounds))
        
        return false
    }
    
    private func metaRowsColumnsInRect(rect: CGRect) -> (left: Int, right: Int, up: Int, down: Int) {
        let left = max(0, Int(floor(rect.minX/tableWidth)))
        let right = min(metaColumns - 1, Int(ceil(rect.maxX/tableWidth)))
        let up = metaRows - 1 - (tableOffsets.reverse().indexOf { $0 < rect.minY } ?? metaRows - 1)
        let down = metaRows - 1 - (tableOffsets.reverse().indexOf { $0 < rect.maxY } ?? metaRows - 1)

        return (left, right, up, down)
    }
    
    override func invalidationContextForBoundsChange(newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let (firstMetaColumn, lastMetaColumn, firstMetaRow, lastMetaRow) = metaRowsColumnsInRect(newBounds)
//        print("\(newBounds.minX)-\(newBounds.maxX) -> \(firstMetaColumn)-\(lastMetaColumn)")
//        print("\(newBounds.minY)-\(newBounds.maxY) -> \(firstMetaRow)-\(lastMetaRow)")

        var paths = [NSIndexPath]()
        
        func appendPath(section: Int, item: Int) {
            paths.append(NSIndexPath(forItem: item, inSection: section))
        }
        
        func appendPaths(section: Int, row: Int? = nil, column: Int? = nil) {
            let rowsInSection = rowHeights[section].count
            let columnsInSection = columnWidths.count
            
            let rows = (row ?? 0)...(row ?? rowsInSection - 1)
            let columns = (column ?? 0)...(column ?? columnsInSection - 1)
            
            for row in rows {
                for column in columns {
//                    print("   appending (\(row):\(column)))")
                    appendPath(section, item: column + row*columnsInSection)
                }
            }
        }
        
        func appendPathsMeta(metaRow metaRow: Int, metaColumn: Int, row: Int? = nil, column: Int? = nil) {
            //            print(" --- (\(metaRow):\(metaColumn)) ---")
//            let section = [metaColumn, metaRow] |> tensor.sliced.normalise |> tensor.sliced.linearise
            let section = tensor.sliced.linearise(tensor.sliced.normalise([metaColumn, metaRow]))
            appendPaths(section, row: row, column: column)
        }
        
        for metaRow in firstMetaRow...lastMetaRow {
            for metaColumn in firstMetaColumn...lastMetaColumn {
                appendPathsMeta(metaRow: metaRow, metaColumn: metaColumn, row: 0)
                appendPathsMeta(metaRow: metaRow, metaColumn: metaColumn, column: 0)
            }
        }
        
//        for metaRow in max(0, firstMetaRow - 1)...min(metaRows - 1, lastMetaRow + 1) {
//            //            appendPathsMeta(metaRow: metaRow, metaColumn: firstMetaColumn, column: 0)
//            for metaColumn in max(0, firstMetaColumn - 1)...min(metaColumns - 1, lastMetaColumn + 1) {
//                appendPathsMeta(metaRow: metaRow, metaColumn: metaColumn, row: 0)
//                appendPathsMeta(metaRow: metaRow, metaColumn: metaColumn, column: 0)
//            }
//        }


//        for metaColumn in max(0, firstMetaColumn - 1)...min(metaColumns - 1, lastMetaColumn + 1) {
//            appendPathsMeta(metaRow: firstMetaRow, metaColumn: metaColumn, row: 0)
//        }

//        for metaColumn in firstMetaColumn...lastMetaColumn {
//            if firstMetaRow - 1 >= 0 {
//                appendPathsMeta(metaRow: firstMetaRow - 1, metaColumn: metaColumn, row: 0)
//            }
//            appendPathsMeta(metaRow: firstMetaRow, metaColumn: metaColumn, row: 0)
//            if firstMetaRow + 1 < metaRows {
//                appendPathsMeta(metaRow: firstMetaRow + 1, metaColumn: metaColumn, row: 0)
//            }
//        }
        
        let tableCount = metaRows*metaColumns
        
        for category in tensor.ordering {
            for value in 0..<tensor.size[category] {
                appendPath(tableCount + category, item: value)
            }
        }
        
        appendPath(tableCount + tensor.dimension, item: 0)
        appendPath(tableCount + tensor.dimension, item: 1)
        
        paths.forEach { path in
            cachedAttributes[path] = nil
        }
        
        let context = super.invalidationContextForBoundsChange(newBounds)
        context.invalidateItemsAtIndexPaths(paths)
        
        return context
    }
    
//    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
//        let x = CGFloat(Int(proposedContentOffset.x) % 60)
//        return proposedContentOffset
//    }
    
    // MARK: Pure helper functions
    
    func adjust(r: CGFloat, stopScroll: CGFloat, subtractAdd: CGFloat) -> CGFloat {
        return delay(r - subtractAdd, untilBelow: -stopScroll) + subtractAdd
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

func ease(from: CGFloat, to: CGFloat)(x: CGFloat) -> CGFloat {
    return ease(clamp((x - from)/(to - from)))
}

func ease(x: CGFloat) -> CGFloat {
    return x < 0.5 ? 4*pow(x, 3) : pow(2*x - 2, 3)/2 + 1
}

func clamp(x: CGFloat) -> CGFloat {
    if x < 0 {
        return 0
    }
    else if x > 1 {
        return 1
    }
    
    return x
}

