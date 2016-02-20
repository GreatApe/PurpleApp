//
//  VeloTableViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit
import Realm

class VeloCanvasViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var canvas: UIScrollView!
    
    private var veloTables = [VeloTableViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        canvas.contentSize = CGSize(width: 2000, height: 2000)
    }

    // MARK: User actions
    
    @IBAction func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            newTable(sender.locationInView(canvas))
        }
    }

    func newTable(point: CGPoint) {
        if let tvc = storyboard?.instantiateViewControllerWithIdentifier("VeloTable") as? VeloTableViewController {
            let tableId = Engine.shared.makeTable()
            Engine.shared.addProperty(.Double, toTable: tableId)
            Engine.shared.addRandomRowToTable(tableId)
            
            tvc.tableId = tableId
            let size = CGSize(width: 500, height: 300)
            tvc.view.frame.size = size
            
            let container = UIView(frame: CGRect(origin: point, size: size))
            canvas.addSubview(container)
            tvc.willMoveToParentViewController(self)
            container.addSubview(tvc.view)
            addChildViewController(tvc)
            tvc.didMoveToParentViewController(self)
            
            veloTables.append(tvc)
        }
    }
    
    @IBAction func tappedButton() {
//        Engine.shared.addProperty(.Double, to: "XXX")
//        Engine.shared.describe()
        
        veloTables.forEach { $0.reloadAll() }
    }
    
    @IBAction func tappedOtherButton() {
        Engine.shared.describe()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        for veloTable in veloTables {
            if let tableContainer = veloTable.view.superview {
                veloTable.canvasScrolled(scrollView.contentOffset.x - tableContainer.frame.minX)
            }
        }
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

class VeloTableViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var leftIndexColumnOffset: NSLayoutConstraint!
    
    @IBOutlet weak var coreHeaderRow: VeloView!
    @IBOutlet weak var computedHeaderRow: VeloView!
    
    @IBOutlet weak var leftIndexTableView: UITableView!
    @IBOutlet weak var coreTableView: UITableView!
    @IBOutlet weak var computedColumnsTableView: UITableView!
    @IBOutlet weak var addComputedColumns: UIStackView!

    @IBOutlet weak var computedColumnsWidth: NSLayoutConstraint!

    @IBOutlet weak var addComputedColumnsWidth: NSLayoutConstraint!
    
    @IBOutlet weak var mainStack: UIStackView!
    @IBOutlet weak var computedColumns: UIStackView!
    
    private let leftIndexDataSource = IndexDataSource()
    private let coreTableDataSource = CoreDataSource()
    private let computedColumnsDataSource = ComputedColumnsDataSource()
    
    var tableId: String!
    
    // temp
    let cellWidth: CGFloat = 120
    let addComputedColumnsButtonWidth: CGFloat = 70
    var showAddComputedColumns = true

    var intrinsicSize: CGSize {
        let margin = mainStack.spacing
        let coreWidth = CGFloat(Engine.shared.tableHeader(tableId).count)*cellWidth
        let width = leftIndexTableView.frame.width + coreWidth + computedWidth() + addComputedWidth() + 2*margin
        
        return CGSize(width: width, height: 500)
    }
    
    private func computedWidth() -> CGFloat {
        return CGFloat(computedColumnsDataSource.columns)*cellWidth
    }

    private func addComputedWidth() -> CGFloat {
        return showAddComputedColumns ? addComputedColumnsButtonWidth : 0
    }
    
    func reloadAll() {
        view.frame.size.width = intrinsicSize.width

        reloadIndex()
        reloadCore()
        reloadComputed()
    }

    private func reloadIndex() {
        leftIndexTableView.reloadData()
    }
    
    private func reloadCore() {
        mainStack.layoutIfNeeded()
        coreHeaderRow.setupFields(Engine.shared.tableHeader(tableId))
        
        coreTableView.reloadData()
    }
    
    private func reloadComputed() {
        computedColumnsWidth.constant = computedWidth()
        addComputedColumnsWidth.constant = addComputedWidth()

        computedColumns.layoutIfNeeded()
        addComputedColumns.layoutIfNeeded()
        
        let columns = computedColumnsDataSource.columns
        computedHeaderRow.setupFields((0..<columns).map{ "f" + String($0) })
        
        if columns > 0 {
            computedColumnsTableView.reloadData()
        }
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
        
        reloadAll()
    }

    // MARK: From containing View Controller

    func canvasScrolled(offset: CGFloat) {
        let stopWidth = addComputedColumnsWidth.constant + mainStack.spacing
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

        view.frame.size.width = intrinsicSize.width
        reloadCore()
    }
    
    @IBAction func tappedOtherButton() {
        computedColumnsDataSource.columns = (computedColumnsDataSource.columns + 1) % 4
        
        view.frame.size.width = intrinsicSize.width
        reloadComputed()
    }
    
    @IBAction func tappedThirdButton() {
        showAddComputedColumns = !showAddComputedColumns
        view.frame.size.width = intrinsicSize.width
        reloadComputed()
    }
}



