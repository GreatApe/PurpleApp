//
//  Models.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation
import Realm

// MARK: Dynamic models

class Collection: RLMObject {
    dynamic var id = ""
    dynamic var categoryIds = RLMArray(objectClassName: "RealmString")
    dynamic var taggedTables = RLMArray(objectClassName: "TaggedTable")
}

class TaggedTable: RLMObject {
    dynamic var categoryValueIds = RLMArray(objectClassName: "RealmString")
    dynamic var tableId = ""
    
    override class func indexedProperties() -> [String] {
        return ["tableId"]
    }
}

class TableBase: RLMObject {
    dynamic var id: String = ""
    
    //        dynamic var sourceTable: TableX?
    //        dynamic var tableFunction: Function?
    //        dynamic var elementFunction: Function?
    
    dynamic var rows = RLMArray(objectClassName: "RowBase")
    
    //    let computedColumns = List<ComputedColumn>()
    //    let computedRows = List<ComputedRow>()
    
    override class func primaryKey() -> String {
        return "id"
    }
}

class RowBase: RLMObject {
    dynamic var index = ""
    
    override class func primaryKey() -> String {
        return "index"
    }
}

// MARK: Fixed models

class TableType: RLMObject {
    dynamic var id: String = ""
    //    dynamic var elementTypeId = ""
    //
    //    let computedColumns = List<ComputedColumn>()
    //    let computedRows = List<ComputedRow>()
}

//class ComputedColumn: Object {
//    dynamic var id = ""
//    dynamic var function: Function?
//}
//
//class ComputedRow: Object {
//    dynamic var id = ""
//    let computedRows = List<ComputedCell>()
//}
//
//class ComputedCell: Object {
//    dynamic var id = ""
//    dynamic var function: Function?
//}
//
//class Function: Object {
//    dynamic var id = ""
//    dynamic var elementTypeId = ""
//}
//
//class Canvas: Object {
//    dynamic var id = ""
//    let collections = List<Collection>()
//    let collectionLayouts = List<CollectionLayout>()
//    
//    let categories = List<Category>()
//    let mappings = List<Mapping>()
//}
//
//class Group: Object {
//    dynamic var id = ""
//    
//    let tableIds = List<RealmString>()
//}
//
//class CollectionLayout: Object {
//    dynamic var collectionId = ""
//    
//    dynamic var leftCollection: CollectionLayout?
//    dynamic var leftDistance = 0
//    dynamic var topCollection: CollectionLayout?
//    dynamic var topDistance = 0
//    
//    let height = RealmOptional<Int>()
//    let width = RealmOptional<Int>()
//}

//class Category: Object {
//    dynamic var id = ""
//    let values = List<RealmString>()
//}

class RealmString: RLMObject {
    dynamic var value = ""
}

//class Mapping: Object {
//    dynamic var id = ""
//    let values = List<Correspondence>()
//}
//
//class Correspondence: Object {
//    dynamic var id = ""
//    dynamic var label = ""
//}

func realmPath(name: String) -> String {
    let path: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    return path.stringByAppendingPathComponent(name)
}

func realmExists(name: String) -> Bool {
    return NSFileManager.defaultManager().fileExistsAtPath(realmPath(name) + ".realm")
}

extension RLMRealm {    
    class func dynamicRealm(name: String, schema: RLMSchema? = nil) throws -> RLMRealm {
        return try RLMRealm(path: realmPath(name) + ".realm", key: nil, readOnly: false, inMemory: false, dynamic: true, schema: schema)
    }
}

// Meta
// Elk, Elque
// Moose
// Boss
// Money
// Hype, Hypr

