//
//  TabulaViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TabulaViewController: UICollectionViewController {
    var tableId: String!
    
    var selected = true { didSet { changedSelected() } }
    
    private var columnCount = 4
    private var computedColumnCount = 2
    private var rowCount = 5
    private var computedRowCount = 2

    private var layout: TableLayout { return collectionViewLayout as! TableLayout }
    
    // MARK: Setters
    
    private func changedSelected() {
        let newLayout = layout.duplicate
        newLayout.selected = selected
        collectionView!.setCollectionViewLayout(newLayout, animated: true)
    }
    
    func addColumn() {
        columnCount += 1
        let newLayout = layout.duplicate
        layout.mainWidths = [CGFloat](count: columnCount, repeatedValue: 80) + [44]
        collectionView!.setCollectionViewLayout(newLayout, animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        updateLayout()
    }
    
    private func updateLayout() {
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
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let totalColumns = 1 + columnCount + 1 + computedColumnCount + 1
        let row = indexPath.item / totalColumns
        let column = indexPath.item % totalColumns
        
        let indexColumn = 0
        let mainColumns = 1..<1 + columnCount
        let addColumn = 1 + columnCount
        let computedColumns = addColumn + 1..<addColumn + 1 + computedColumnCount
        let addComputedColumn = computedColumns.last! + 1
        
        let headerRow = 0
        let mainRows = 1..<1 + rowCount
        let addRow = mainRows.last! + 1
        let computedRows = addRow + 1..<addRow + 1 + computedRowCount
        
        let cellId: String
        
        switch (row, column) {
        case (headerRow, indexColumn): cellId = "TableName"
        case (headerRow, mainColumns): cellId = "FieldName"
        case (headerRow, addColumn): cellId = "Spacer"
        case (headerRow, computedColumns): cellId = "ComputedFieldName"
        case (headerRow, addComputedColumn): cellId = "Spacer"
            
        case (mainRows, indexColumn): cellId = "RowIndex"
        case (mainRows, mainColumns): cellId = "Cell"
        case (mainRows, addColumn): cellId = "NewCell"
        case (mainRows, computedColumns): cellId = "ComputedCell"
        case (mainRows, addComputedColumn): cellId = "NewComputedCell"
            
        case (addRow, indexColumn): cellId = "NewCell"
        case (addRow, mainColumns): cellId = "NewCell"
        case (addRow, addColumn): cellId = "Spacer"
        case (addRow, computedColumns): cellId = "Spacer"
        case (addRow, addComputedColumn): cellId = "Spacer"
            
        case (computedRows, indexColumn): cellId = "Spacer"
        case (computedRows, mainColumns): cellId = "ComputedCell"
        case (computedRows, addColumn): cellId = "Spacer"
        case (computedRows, computedColumns): cellId = "ComputedCell"
        case (computedRows, addComputedColumn): cellId = "Spacer"

        default: cellId = "Spacer"
            
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellId, forIndexPath: indexPath)
        return cell
    }
    
    // MARK: From containing View Controller
    
    func canvasScrolled(offset: CGFloat) {
//        let stopWidth = addComputedColumnsWidth.constant + (computedColumns.frame.width == 0 ? mainStack.spacing : 0)
//        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - stopWidth)
    }
}