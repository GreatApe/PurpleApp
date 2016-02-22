//
//  Table.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

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

class VeloTableViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var leftIndexColumnOffset: NSLayoutConstraint!
    
    @IBOutlet weak var coreHeaderRow: VeloView!
    @IBOutlet weak var computedHeaderRow: VeloView!
    
    @IBOutlet weak var leftIndexTableView: UITableView!
    @IBOutlet weak var coreTableView: UITableView!
    
    @IBOutlet weak var computedColumnsTableView: UITableView!
    @IBOutlet weak var addColumnTableView: UITableView!
    
    @IBOutlet weak var addComputedColumnsHeader: VeloView!
    @IBOutlet weak var addComputedColumns: VeloView!
    
    @IBOutlet weak var coreTableWidth: NSLayoutConstraint!
    @IBOutlet weak var computedColumnsWidth: NSLayoutConstraint!
    @IBOutlet weak var addComputedColumnsWidth: NSLayoutConstraint!
    
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var computedColumns: UIStackView!
    
    @IBOutlet weak var coreTableHeight: NSLayoutConstraint!
    
    private let leftIndexDataSource = IndexDataSource()
    private let coreTableDataSource = CoreDataSource()
    private let addColumnDataSource = AddColumnDataSource()
    private let computedColumnsDataSource = ComputedColumnsDataSource()
    
    var tableId: String!
    
    // temp
    let cellWidth: CGFloat = 120
    let addComputedColumnsButtonWidth: CGFloat = 70
    var showAddComputedColumns = true
    
    func reloadAll() {
        reloadIndex()
        reloadCore()
        reloadAddColumn()
        reloadComputed()
    }
    
    private func reloadIndex() {
        leftIndexTableView.reloadData()
    }
    
    private func reloadCore() {
        coreTableWidth.constant = CGFloat(Engine.shared.tableHeader(tableId).count)*cellWidth
        coreTableHeight.constant = min(CGFloat(Engine.shared.tableRowCount(tableId))*44, 600)
        
        view.layoutIfNeeded()
        coreHeaderRow.setupFields(Engine.shared.tableHeader(tableId))
        
        coreTableView.reloadData()
    }
    
    private func reloadAddColumn() {
        addColumnTableView.reloadData()
    }
    
    private func reloadComputed() {
        computedColumnsWidth.constant = CGFloat(computedColumnsDataSource.columns)*cellWidth
        addComputedColumnsWidth.constant = showAddComputedColumns ? addComputedColumnsButtonWidth : 0

        view.layoutIfNeeded()
        
        let columns = computedColumnsDataSource.columns
        computedHeaderRow.setupFields((0..<columns).map{ "f" + String($0) })
        
        if columns > 0 {
            computedColumnsTableView.reloadData()
        }
        
        addComputedColumns.setupFields(["f"])
        addComputedColumnsHeader.setupFields(["+"])
    }
    
//    func arrangeComputed() {
//        computedColumnsWidth.constant = computedWidth()
//        addComputedColumnsWidth.constant = addComputedWidth()
//        
//        computedHeaderRow.arrange()
//        for row in 0..<computedColumnsTableView.numberOfRowsInSection(0) {
//            let indexPath = NSIndexPath(forRow: row, inSection: 0)
//            (computedColumnsTableView.cellForRowAtIndexPath(indexPath) as! VeloRow).arrange()
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftIndexTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        leftIndexDataSource.tableId = tableId
        leftIndexTableView.dataSource = leftIndexDataSource
        
        coreHeaderRow.color = UIColor.coreHeaderCell()
        coreTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        coreTableDataSource.tableId = tableId
        coreTableView.dataSource = coreTableDataSource
        
        addColumnTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        addColumnDataSource.tableId = tableId
        addColumnTableView.dataSource = addColumnDataSource

        computedHeaderRow.color = UIColor.computedHeaderCell()
        computedColumnsTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        computedColumnsDataSource.tableId = tableId
        
//        let valueCompDiff = Computation(signature: ["Double", "Double"]) { values in
//            return (values[0] as! Double) - (values[1] as! Double)
//        }
//
//        let valueCompSum = Computation(signature: ["Double", "Double"]) { values in
//            return (values[0] as! Double) + (values[1] as! Double)
//        }
//
//        let inputFields = ["d1", "d0"]
//        
//        let comp1 = ElementComputation(elementType: table.objectType, inputFields: inputFields, computation: valueCompDiff)
//        let comp2 = ElementComputation(elementType: table.objectType, inputFields: inputFields, computation: valueCompSum)
//        
//        computedColumnsDataSource.computations = [comp1, comp2]
        computedColumnsTableView.dataSource = computedColumnsDataSource
        
//        computedHeaderRow.setupFields(["diff", "sum"])
        
        addComputedColumns.color = UIColor.computedCell()
        addComputedColumnsHeader.color = UIColor.computedHeaderCell()
    }
    
    private var didLayoutOnce = false
    
    override func viewDidLayoutSubviews() {
        if didLayoutOnce { return }
        didLayoutOnce = true
        
        reloadAll()
    }

    // MARK: From containing View Controller

    func canvasScrolled(offset: CGFloat) {
        let stopWidth = addComputedColumnsWidth.constant + (computedColumns.frame.width == 0 ? mainStack.spacing : 0)
        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - stopWidth)
    }
    
    // MARK: UITableViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        leftIndexTableView.contentOffset = scrollView.contentOffset
        coreTableView.contentOffset = scrollView.contentOffset
        computedColumnsTableView.contentOffset = scrollView.contentOffset
    }
    
    // MARK: User Actions
    
    @IBAction func tableNameChanged(sender: UITextField) {
        sender.invalidateIntrinsicContentSize()
    }
    
    @IBAction func tappedButton() {
        Engine.shared.addProperty(.Double, toTable: tableId)
        reloadCore()
    }
    
    @IBAction func tappedOtherButton() {
        computedColumnsDataSource.columns = (computedColumnsDataSource.columns + 1) % 4
        reloadComputed()
    }
    
    @IBAction func tappedThirdButton() {
        showAddComputedColumns = !showAddComputedColumns
        reloadComputed()
    }
    
    @IBAction func tappedFourthButton() {
        Engine.shared.addRandomRowToTable(tableId)
        reloadAll()
    }
}



