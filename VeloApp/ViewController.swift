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
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
//        Engine.shared.newTableClass("XXX")
        
//        Engine.shared.createRandomTable("TableXXX", name: "xyz")

//        Engine.shared.describe()

//        Engine.shared.addProperty(.Double, to: "TableBase")
        Engine.shared.addProperty(.Double, to: "RowBase")
//
        Engine.shared.describe()

        Engine.shared.createRandomTable("TableBase", name: "xyz")

//        Engine.shared.createRandomTable("TableXXX", name: "xyz")

        Engine.shared.describe()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    var veloTables = [VeloTableViewController]()
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let veloTable = segue.destinationViewController as? VeloTableViewController {
            veloTables.append(veloTable)
            
            veloTable.tableClassName = "TableBase"
            veloTable.tableId = "xyz"
        }
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
    
    let leftIndexDataSource = IndexDataSource()
    let coreTableDataSource = CoreDataSource()
    let computedColumnsDataSource = ComputedColumnsDataSource()
    
    var tableId: String!
    var tableClassName: String!
    
    var table: RLMObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table = Engine.shared.table(tableClassName, id: tableId)
        
        coreHeaderRow.setupFields(Engine.shared.tableHeader(table))
        
        leftIndexTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        leftIndexDataSource.data = table["rows"] as! RLMArray
        leftIndexTableView.dataSource = leftIndexDataSource
        
        coreTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        coreTableDataSource.data = table["rows"] as! RLMArray
        coreTableView.dataSource = coreTableDataSource

        computedColumnsTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        computedColumnsDataSource.data = table["rows"] as! RLMArray
        
        
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
        
        computedHeaderRow.setupFields(["diff", "sum"])
    }

    // MARK: From containing View Controller

    func canvasScrolled(offset: CGFloat) {
        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - 60)
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
}

protocol VeloRow: class {
    var subCells: [UIButton] { get set }
    func addSubview(_: UIView)
    var bounds: CGRect { get }
}

extension VeloRow {
    func arrange() {
        let w = bounds.width/CGFloat(subCells.count)
        for (index, subCell) in subCells.enumerate() {
            subCell.frame = CGRect(x: CGFloat(index)*w, y: 0, width: w, height: bounds.height)
        }
    }
    
    func addSubCell() {
        let subCell = UIButton()
        subCell.titleLabel?.hidden = false
        addSubview(subCell)
        subCells.append(subCell)
        subCell.backgroundColor = UIColor.random()
    }
    
    func setupFields(labels: [String]) {
        if subCells.count == 0 {
            for _ in 0..<labels.count {
                addSubCell()
            }
            arrange()
        }
        
        for (label, subCell) in zip(labels, subCells) {
            subCell.setTitle(label, forState: .Normal)
        }
    }
}

class VeloView: UIView, VeloRow {
    var subCells = [UIButton]()
}

class VeloCell: UITableViewCell, VeloRow {
    class var identifier: String { return "VeloCell" }
    
    var subCells = [UIButton]()
}

extension RLMCollection {
    subscript(i: Int) -> RLMObject {
        return self[UInt(i)] as! RLMObject
    }
    
    var count: Int { return Int(count) }
}

// MARK: Left Index Table View

class IndexDataSource: NSObject, UITableViewDataSource {
    var data: RLMCollection!
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        let label = data[indexPath.row]["index"] as! String
        cell.setupFields([label])
        
        return cell
    }
}

// MARK: Core Table View

class CoreDataSource: NSObject, UITableViewDataSource {
    var data: RLMCollection!
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        
        let row = data[indexPath.row]
//        cell.setupFields(row.objectSchema.properties.filter { $0.name != "index" }.map { "\(row[$0.name]!)" })
        
        return cell
    }
}

// MARK: Computed Columns Table View

class ComputedColumnsDataSource: NSObject, UITableViewDataSource {
    var data: RLMCollection!
//    var computations: [ElementComputation]?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        
//        var texts = [String]()
//        
//        if let row = input?.row(indexPath.row), computations = computations {
//            for comp in computations {
//                comp.apply(row)
//                texts.append("\(comp.apply(row))")
//            }
//        }
//        
//        cell.setupFields(texts)
        
        return cell
    }
}

extension UIColor {
    class func random() -> UIColor {
        func randomFloat() -> CGFloat {
            return CGFloat(arc4random() % 256)/256
        }
        
        return UIColor(red: randomFloat(), green: randomFloat(), blue: randomFloat(), alpha: 1.0)
    }
}


