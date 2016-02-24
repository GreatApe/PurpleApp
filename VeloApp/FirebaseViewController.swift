//
//  firebaseViewController.swift
//  VeloApp
//
//  Created by Andreas Okholm on 23/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation
import Gloss


class FirebaseViewController: UIViewController {
    
    var ds = DataSync()
    
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
    let ref = Firebase(url: "https://purplemist.firebaseio.com/")
    lazy var refTables: Firebase = { self.ref
        .childByAppendingPath("users")
        .childByAppendingPath(self.ref.authData.uid)
        .childByAppendingPath("tables") }()
    
    var tableAdded: (Table -> Void)! { didSet { tableAdd() } }
    var tableChanged: (Table -> Void)! { didSet { tableChange() } }
    var tableRemoved: (Table -> Void)! { didSet { tableRemove() } }
    
    init() {
    }
    
    func getPushId() -> String {
        return ref.childByAutoId().key
    }
    
    func setTable(t: Table) {
        refTables.childByAppendingPath(t.key).setValue(t.rawdata)
    }
    
    func setRow(key: String, rowindex: Int, r: [AnyObject]) {
        refTables
            .childByAppendingPath(key)
            .childByAppendingPath(String(rowindex))
            .setValue(r)
    }
    
    private func tableAdd() {
        refTables.observeEventType(.ChildAdded) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(key: snap.key, object: snap.value) else {
                return
            }
            self.tableAdded(table)
            print("Table added: \(table)")
        }
    }
    private func tableRemove() {
        refTables.observeEventType(.ChildRemoved) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(key: snap.key, object: snap.value) else {
                return
            }
            self.tableRemoved(table)
            print("Table removed: \(table)")
        }
    }
    
    private func tableChange() {
        refTables.observeEventType(.ChildChanged) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(key: snap.key, object: snap.value) else {
                return
            }
            self.tableChanged(table)
            print("Table changed: \(table)")
        }
    }
    
}


struct Table: CustomStringConvertible {
    let rawdata: [[AnyObject]]
    let key: String
    
    var name: String {
        return toString(rawdata[0][0])
    }
    
    var headers: [String] {
        return rawdata[1].map(toString)
    }
    
    var data: [[AnyObject]] {
        return Array(rawdata[2..<rawdata.count])
    }
    
    var description: String {
        return "\(name), header: \(headers), data: \(data)"
    }
    
    init?(key: String, object: AnyObject!) {
        self.key = key
        guard let d = object as? [[AnyObject]] where d.count > 2 else {
            return nil
        }
        rawdata = d
    }
    
    init?(key: String, name: String, headers: [String], var data: [[AnyObject]]) {
        self.key = key
        data.insert([name, "", ""], atIndex: 0)
        data.insert(headers, atIndex: 1)
        rawdata = data
    }
    
    func toString(a: AnyObject) -> String {
        switch a {
        case let n as String: return n
        case let n as NSNumber: return n.stringValue
        default: return "no name"
        }
    }
}