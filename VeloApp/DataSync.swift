//
//  firebaseViewController.swift
//  VeloApp
//
//  Created by Andreas Okholm on 23/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit
import Realm

protocol SyncDelegate: class {
    func collectionAdded(metaData: MetaData)
    func collectionChanged(metaData: MetaData)
//    func tableAdded(collectionId: String, tableIndex: [Int], data: TableData)
    func rowChanged(collectionId: String, tableIndex: [Int], row: Int, data: RowData)
//    func rowAdded(collectionId: String, tableIndex: [Int], data: RowData)
}

class DataSync {
    private let ref = Firebase(url: "https://purplemist.firebaseio.com/")
    lazy var refMetaData: Firebase = { self.ref.childByAppendingPath("collections") }()
    lazy var refTables: Firebase = { self.ref.childByAppendingPath("collectionTables") }()
    
    weak var delegate: SyncDelegate! { didSet { observe() } }
    
    func getSyncId() -> String {
        return ref.childByAutoId().key
    }
    
//    func upload(table: Table) {
////        refCollections.childByAppendingPath(table.tableId).setValue(table.rawData)
//    }
    
//    func upload(row: [AnyObject], atIndex rowIndex: Int, inTable tableId: String) {
//        refTables
//            .childByAppendingPath(tableId)
//            .childByAppendingPath(String(rowIndex + 2))
//            .setValue(row)
//    }
    
    private func observe() {
        refMetaData.observeEventType(.ChildAdded, withBlock: { snap in
            print("Observe: added: \(snap.key)")
            guard let metaData = self.getMetaData(snap) else { return }
            print("   name: \(metaData.displayName ?? "")")

            self.delegate.collectionAdded(metaData)
            
            let rowParser = parseRow(metaData.schema)

            let refCollection = self.refTables.childByAppendingPath(metaData.id)
            refCollection.observeEventType(.ChildAdded, withBlock: { snap in
//                guard let tableData = snap.value as? TableData else { return }
                
                let tableIndex = getTensorIndex(snap.key)
                
//                self.delegate.tableAdded(metaData.id, tableIndex: tableIndex, data: tableData |> map(rowParser))
                
                refCollection.childByAppendingPath(snap.key).observeEventType(.ChildChanged, withBlock: { snap in
                    guard let row = Int(snap.key), rowData = snap.value as? RowData else { return }
                    
                    self.delegate.rowChanged(metaData.id, tableIndex: tableIndex, row: row, data: rowData |> rowParser)
                })
                
                refCollection.childByAppendingPath(snap.key).observeEventType(.ChildAdded, withBlock: { snap in
                    guard let row = Int(snap.key), rowData = snap.value as? RowData else { return }
                    
                    self.delegate.rowChanged(metaData.id, tableIndex: tableIndex, row: row, data: rowData |> rowParser)

//                    self.delegate.rowAdded(metaData.id, tableIndex: tableIndex, row: row, data: rowData |> rowParser)
                })
            })

        })
        
        refMetaData.observeEventType(.ChildChanged, withBlock: { snap in
            print("Observe: changed: \(snap.key)")

            guard let metaData = self.getMetaData(snap) else { return }
            
            self.delegate.collectionChanged(metaData)
        })
    }
    
    private func getMetaData(snap: FDataSnapshot) -> MetaData? {
        guard var metaData = snap.value as? [String : AnyObject] else { return nil }
        
        if let catNames = metaData["categoryHeaders"] as? [String] where metaData["categoryIds"] == nil {
            metaData["categoryIds"] = catNames.map { _ in self.getSyncId() }
        }
        
        let id = snap.key
        
        let displayName = metaData["title"] as? String
        
        guard let header = metaData["headers"] as? [String] where header.count > 0 else { return nil }

        guard let rawSchema = metaData["schema"] as? [NSString] where rawSchema.count == header.count else { return nil }
        
        let schema = rawSchema.map(RLMPropertyType.make)
        
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
        
        return MetaData(id: id, displayName: displayName, header: header, schema: schema, categories: categories)
    }
}

typealias TableData = [RowData]
typealias RowData = [AnyObject]

func zip<A, B, C>(a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
    return zip(a, zip(b, c)).map { ($0, $1.0, $1.1) }
}

func getFireIndex(index: [Int]) -> String {
    return index.map(String.init).joinWithSeparator("-")
}

func getTensorIndex(fireIndex: String) -> [Int] {
    return fireIndex.componentsSeparatedByString("-").flatMap { Int.init($0) }
}
