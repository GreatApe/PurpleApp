//
//  firebaseViewController.swift
//  VeloApp
//
//  Created by Andreas Okholm on 23/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation
import Realm

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
    
    var tableAdded: (Table -> Void)! { didSet { observe(.ChildAdded, callback: tableAdded) } }
    var tableChanged: (Table -> Void)! { didSet { observe(.ChildChanged, callback: tableChanged) } }
    var tableRemoved: (Table -> Void)! { didSet { observe(.ChildRemoved, callback: tableRemoved) } }
    
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
    
    private func observe(type: FEventType, callback: Table -> Void) {
        refTables.observeEventType(type, withBlock: { snap in
            let tableId = snap.key

            guard let data = snap.value as? [[AnyObject]] where data.count > 2 else {
                print("#######")
                print("#### Failed parsing ####")
                print(snap.value)
                return
            }

            let schemaForData = data[2].map(Engine.typeForCell)
            let schema = Engine.shared.schemaForTable(tableId) ?? schemaForData
            callback(Table(tableId: tableId, data: data, schema: schema))
        })
    }
    
    private func schemaForRow(data: [[AnyObject]]) -> [RLMPropertyType] {
        return data[2].map(Engine.typeForCell)
    }
}

//func parse(f: Table -> Void) -> FDataSnapshot! -> Void {
//    return { snap in _ = Table(tableId: snap.key, object: snap.value).map(f) }
//}

struct Table: CustomStringConvertible {
    let rawData: [[AnyObject]]
    var tableId: String
    
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
    
    init(tableId: String, data: [[AnyObject]], schema: [RLMPropertyType]) {
        self.tableId = tableId
        let parser = parseRow(schema)
        rawData = data.enumerate().map { index, row in
            index < 2 ? row : parser(row)
        }
    }
    
//    init?(tableId: String, name: String, headers: [String], var data: [[AnyObject]]) {
//        self.tableId = tableId
//        data.insert([name, "", ""], atIndex: 0)
//        data.insert(headers, atIndex: 1)
//        rawData = data
//    }
    
}

// Parsing

func describe(propType: RLMPropertyType) -> String {
    switch propType {
    case .String: return "String"
    case .Int: return "Int"
    case .Double: return "Double"
    case .Date: return "Date"
    case .Data: return "Data"
    case .Object: return "Object"
    case .Array: return "Array"
    case .Any: return "Any"
    case .Bool: return "Bool"
    default: return "Error"
    }
}

func toString(value: AnyObject) -> String {
    switch value {
    case let value as String: return value
    case let value as NSNumber: return value.stringValue
    default: return "Field"
    }
}

func parseRow(schema: [RLMPropertyType]) -> [AnyObject] -> [AnyObject] {
    return { row in
        return zip(row, schema).map { value, type in
            switch (value, type) {
            case (let value as String, .String): return value
            case (_, .String): return "empty string"
            case (let value as NSNumber, .Double): return value.doubleValue
            case (_, .Double): return 9.9
            case (let value as NSNumber, .Int): return value.integerValue ?? 99
            case (_, .Int): return 99
            default: fatalError("Wrong type")
            }
        }
    }
}

//func parseRow(row: [AnyObject]) -> [AnyObject] {
//    return row.map { value in
//        if let num = value as? NSNumber { return num.doubleValue }
//        else { return value }
//    }
//}
