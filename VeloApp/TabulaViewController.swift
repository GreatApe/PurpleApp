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

class TableNameCell: UICollectionViewCell, LabeledCell {
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

class CompCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var label: UILabel!
}

class CompColumnCell: UICollectionViewCell, LabeledCell {
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
        case IndexName: return "IndexName"
        case FieldName: return "FieldName"
        case EmptyFieldName: return "FieldName"
        case CompFieldName, EmptyCompFieldName: return "ComputedFieldName"
        case Index, EmptyIndex: return "Index"
        case Cell, EmptyCell: return "Cell"
        case CompColumnCell, EmptyCompColumnCell: return "ComputedColumnCell"
        case CompCell, EmptyCompCell: return "CompCell"
        case Spacer: return "Spacer"
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
        case (c.rowsRange, c.emptyColumnsRange): self = .Cell(row: row - c.firstRow, column: column)
        case (c.rowsRange, c.compColumnsRange): self = .CompColumnCell(row: row - c.firstRow, column: column - c.firstCompColumn)
        case (c.rowsRange, c.emptyCompColumnsRange): self = .EmptyCompColumnCell
            
        case (c.emptyRowsRange, c.indexColumnRange): self = .EmptyIndex
        case (c.emptyRowsRange, c.columnsRange): self = .EmptyCell
        case (c.emptyRowsRange, c.emptyColumnsRange): self = .Spacer
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

struct TableConfig {
    let indexColumns = 1
    var columns = 3
    var emptyColumns = 1
    var compColumns = 2
    var emptyCompColumns = 1
    
    let headerRows = 1
    var rows = 3
    var emptyRows = 1
    var compRows = 2
    
    var totalRows: Int { return headerRows + rows + emptyRows + compRows }
    var totalColumns: Int { return indexColumns + columns + emptyColumns + compColumns + emptyCompColumns }
    var totalCells: Int { return totalRows*totalColumns }
    
    func cellType(row: Int, column: Int) -> CellType {
        switch (row, column) {
        case (headerRowRange, indexColumnRange): return .IndexName(column: column)
        case (headerRowRange, columnsRange): return .FieldName(column: column)
        case (headerRowRange, emptyColumnsRange): return .EmptyFieldName
        case (headerRowRange, compColumnsRange): return .CompFieldName(column: column - firstCompColumn)
        case (headerRowRange, emptyCompColumnsRange): return .EmptyCompFieldName
            
        case (rowsRange, indexColumnRange): return .Index(row: row - firstRow)
        case (rowsRange, columnsRange): return .Cell(row: row - firstRow, column: column)
        case (rowsRange, emptyColumnsRange): return .Cell(row: row - firstRow, column: column)
        case (rowsRange, compColumnsRange): return .CompColumnCell(row: row - firstRow, column: column - firstCompColumn)
        case (rowsRange, emptyCompColumnsRange): return .EmptyCompColumnCell
            
        case (emptyRowsRange, indexColumnRange): return .EmptyIndex
        case (emptyRowsRange, columnsRange): return .EmptyCell
        case (emptyRowsRange, emptyColumnsRange): return .Spacer
        case (emptyRowsRange, compColumnsRange): return .EmptyCompColumnCell
        case (emptyRowsRange, emptyCompColumnsRange): return .Spacer
            
        case (compRowsRange, indexColumnRange): return .Spacer
        case (compRowsRange, columnsRange): return .CompCell(row: row - firstCompRow, column: column)
        case (compRowsRange, emptyColumnsRange): return .Spacer
        case (compRowsRange, compColumnsRange): return .CompCell(row: row - firstCompRow, column: column - firstCompColumn)
        case (compRowsRange, emptyCompColumnsRange): return .Spacer
            
        default: fatalError("Cell error")
        }
    }
    
    private var firstIndexColumn: Int { return 0 }
    private var firstColumn: Int { return firstIndexColumn + indexColumns }
    private var firstEmptyColumn: Int { return firstColumn + columns }
    private var firstCompColumn: Int { return firstEmptyColumn + emptyColumns}
    private var firstEmptyCompColumn: Int { return firstCompColumn + emptyCompColumns}
    
    private var firstHeaderRow: Int { return 0 }
    private var firstRow: Int { return firstHeaderRow + headerRows }
    private var firstEmptyRow: Int { return firstRow + rows }
    private var firstCompRow: Int { return firstEmptyColumn + emptyColumns}
    
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
}

class TabulaViewController: UICollectionViewController {
    var tableId: String! { didSet { reload() } }
//    var selected = true { didSet { changedSelected() } }
    
    private var layout: TableLayout { return collectionViewLayout as! TableLayout }

    // MARK: Setters
    
    private func changedSelected() {
        let newLayout = layout.duplicate
        newLayout.selected = selected
        collectionView!.setCollectionViewLayout(newLayout, animated: true)
    }
    
    private func pathsForRow(row: Int) -> [NSIndexPath] {
        let totalColumns = size.totalColumns
        return (row*totalColumns..<(row + 1)*size.totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
    }
    
    private func pathsForColumn(column: Int) -> [NSIndexPath] {
        let totalColumns = size.totalColumns
        return column.stride(through: size.totalCells, by: totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
    }
    
    func addColumn(column: Int) {
        size.columns += 1
        layout.mainWidths = [CGFloat](count: size.columns, repeatedValue: 80)
        collectionView!.insertItemsAtIndexPaths(pathsForColumn(column))
    }
    
    func deleteColumn(column: Int) {
        let paths = pathsForColumn(column)
        size.columns -= 1
        layout.mainWidths = [CGFloat](count: size.columns, repeatedValue: 80)
        collectionView!.deleteItemsAtIndexPaths(paths)
    }

    func addRow(row: Int) {
        layout.size.rows += 1
        layout.rows = rowCount
        collectionView!.insertItemsAtIndexPaths(pathsForRow(row))
    }

    func deleteRow(row: Int) {
        let paths = pathsForRow(row)
        rowCount -= 1
        layout.rows = rowCount
        collectionView!.deleteItemsAtIndexPaths(paths)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        layoutChanged()
    }
    
    private var name = "Table"
    private var headerData = ["Field0"]
    private var rowData: [[AnyObject]] = [["ndx0", "val0"]]
    
    func reload() {
        tableChanged()
        layoutChanged()
        
        print("Reload:")
        print(name)
        print(headerData)
        print(columnCount)
        print(rowCount)
        print(rowData)
        
        collectionView?.reloadData()
    }
    
    private func tableChanged() {
        name = Engine.shared.tableName(tableId)
        
        headerData = Engine.shared.tableHeader(tableId)
        columnCount = headerData.count
        
        rowData = Engine.shared.tableRows(tableId)
        rowCount = rowData.count
    }
    
    private func layoutChanged() {
        layout.selected = selected
        layout.indexWidth = 100
        layout.mainWidths = [CGFloat](count: columnCount, repeatedValue: 80) + [44]
        layout.compWidths = [CGFloat](count: compColumnCount, repeatedValue: 60) + [44]
        layout.rows = rowCount
        layout.compRows = compRowCount
        layout.invalidateLayout()
    }
    
    // MARK: Collection View Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return config.totalCells
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let row = indexPath.item / config.totalColumns
        let column = indexPath.item % config.totalColumns
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellType.rawValue, forIndexPath: indexPath)
        
        if let cell = cell as? LabeledCell, text = text {
            cell.label.text = text
        }
        
        //            case .RowIndex: text = String(rowData[row - 1][column])
        //            case .Cell: text = String(rowData[row - 1][column - 1])
        
        return cell
    }
    
    // MARK: From containing View Controller
    
    func canvasScrolled(offset: CGFloat) {
        //        let stopWidth = addComputedColumnsWidth.constant + (computedColumns.frame.width == 0 ? mainStack.spacing : 0)
//        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - stopWidth)
    }
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
