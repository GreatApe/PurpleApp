//
//  firebaseViewController.swift
//  VeloApp
//
//  Created by Andreas Okholm on 23/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation

class FirebaseViewController: UIViewController {
    
    let ds = DataSync()
    
    override func viewDidLoad() {
        ds.tableAdded = { (t: Table) in
            print("add \(t.name)")
        }
        ds.tableChanged = { (t: Table) in
            print("change \(t.name)")
        }
        ds.tableRemoved = { (t: Table) in
            print("remove \(t.name)")
        }
    }
}

class DataSync {
    private let ref = Firebase(url: "https://purplemist.firebaseio.com/")
    lazy var refTables: Firebase = { self.ref.childByAppendingPath("tables") }()
    
    var tableAdded: (Table -> Void)! { didSet { tableAdd() } }
    var tableChanged: (Table -> Void)! { didSet { tableChange() } }
    var tableRemoved: (Table -> Void)! { didSet { tableRemove() } }
    
    func getSyncId() -> String {
        return ref.childByAutoId().key
    }
    
    func upload(table: Table) {
        refTables.childByAppendingPath(table.tableId).setValue(table.rawData)
    }
    
    func upload(row: [AnyObject], atIndex rowIndex: Int, inTable tableId: String) {
        refTables
            .childByAppendingPath(tableId)
            .childByAppendingPath(String(rowIndex))
            .setValue(row)
    }
    
    private func tableAdd() {
        refTables.observeEventType(.ChildAdded) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(tableId: snap.key, object: snap.value) else {
                return
            }
            self.tableAdded(table)
        }
    }
    private func tableRemove() {
        refTables.observeEventType(.ChildRemoved) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(tableId: snap.key, object: snap.value) else {
                return
            }
            self.tableRemoved(table)
        }
    }
    
    private func tableChange() {
        refTables.observeEventType(.ChildChanged) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(tableId: snap.key, object: snap.value) else {
                return
            }
            self.tableChanged(table)
        }
    }
}

struct Table: CustomStringConvertible {
    let rawData: [[AnyObject]]
    let tableId: String
    
    var name: String {
        return toString(rawData[0][0])
    }
    
    var headers: [String] {
        return rawData[1].map(toString)
    }
    
    var data: [[AnyObject]] {
        return Array(rawData[2..<rawData.count])
    }
    
    var description: String {
        return "\(name), header: \(headers)\ndata: \(data)"
    }
    
    init?(tableId: String, object: AnyObject!) {
        self.tableId = tableId
        guard let data = object as? [[AnyObject]] where data.count > 2 else {
            return nil
        }
        
        rawData = data.map(parseRow)
    }
    
    init?(tableId: String, name: String, headers: [String], var data: [[AnyObject]]) {
        self.tableId = tableId
        data.insert([name, "", ""], atIndex: 0)
        data.insert(headers, atIndex: 1)
        rawData = data
    }
    
    func toString(value: AnyObject) -> String {
        switch value {
        case let value as String: return value
        case let value as NSNumber: return value.stringValue
        default: return "Field"
        }
    }
}

// Parsing

func parseRow(row: [AnyObject]) -> [AnyObject] {
    return row.map { value in
        if let num = value as? NSNumber { return num.doubleValue }
        else { return value }
    }
}
