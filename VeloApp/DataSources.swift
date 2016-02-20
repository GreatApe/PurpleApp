//
//  DataSources.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 20/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

protocol VeloRow: class {
    var subCells: [UIButton] { get set }
    func addSubview(_: UIView)
    var bounds: CGRect { get }
    var color: UIColor { get }
}

let margin: CGFloat = 2

extension VeloRow {
    func updateColor() {
        subCells.forEach { $0.backgroundColor = color }
    }
    
    func arrange() {
        let w = bounds.width/CGFloat(subCells.count)
        for (index, subCell) in subCells.enumerate() {
            subCell.frame = CGRect(x: CGFloat(index)*w, y: 0, width: w, height: bounds.height).insetBy(dx: margin, dy: margin)
        }
    }
    
    func addSubCell() {
        let subCell = UIButton()
        subCell.titleLabel?.hidden = false
        addSubview(subCell)
        subCells.append(subCell)
        subCell.backgroundColor = color
    }
    
    func setupFields(labels: [String]) {
        while subCells.count < labels.count {
            addSubCell()
        }
        
        while subCells.count > labels.count {
            subCells.removeLast().removeFromSuperview()
        }
        
        for (label, subCell) in zip(labels, subCells) {
            subCell.setTitle(label, forState: .Normal)
        }
        
        arrange()
    }
}

class VeloView: UIView, VeloRow {
    var color = UIColor.redColor() { didSet { updateColor() } }
    var subCells = [UIButton]()
}

class VeloCell: UITableViewCell, VeloRow {
    class var identifier: String { return "VeloCell" }
    var color = UIColor.redColor() { didSet { updateColor() } }

    var subCells = [UIButton]()
}

// MARK: Left Index Table View

class IndexDataSource: NSObject, UITableViewDataSource {
    var tableId: String!
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Engine.shared.tableRowCount(tableId)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        let label = Engine.shared.tableCell(tableId, rowIndex: indexPath.row, propertyId: "index").description
        cell.setupFields([label])
        cell.color = UIColor.indexCell()
        
        return cell
    }
}

// MARK: Core Table View

class CoreDataSource: NSObject, UITableViewDataSource {
    var tableId: String!
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Engine.shared.tableRowCount(tableId)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(VeloCell.identifier, forIndexPath: indexPath) as! VeloCell
        let row = Engine.shared.tableRow(tableId, rowIndex: indexPath.row)
        cell.setupFields(row.filter { key, value in key != "index" }.map { "\($1)" })
        cell.color = UIColor.coreCell()

        return cell
    }
}

// MARK: Computed Columns Table View

class ComputedColumnsDataSource: NSObject, UITableViewDataSource {
    var tableId: String!

    // temp
    var columns = 1
    //    var computations: [ElementComputation]?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Engine.shared.tableRowCount(tableId)
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
        
        cell.setupFields((0..<columns).map(String.init))
        cell.color = UIColor.computedCell()

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
    
    class func coreHeaderCell() -> UIColor {
        return UIColor(white: 0.6, alpha: 1)
    }

    class func coreCell() -> UIColor {
        return UIColor(white: 0.7, alpha: 1)
    }
    
    class func indexCell() -> UIColor {
        return UIColor(red: 0.6, green: 0.6, blue: 0.8, alpha: 1)
    }
    
    class func computedHeaderCell() -> UIColor {
        return UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1)
    }

    class func computedCell() -> UIColor {
        return UIColor(red: 0.8, green: 0.8, blue: 0.9, alpha: 1)
    }
}
