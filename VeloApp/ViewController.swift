//
//  VeloTableViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit
import RealmSwift

class Engine {
    static var shared = Engine()
    
    private let realm = try! Realm()
    
    private init() {
        
    }
    
    func data(address: [String]) -> [AnyObject] {
        ["Table1", "d0"]
        
        return [1, 2]
    }
}

class VeloCanvasViewController: UIViewController, UIScrollViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()

        if let t = realm.objects(TableX).first {
            return
        }
        
        func randomElement() -> ElementX {
            let e = ElementX()
            e.index = "idx" + String(Int(arc4random() % 1000))
            e.s0 = "str" + String(Int(arc4random() % 100))
            e.s1 = "str" + String(Int(arc4random() % 100))
            
            e.d0 = Double(arc4random() % 100)
            e.d1 = Double(arc4random() % 100)
            
            print("randomElement: \(e.index)")
            
            return e
        }
        
        try! realm.write {
            let t = TableX()
            t.id = NSUUID().UUIDString
            
            for _ in 1..<30 {
                t.elements.append(randomElement())
            }
            realm.add(t)
        }
    }
    
    var veloTables = [VeloTableViewController]()
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let veloTable = segue.destinationViewController as? VeloTableViewController {
            veloTables.append(veloTable)
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

protocol VeloType {}

extension Double: VeloType {}
extension String: VeloType {}

struct ElementComputation {
    let elementType: String
    let inputFields: [String]
    let computation: AnyComputation
    
    func apply(element: Object) -> VeloType {
        let values = inputFields.map { element[$0]! }
        
        if let comp = computation as? Computation<Double> {
            return comp.function(values)
        }
        else if let comp = computation as? Computation<String> {
            return comp.function(values)
        }
        
        return "FAIL"
    }
}

protocol AnyComputation {
    var signature: [String] { get }
}

struct Computation<T: VeloType>: AnyComputation {
    let signature: [String]
    let function: [AnyObject] -> T
}

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
    
    var data: List<ElementX>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        
        let table = realm.objects(TableX).first!
        data = table.elements
        
        coreHeaderRow.setupFields(realm.schema[table.objectType]!.properties.dropFirst().map { $0.name } )
        
        leftIndexTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        leftIndexDataSource.data = data
        leftIndexTableView.dataSource = leftIndexDataSource
        
        coreTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        coreTableDataSource.data = data
        coreTableView.dataSource = coreTableDataSource

        computedColumnsTableView.registerClass(VeloCell.self, forCellReuseIdentifier: VeloCell.identifier)
        computedColumnsDataSource.input = data
        
        let valueCompDiff = Computation<Double>(signature: ["Double", "Double"]) { values in
            return (values[0] as! Double) - (values[1] as! Double)
        }

        let valueCompSum = Computation<Double>(signature: ["Double", "Double"]) { values in
            return (values[0] as! Double) + (values[1] as! Double)
        }

        let elementType = data!._rlmArray.objectClassName
        let inputFields = ["d1", "d0"]
        
        let comp1 = ElementComputation(elementType: elementType, inputFields: inputFields, computation: valueCompDiff)
        let comp2 = ElementComputation(elementType: elementType, inputFields: inputFields, computation: valueCompSum)
        
        computedColumnsDataSource.computations = [comp1, comp2]
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

// MARK: Left Index Table View

class IndexDataSource: NSObject, UITableViewDataSource {
    weak var data: ObjectList?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        let label = data?.row(indexPath.row)["index"] as? String ?? ""
        cell.setupFields([label])
        
        return cell
    }
}

// MARK: Core Table View

protocol ObjectList: class {
    func row(i: Int) -> Object
    var count: Int { get }
}

extension List: ObjectList {
    func row(i: Int) -> Object {
        return self[i]
    }
}

class CoreDataSource: NSObject, UITableViewDataSource {
    weak var data: ObjectList?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell

        var texts = [String]()
        
        if let row = data?.row(indexPath.row) {
            for prop in row.objectSchema.properties where prop.name != "index" {
                texts.append("\(row[prop.name]!)")
            }
        }
        
        cell.setupFields(texts)
        
        return cell
    }
}

// MARK: Computed Columns Table View

class ComputedColumnsDataSource: NSObject, UITableViewDataSource {
    weak var input: ObjectList?
    var computations: [ElementComputation]?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return input?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        
        var texts = [String]()
        
        if let row = input?.row(indexPath.row), computations = computations {
            for comp in computations {
                comp.apply(row)
                texts.append("\(comp.apply(row))")
            }
        }
        
        cell.setupFields(texts)
        
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



