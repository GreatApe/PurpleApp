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
            
            if let name = table.name {
                print("Table added: \(name)")
            }
        }
        
        refTables.observeEventType(.ChildRemoved) { (snap: FDataSnapshot!) -> Void in
            if let table = self.tables[snap.key], name = table.name {
                print("Table removed: \(name)")
            }
            self.tables.removeValueForKey(snap.key)
        }
        
        refTables.observeEventType(.ChildChanged) { (snap: FDataSnapshot!) -> Void in
            guard let table = Table(object: snap.value) else {
                return
            }
            self.tables[snap.key] = table
            
            if let name = table.name {
                print("Table updated: \(name)")
            }
        }
    }
    
}

struct Table {
    let data: [[AnyObject]]
    var name: String? {
        if let s = data[0][0] as? String {
            return s
        }
        return nil
    }
    
    init?(object: AnyObject!) {
        guard let d = object as? [[AnyObject]] else {
            return nil
        }
        data = d
    }
}