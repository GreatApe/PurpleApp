//
//  TabulaViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TabulaViewController: UICollectionViewController {
    var collectionId: String! { didSet { collectionIdChanged() } }
    var collectionIndex: [Int] = []
    
    private var layout: TableLayout { return collectionViewLayout as! TableLayout }
    
    private var name: String = "Table"
    private var header: [String] = ["Field0", "Field1"]
    private var categories: [[String]] = []
    private var rows: [[AnyObject]] = [["ndx0", "val0"]]
    
    override func viewDidLoad() {
        var cs = [RowConfig]()
        for _ in 0..<12 {
            var c = RowConfig()
            c.rows = 2 + Int(rand() % 5)
            cs.append(c)
        }

        layout.rowConfigs = cs
    }
    
    func reload() {
        collectionView?.reloadData()
    }
    
    private func collectionIdChanged() {
        (name, header, categories) = Engine.shared.getCollectionData(collectionId)
        
        print("Header: \(header)")

        collectionIndex = Array(count: categories.count, repeatedValue: 0)
        
//        layout.config.columns = header.count - 1
//        layout.config.rows = rows.count
    }
    
    // MARK: Collection View Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return layout.metaRows*layout.metaColumns
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return layout.columnConfig.totalColumns*layout.rowConfigs[section].totalRows
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let totalColumns = layout.columnConfig.totalColumns
        let rowConfig = layout.rowConfigs[indexPath.section]
        
        let row = indexPath.item / totalColumns
        let column = indexPath.item % totalColumns
        let cellType = CellType(rowConfig: rowConfig, columnConfig: layout.columnConfig, row: row, column: column)
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellType.id, forIndexPath: indexPath)
        
//        print("\(indexPath.section).\(indexPath.item):\(row).\(column) = cellType:\(cellType)")
        
//        print("Wants cell: \(row)\(column)")
        
        switch (cellType, cell) {
        case (let .IndexName(column: c), let cell as IndexNameCell):
//            cell.label.text = header[c]
            cell.label.text = "c: \(c)"
        case (let .FieldName(column: c), let cell as FieldNameCell):
//            cell.label.text = header[c]
            cell.label.text = "c: \(c)"
        case (let .CompFieldName(column: c), let cell as CompFieldNameCell):
            cell.label.text = "c: \(c)"
            
        case (let .Index(row: r), let cell as IndexCell):
//            cell.label.text = String(rows[r][0])
            cell.label.text = "r: \(r)"

        case (let .Cell(row: r, column: c), let cell as Cell):
//            cell.label.text = String(rows[r][c])
            cell.label.text = "\(r):\(c)"
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
    
//    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        let totalColumns = layout.config.totalColumns
//        let row = indexPath.item / totalColumns
//        let column = indexPath.item % totalColumns
//        
//        if layout.config.emptyColumnsRange.contains(column) {
//            let newLayout = layout.duplicate
//            newLayout.config.emptyColumns = 0
//            newLayout.config.columns += 1
//            collectionView.setCollectionViewLayout(newLayout, animated: true)
//        }
//    }
    
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
    
//    private func pathsForRow(row: Int) -> [NSIndexPath] {
//        let totalColumns = layout.config.totalColumns
//        return (row*totalColumns..<(row + 1)*totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
//    }
//    
//    private func pathsForColumn(column: Int) -> [NSIndexPath] {
//        let totalColumns = layout.config.totalColumns
//        let totalCells = layout.config.totalCells
//        return column.stride(through: totalCells, by: totalColumns).map { NSIndexPath(forItem: $0, inSection: 0) }
//    }
    
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
