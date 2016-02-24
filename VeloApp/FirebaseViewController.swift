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
    
    let ref = Firebase(url: "https://purplemist.firebaseio.com/")
    var tables = [String : Table]()
    
    override func viewDidLoad() {
        setupListeners()
    }
    
    
    func setupListeners() {
        let refTables = ref
            .childByAppendingPath("users")
        .childByAppendingPath(ref.authData.uid)
        .childByAppendingPath("tables")
        
        refTables.observeEventType(.ChildAdded) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(object: snap.value) else {
                return
            }
            self.tables[snap.key] = table
            print("Table added: \(table)")
        }
        
        refTables.observeEventType(.ChildRemoved) { (snap: FDataSnapshot!) -> Void in
            if let table = self.tables[snap.key] {
                print("Table removed: \(table)")
            }
            self.tables.removeValueForKey(snap.key)
        }
        
        refTables.observeEventType(.ChildChanged) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(object: snap.value) else {
                return
            }
            self.tables[snap.key] = table
            print("Table updated: \(table)")
        }
    }
    
}

struct Table: CustomStringConvertible {
    let rawdata: [[AnyObject]]
    
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
    
    init?(object: AnyObject!) {
        guard let d = object as? [[AnyObject]] where d.count > 2 else {
            return nil
        }
        rawdata = d
    }
    
    func toString(a: AnyObject) -> String {
        switch a {
        case let n as String: return n
        case let n as NSNumber: return n.stringValue
        default: return "no name"
        }
    }
}