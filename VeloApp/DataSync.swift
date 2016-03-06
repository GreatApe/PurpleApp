//
//  firebaseViewController.swift
//  VeloApp
//
//  Created by Andreas Okholm on 23/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation
import Realm

class DataSync {
    private let ref = Firebase(url: "https://purplemist.firebaseio.com/")
    lazy var refMetaData: Firebase = { self.ref.childByAppendingPath("collections") }()
    lazy var refTables: Firebase = { self.ref.childByAppendingPath("collectionTables") }()
    
    var collectionAdded: (Collection -> Void)! { didSet { observeCollection(collectionAdded) } }
//    var collectionChanged: (Collection -> Void)! { didSet { observe(.ChildChanged, callback: collectionChanged) } }
//    var collectionRemoved: (Collection -> Void)! { didSet { observe(.ChildRemoved, callback: collectionRemoved) } }
    
//    var rowChanged: ((Table) -> Void)! { didSet { observe(.ChildRemoved, callback: tableRemoved) } }
    
    func getSyncId() -> String {
        return ref.childByAutoId().key
    }
    
//    func upload(table: Table) {
////        refCollections.childByAppendingPath(table.tableId).setValue(table.rawData)
//    }
    
    func upload(row: [AnyObject], atIndex rowIndex: Int, inTable tableId: String) {
        refTables
            .childByAppendingPath(tableId)
            .childByAppendingPath(String(rowIndex + 2))
            .setValue(row)
    }
    
    private func observeCollection(callback: Collection -> Void) {
        refMetaData.observeEventType(.ChildAdded, withBlock: { snap in
            guard let metaData = self.getMetaData(snap) else { return }

            self.refTables.childByAppendingPath(metaData.id).observeSingleEventOfType(.Value, withBlock: { snap in
                guard let collection = self.getCollection(snap, metaData: metaData) else { return }

                callback(collection)
            })
        })
    }
    
    private func getCollection(snap: FDataSnapshot, metaData: CollectionMetaData) -> Collection? {
        guard let data = snap.value as? [String : [[AnyObject]]] else { return nil }
        
        let size = metaData.categories.map { $2.count }
        let tableParser = parseTable(Engine.shared.getSchema(metaData.id))
        
        let tables: [TableData]
        if size.count == 0, let tableData = data["theOneAndOnly"] {
            tables = [tableParser(tableData)]
        }
        else {
            let getFireIndex = { (size: [Int]) in size.reverse().map(String.init).joinWithSeparator("-") }
            tables = Tensor(size: size).all.map(getFireIndex).map { tableParser(data[$0] ?? []) }
        }
        
        guard let schema = tables.flatten().first?.map(Engine.typeForCell) else { // FIXME: Schema should be part of collection
            return nil
        }
        
        return Collection(metaData: metaData.withSchema(schema), tables: tables)
    }
    
    private func getMetaData(snap: FDataSnapshot) -> CollectionMetaData? {
        guard var metaData = snap.value as? [String : AnyObject] else { return nil }
        
        if let catNames = metaData["categoryHeaders"] as? [String] where metaData["categoryIds"] == nil {
            metaData["categoryIds"] = catNames.map { _ in self.getSyncId() }
        }
        
        let id = snap.key
        
        let displayName = metaData["title"] as? String
        
        guard let header = metaData["headers"] as? [String] where header.count > 0 else { return nil }
        
        let categories: [Cat]
        if let catIds = metaData["categoryIds"] as? [String],
            catNames = metaData["categoryHeaders"] as? [String],
            catValues = metaData["categories"] as? [[String]] {
                guard catValues.count == catIds.count && catIds.count == catNames.count else { return nil }
                categories = zip(catIds, catNames, catValues).map { $0 as Cat }
        }
        else {
            categories = []
        }
        
        return CollectionMetaData(id: id, displayName: displayName, header: header, schema: [], categories: categories)
    }
}

typealias TableData = [[AnyObject]]

func zip<A, B, C>(a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
    return zip(a, zip(b, c)).map { ($0, $1.0, $1.1) }
}

struct Collection: CustomStringConvertible {
    let metaData: CollectionMetaData
    let tables: [TableData]
    
    var description: String {
        return metaData.description + ", tables: \(tables.count)"
    }
}

struct CollectionMetaData: CustomStringConvertible {
    let id: String
    let displayName: String?
    let header: [String]
    let schema: [RLMPropertyType]
    let categories: [Cat]
    
    func withSchema(schema: [RLMPropertyType]) -> CollectionMetaData {
        return CollectionMetaData(id: id, displayName: displayName, header: header, schema: schema, categories: categories)
    }
    
    var description: String {
        return "\(displayName), header: \(header), categories: \(categories.map { $2 })"
    }
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

func parseTable(schema: [RLMPropertyType]?) -> TableData -> TableData {
    var rowParser: ([AnyObject] -> [AnyObject])?
    
    return { tableData in
        guard let firstRow = tableData.first else { return [] }
        
        if rowParser == nil {
            if let schema = schema {
                rowParser = parseRow(schema)
            }
            else {
                rowParser = parseRow(firstRow.map(Engine.typeForCell))
            }
        }
        return tableData.map(rowParser!)
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