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

class ComputedFieldNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class IndexCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class Cell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class ComputedCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var label: UILabel!
}

class ComputedColumnCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

enum CellType: String {
    case TableName = "TableName"
    case FieldName = "FieldName"
    case ComputedFieldName = "ComputedFieldName"
    case RowIndex = "RowIndex"
    case Cell = "Cell"
    case NewCell = "NewCell"
    case ComputedColumnCell = "ComputedColumnCell"
    case NewComputedCell = "NewComputedCell"
    case ComputedCell = "ComputedCell"
    case Spacer = "Spacer"
}

class TabulaViewController: UICollectionViewController {
    var tableId: String! { didSet { reload() } }
    var selected = true { didSet { changedSelected() } }
    
    private var columnCount = 1
    private var emptyColumns = 0
    private var computedColumnCount = 0
    
    private var rowCount = 1
    private var emptyRows = 0
    private var computedRowCount = 0
    
    private var layout: TableLayout { return collectionViewLayout as! TableLayout }

    // MARK: Setters
    
    private func changedSelected() {
        let newLayout = layout.duplicate
        newLayout.selected = selected
        collectionView!.setCollectionViewLayout(newLayout, animated: true)
    }
    
    private func pathsForRow(row: Int) -> [NSIndexPath] {
        let totalColumns = 1 + columnCount + 1 + computedColumnCount + 1
        return (row*totalColumns..<(row + 1)*totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
    }
    
    private func pathsForColumn(column: Int) -> [NSIndexPath] {
        let totalColumns = 1 + columnCount + 1 + computedColumnCount + 1
        return column.stride(through: totalCells, by: totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
    }
    
    func addColumn(column: Int) {
        columnCount += 1
        layout.mainWidths = [CGFloat](count: columnCount, repeatedValue: 80) + [44]
        collectionView!.insertItemsAtIndexPaths(pathsForColumn(column))
    }
    
    func deleteColumn(column: Int) {
        let paths = pathsForColumn(column)
        columnCount -= 1
        layout.mainWidths = [CGFloat](count: columnCount, repeatedValue: 80) + [44]
        collectionView!.deleteItemsAtIndexPaths(paths)
    }

    func addRow(row: Int) {
        rowCount += 1
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
        layout.computedWidths = [CGFloat](count: computedColumnCount, repeatedValue: 60) + [44]
        layout.rows = rowCount
        layout.computedRows = computedRowCount
        layout.invalidateLayout()
    }
    
    // MARK: Collection View Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    private var totalCells: Int {
        let totalColumns = 1 + columnCount + 1 + computedColumnCount + 1
        let totalRows = 1 + rowCount + 1 + computedRowCount
        
        return totalColumns*totalRows
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalCells
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let totalColumns = 1 + columnCount + 1 + computedColumnCount + 1
        let row = indexPath.item / totalColumns
        let column = indexPath.item % totalColumns
        
        let indexColumn = 0
        let mainColumns = 1..<1 + columnCount
        let addColumn = 1 + columnCount
        let computedColumns = addColumn + 1..<addColumn + 1 + computedColumnCount
        let addComputedColumn = computedColumns.last ?? addColumn + 1
        
        let headerRow = 0
        let mainRows = 1..<1 + rowCount
        let addRow = mainRows.last! + 1
        let computedRows = addRow + 1..<addRow + 1 + computedRowCount
        
        let cellType: CellType
        let text: String?
        
        switch (row, column) {
        case (headerRow, indexColumn):
            cellType = .TableName
            text = name
        case (headerRow, mainColumns):
            cellType = .FieldName
            text = headerData[column - 1]
        case (headerRow, computedColumns):
            cellType = .ComputedFieldName
            text = "Fx"
        case (mainRows, indexColumn):
            cellType = .RowIndex
            text = (rowData[row - 1][indexColumn] as! String)
        case (mainRows, mainColumns):
            cellType = .Cell
            text = String(rowData[row - 1][column])
        case (mainRows, computedColumns):
            cellType = .ComputedColumnCell
            text = "xx"
        case (mainRows, addComputedColumn):
            cellType = .NewComputedCell
            text = nil
        case (mainRows, addColumn), (addRow, indexColumn), (addRow, mainColumns):
            cellType = .NewCell
            text = nil
        case (computedRows, mainColumns), (computedRows, computedColumns):
            cellType = .ComputedCell
            text = "yy"
        default:
            cellType = .Spacer
            text = nil
        }
        
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
