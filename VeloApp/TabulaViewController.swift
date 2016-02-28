//
//  TabulaViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

protocol LabeledCell {
    var label: UILabel! { get }
}

class IndexNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class FieldNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class CompFieldNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class IndexCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class Cell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class CompColumnCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class CompCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var label: UILabel!
}

enum CellType {
    case IndexName(column: Int)
    case FieldName(column: Int)
    case EmptyFieldName
    case CompFieldName(column: Int)
    case EmptyCompFieldName
    case Index(row: Int)
    case EmptyIndex
    case Cell(row: Int, column: Int)
    case EmptyCell
    case CompColumnCell(row: Int, column: Int)
    case EmptyCompColumnCell
    case CompCell(row: Int, column: Int)
    case EmptyCompCell
    case Spacer
    
    var id: String {
        switch self {
        case IndexName: return "IndexNameCell"
        case FieldName, EmptyFieldName: return "FieldNameCell"
        case CompFieldName, EmptyCompFieldName: return "CompFieldNameCell"
        case Index, EmptyIndex: return "IndexCell"
        case Cell, EmptyCell: return "Cell"
        case CompColumnCell, EmptyCompColumnCell: return "CompColumnCell"
        case CompCell, EmptyCompCell: return "CompCell"
        case Spacer: return "SpacerCell"
        }
    }
    
    var isEmpty: Bool {
        switch self {
        case EmptyFieldName, EmptyCompFieldName, EmptyIndex, EmptyCell, EmptyCompColumnCell, EmptyCompCell: return true
        default: return false
        }
    }
    
    init(config c: TableConfig, row: Int, column: Int) {
        switch (row, column) {
        case (c.headerRowRange, c.indexColumnRange): self = .IndexName(column: column)
        case (c.headerRowRange, c.columnsRange): self = .FieldName(column: column)
        case (c.headerRowRange, c.emptyColumnsRange): self = .EmptyFieldName
        case (c.headerRowRange, c.compColumnsRange): self = .CompFieldName(column: column - c.firstCompColumn)
        case (c.headerRowRange, c.emptyCompColumnsRange): self = .EmptyCompFieldName
            
        case (c.rowsRange, c.indexColumnRange): self = .Index(row: row - c.firstRow)
        case (c.rowsRange, c.columnsRange): self = .Cell(row: row - c.firstRow, column: column)
        case (c.rowsRange, c.emptyColumnsRange): self = .EmptyCell
        case (c.rowsRange, c.compColumnsRange): self = .CompColumnCell(row: row - c.firstRow, column: column - c.firstCompColumn)
        case (c.rowsRange, c.emptyCompColumnsRange): self = .EmptyCompColumnCell
            
        case (c.emptyRowsRange, c.indexColumnRange): self = .EmptyIndex
        case (c.emptyRowsRange, c.columnsRange): self = .EmptyCell
        case (c.emptyRowsRange, c.emptyColumnsRange): self = .EmptyCell
        case (c.emptyRowsRange, c.compColumnsRange): self = .EmptyCompColumnCell
        case (c.emptyRowsRange, c.emptyCompColumnsRange): self = .Spacer
            
        case (c.compRowsRange, c.indexColumnRange): self = .Spacer
        case (c.compRowsRange, c.columnsRange): self = .CompCell(row: row - c.firstCompRow, column: column)
        case (c.compRowsRange, c.emptyColumnsRange): self = .Spacer
        case (c.compRowsRange, c.compColumnsRange): self = .CompCell(row: row - c.firstCompRow, column: column - c.firstCompColumn)
        case (c.compRowsRange, c.emptyCompColumnsRange): self = .Spacer
            
        default: fatalError("Cell error")
        }
    }
}

struct TableConfig: CustomStringConvertible {
    let indexColumns = 1
    var columns = 1
    var emptyColumns = 1
    var compColumns = 2
    var emptyCompColumns = 1
    
    let headerRows = 1
    var rows = 1
    var emptyRows = 1
    var compRows = 2
    
    var totalRows: Int { return headerRows + rows + emptyRows + compRows }
    var totalColumns: Int { return indexColumns + columns + emptyColumns + compColumns + emptyCompColumns }
    var totalCells: Int { return totalRows*totalColumns }
    
    private var firstIndexColumn: Int { return 0 }
    private var firstColumn: Int { return firstIndexColumn + indexColumns }
    private var firstEmptyColumn: Int { return firstColumn + columns }
    private var firstCompColumn: Int { return firstEmptyColumn + emptyColumns}
    private var firstEmptyCompColumn: Int { return firstCompColumn + compColumns}
    
    private var firstHeaderRow: Int { return 0 }
    private var firstRow: Int { return firstHeaderRow + headerRows }
    private var firstEmptyRow: Int { return firstRow + rows }
    private var firstCompRow: Int { return firstEmptyRow + emptyRows}
    
    private func range(from: Int, length: Int) -> Range<Int> { return from..<(from + length) }
    
    private var indexColumnRange: Range<Int> { return range(firstIndexColumn, length: indexColumns) }
    private var columnsRange: Range<Int> { return range(firstColumn, length: columns) }
    private var emptyColumnsRange: Range<Int> { return range(firstEmptyColumn, length: emptyColumns) }
    private var compColumnsRange: Range<Int> { return range(firstCompColumn, length: compColumns) }
    private var emptyCompColumnsRange: Range<Int> { return range(firstEmptyCompColumn, length: emptyCompColumns) }
    
    private var headerRowRange: Range<Int> { return range(firstHeaderRow, length: headerRows) }
    private var rowsRange: Range<Int> { return range(firstRow, length: rows) }
    private var emptyRowsRange: Range<Int> { return range(firstEmptyRow, length: emptyRows) }
    private var compRowsRange: Range<Int> { return range(firstCompRow, length: compRows) }
    
    func isEmpty(row: Int, column: Int) -> Bool {
        return emptyColumnsRange.contains(column) || emptyCompColumnsRange.contains(column) || emptyRowsRange.contains(row)
    }

    func isHidden(row: Int, column: Int) -> Bool {
        return (emptyColumnsRange.contains(column) || emptyCompColumnsRange.contains(column)) && emptyRowsRange.contains(row)
    }

    var description: String {
        return " Columns: \(columns)\n EmptyColumns: \(emptyColumns)\n Rows: \(rows)\n EmptyRows: \(emptyRows)\n CompRows: \(compRows)" +
        "\n indexColumnRange: \(indexColumnRange)\n columnsRange: \(columnsRange)\n emptyColumnsRange: \(emptyColumnsRange)\n compColumnsRange: \(compColumnsRange)\n emptyCompColumnsRange: \(emptyCompColumnsRange)"
    }
}

class TabulaViewController: UICollectionViewController {
    var collectionId: String!
    var collectionIndex: [Int] = []
    
    private var layout: TableLayout { return collectionViewLayout as! TableLayout }
    
    private var name: String = "Table"
    private var header: [String] = ["Field0", "Field1"]
    private var categories: [[String]] = []
    private var rows: [[AnyObject]] = [["ndx0", "val0"]]
    
    func reload() {
        tableChanged()
        layoutChanged()
        
        collectionView?.reloadData()
    }
    
    private func tableChanged() {
        name = Engine.shared.getName(collectionId)
        header = Engine.shared.getHeader(collectionId)
        categories = Engine.shared.getCategories(collectionId)
        rows = Engine.shared.getRows(collectionId, index: collectionIndex)
        
        layout.config.columns = header.count - 1
        layout.config.rows = rows.count
    }
    
    private func layoutChanged() {
        layout.invalidateLayout()
    }
    
    // MARK: Collection View Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("## TotalCells: \(layout.config.totalCells)")
        return layout.config.totalCells
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let totalColumns = layout.config.totalColumns
        
        let row = indexPath.item / totalColumns
        let column = indexPath.item % totalColumns
        let cellType = CellType(config: layout.config, row: row, column: column)
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellType.id, forIndexPath: indexPath)
        
        print("Wants cell: \(row)\(column)")
        
        switch (cellType, cell) {
        case (let .IndexName(column: c), let cell as IndexNameCell):
            print("c: \(column)")
            cell.label.text = header[c]
        case (let .FieldName(column: c), let cell as FieldNameCell):
            print("c: \(column)")
            cell.label.text = header[c]
        case (let .CompFieldName(column: c), let cell as CompFieldNameCell):
            cell.label.text = ":\(c)"
            
        case (let .Index(row: r), let cell as IndexCell):
            cell.label.text = String(rows[r][0])
        case (let .Cell(row: r, column: c), let cell as Cell):
            //            cell.label.text = String(rowData[r][c])
            cell.label.text = "-"
        case (let .CompColumnCell(row: r, column: c), let cell as CompColumnCell):
            cell.label.text = "\(r):\(c)"

        case (let .CompCell(row: r, column: c), let cell as CompCell):
            cell.label.text = "\(r):\(c)"
            
        case (_, let cell as LabeledCell):
            cell.label.text = ""
        
        default: break
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let totalColumns = layout.config.totalColumns
        let row = indexPath.item / totalColumns
        let column = indexPath.item % totalColumns
        
        if layout.config.emptyColumnsRange.contains(column) {
            let newLayout = layout.duplicate
            newLayout.config.emptyColumns = 0
            newLayout.config.columns += 1
            collectionView.setCollectionViewLayout(newLayout, animated: true)
        }
    }
    
    // MARK: From containing View Controller
    
    func canvasScrolled(offset: CGFloat) {
        //        let stopWidth = addComputedColumnsWidth.constant + (computedColumns.frame.width == 0 ? mainStack.spacing : 0)
//        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - stopWidth)
    }
    
    
    // MARK: Setters
    
    private func changedSelected() {
        //        let newLayout = layout.duplicate
        //        newLayout.selected = selected
        //        collectionView!.setCollectionViewLayout(newLayout, animated: true)
    }
    
    private func pathsForRow(row: Int) -> [NSIndexPath] {
        let totalColumns = layout.config.totalColumns
        return (row*totalColumns..<(row + 1)*totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
    }
    
    private func pathsForColumn(column: Int) -> [NSIndexPath] {
        let totalColumns = layout.config.totalColumns
        let totalCells = layout.config.totalCells
        return column.stride(through: totalCells, by: totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
    }
    
    //    func addColumn(column: Int) {
    //        size.columns += 1
    //        layout.mainWidths = [CGFloat](count: size.columns, repeatedValue: 80)
    //        collectionView!.insertItemsAtIndexPaths(pathsForColumn(column))
    //    }
    //
    //    func deleteColumn(column: Int) {
    //        let paths = pathsForColumn(column)
    //        size.columns -= 1
    //        layout.mainWidths = [CGFloat](count: size.columns, repeatedValue: 80)
    //        collectionView!.deleteItemsAtIndexPaths(paths)
    //    }
    //
    //    func addRow(row: Int) {
    //        layout.size.rows += 1
    //        layout.rows = rowCount
    //        collectionView!.insertItemsAtIndexPaths(pathsForRow(row))
    //    }
    //
    //    func deleteRow(row: Int) {
    //        let paths = pathsForRow(row)
    //        rowCount -= 1
    //        layout.rows = rowCount
    //        collectionView!.deleteItemsAtIndexPaths(paths)
    //    }
}

func clamp<T: Comparable>(x: T, _ lower: T, _ upper: T) -> T {
    if x > lower && x < upper {
        return x
    }
    
    return min(max(x, lower), upper)
}

//struct ElementComputation {
//    let elementType: String
//    let inputFields: [String]
//    let computation: Computation
//
//    func apply(element: Object) -> AnyObject {
//        let values = inputFields.map { element[$0]! }
//
//        return computation.function(values)
//    }
//}

//struct Computation {
//    let signature: [String]
//    let function: [AnyObject] -> AnyObject
//}
//
//func dropIndex(headerRow: [String]) -> [String] {
//    return headerRow.filter { $0 != "id" }
//}
