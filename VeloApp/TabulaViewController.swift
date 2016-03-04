//
//  TabulaViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit
import Realm

class TabulaViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var menuBar: MenuBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionId: String! { didSet { didSetCollectionId() } }
    
    private var layout: TableLayout { return collectionView.collectionViewLayout as! TableLayout }
    
    private var name: String = "Table"
    private var header: [String] = ["Field0", "Field1"]
    private var categories: [Cat] = []
    
    private var fullScreen = true
    
    override func viewDidLayoutSubviews() {
    }
    
    override func viewDidLoad() {
        view.addSubview(menuBar)
    }
    
//    func updateContainer() {
//        guard let container = view.superview, contentSize = layout.contentSize else { return }
//        
//        container.frame.size = contentSize
//        view.frame.size = contentSize
//    }
    
    private func didSetCollectionId() {
        let rowCounts: [Int]
        (name, header, categories, rowCounts) = Engine.shared.getMetaData(collectionId)
        
        nameLabel.text = name
        categories.enumerate().forEach(setupCategory)
        
        let size = categories.map { $0.values.count }
        let config = TableConfig(columns: header.count - 1)
    
        layout.update(size, tableConfig: config, rowCounts: rowCounts)

        collectionView.reloadData()
        layout.updateScrollOffset(collectionView.contentOffset)
    }
    
    private func setupCategory(index: Int, cat: Cat) {
        let size = CGSize(width: 100, height: 40)
        let pos = CGPoint(x: CGFloat(index)*size.width, y: 0)
        
        let catItem: DropDown.Item = (cat.name, nil, false)
        let expandItem: DropDown.Item = ("Show all", nil, false)
        let valueItems: [DropDown.Item] = cat.values.map { ($0, nil, true) }
        let items = [catItem, expandItem] + valueItems
        
        let action: (DropDown, Int) -> Bool = { [unowned self] dropDown, i in
            switch i {
            case 0: return false
            case 1:
                dropDown.hide(1)
                dropDown.selection = nil
                self.free(dropDown.tag)
                return false
            default:
                dropDown.show(1)
                self.fix(dropDown.tag, atValue: i - 2)
                return true
            }
        }
        let dropDown = DropDown(frame: CGRect(origin: pos, size: size), items: items, shouldSelectAction: action)
        dropDown.selection = 2
        menuBar.addDropDown(dropDown)
    }

    private func free(dimension: Int) {
        if layout.tensor.ordering.count == 2 {
            let freeDimension = layout.tensor.ordering[0]
            layout.tensor.fix(freeDimension, at: 0)
            menuBar.dropDowns[freeDimension].show(1)
            menuBar.dropDowns[freeDimension].selection = 2
        }
        layout.tensor.free(dimension)
        collectionView.reloadData()
    }
    
    private func fix(dimension: Int, atValue value: Int) {
        layout.tensor.fix(dimension, at: value)
        collectionView.reloadData()
    }

    // MARK: Collection View Data Source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return layout.metaRows*layout.metaColumns + layout.tensor.dimension + 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let tableCount = layout.metaRows*layout.metaColumns
        
        switch section {
        case 0..<tableCount: return layout.tableConfig.totalColumns*layout.rowConfigs[section |> layout.tensor.unslice].totalRows
        case tableCount..<tableCount + layout.tensor.dimension: return layout.tensor.size[section - tableCount]
        case tableCount + layout.tensor.dimension: return 2
        default: fatalError()
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let tableCount = layout.metaRows*layout.metaColumns
        let cellType: CellType
        
        switch indexPath.section {
        case 0..<tableCount:
            let index = indexPath.section |> layout.tensor.sliced.vectorise |> layout.tensor.unslice

            let totalColumns = layout.tableConfig.totalColumns
            let rowConfig = layout.rowConfigs[index |> layout.tensor.linearise]
            
            let row = indexPath.item / totalColumns
            let column = indexPath.item % totalColumns
            cellType = CellType(rowConfig: rowConfig, tableConfig: layout.tableConfig, index: index, row: row, column: column)
            
        case tableCount..<tableCount + layout.tensor.dimension:
            cellType = .CategoryValue(category: indexPath.section - tableCount, value: indexPath.item)
            
        case tableCount + layout.tensor.dimension:
            cellType = .Mask
            
        default: fatalError()
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellType.id, forIndexPath: indexPath)
        
        guard let labeledCell = cell as? LabeledCell else {
            return cell
        }
        
        let text: String?
        
        switch cellType {
        case let .CategoryValue(category: c, value: v): text = categories[c].values[v]
        case let .IndexName(column: c): text = header[c]
        case let .FieldName(column: c): text = header[c]
        case let .CompFieldName(column: c): text = "c: \(c)"
        case let .Index(index: i, row: r):
            guard let id = collectionId else { text = nil; break }
            text = String(Engine.shared.getData(id, index: i, row: r, column: 0))
        case let .Cell(index: i, row: r, column: c):
            guard let id = collectionId else { text = nil; break }
            text = String(Engine.shared.getData(id, index: i, row: r, column: c))
        case let .CompColumnCell(index: i, row: r, column: c): text = "\(i):\(r):\(c)"
        case let .CompCell(index: i, row: r, column: c): text = "\(i):\(r):\(c)"
        default: text = nil
        }
        
        labeledCell.label.text = text
        
        return cell
    }
    
    func toggle(dimension: Int) {
        if layout.tensor.isFree(dimension) {
            layout.tensor.fix(dimension, at: 0)
        }
        else {
            if layout.tensor.ordering.count == 2 {
                layout.tensor.fix(layout.tensor.ordering[0], at: 0)
            }
            layout.tensor.free(dimension)
        }
        
        print("Tensor: \(layout.tensor)")
        
        collectionView.reloadData()
    }
}

    //    func cellData(table: Int, row: Int, column: Int) -> String {
    ////        if let collection = collection {
    //////            collection |> getTable(table) |> getRows
    ////        }
    //    }
    //        print("\(indexPath.section).\(indexPath.item):\(row).\(column) = cellType:\(cellType)")
    

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
