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

class CollectionBase: RLMObject {
    dynamic var id = ""
    dynamic var displayName: String = ""

    //    dynamic var computedColumns = RLMArray(objectClassName: "ComputedColumn")
    //    dynamic var computedRows = RLMArray(objectClassName: "ComputedRow")

    dynamic var categories = RLMArray(objectClassName: "Category")
    dynamic var tables = RLMArray(objectClassName: "TableBase")
    
//    class func table(index: [Int], collection: RLMObject, tensor: Tensor) -> RLMObject {
//        return (collection["tables"] as! RLMArray)[tensor.linear(index)]
//    }
//    
//    class func dimensions(collection: RLMObject) -> [Int] {
//        return (collection["categories"] as! RLMArray).map(dimension)
//    }
//    
//    class func dimension(category: RLMObject) -> Int {
//        return (category["values"] as! RLMArray).count
//    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

class TableBase: RLMObject {
    dynamic var id: String = ""
    
    //        dynamic var sourceTable: TableX?
    //        dynamic var tableFunction: Function?
    //        dynamic var elementFunction: Function?
    
    dynamic var rows = RLMArray(objectClassName: "RowBase")
    
//    override class func primaryKey() -> String {
//        return "id"
//    }
}

class RowBase: RLMObject {
    //    dynamic var index: String = ""
    //
    //    override class func primaryKey() -> String {
    //        return "index"
    //    }
}

// MARK: Fixed models

class RowType: RLMObject {
    dynamic var rowClassName: String = ""
    dynamic var properties = RLMArray(objectClassName: "RowFieldProperty")
    
    override class func primaryKey() -> String {
        return "rowClassName"
    }
    
    class func makeWithRowClass(rowClassName: String) -> RowType {
        let rowType = RowType()
        rowType.rowClassName = rowClassName
        return rowType
    }
    
    class func make(object: RLMObject) -> RowType {
        let rowType = RowType()
        rowType.rowClassName = object["rowClassName"]! as! String
        rowType.properties = object["properties"]! as! RLMArray
        return rowType
    }
}

class RowFieldProperty: RLMObject {
    dynamic var displayName: String = ""
    dynamic var deleted: Bool = false
}

class CollectionInfo: RLMObject {
    dynamic var collectionId: String = ""
    dynamic var collectionClass: String = ""
    
    class func make(collectionId: String, collectionClass: String) -> CollectionInfo {
        let collectionInfo = CollectionInfo()
        collectionInfo.collectionId = collectionId
        collectionInfo.collectionClass = collectionClass
        return collectionInfo
    }
    
    class func make(object: RLMObject) -> CollectionInfo {
        let collectionInfo = CollectionInfo()
        collectionInfo.collectionId = object["collectionId"]! as! String
        collectionInfo.collectionClass = object["collectionClass"]! as! String
        return collectionInfo
    }
    
    override class func primaryKey() -> String {
        return "collectionId"
    }
}

class Category: RLMObject {
    dynamic var id = ""
    
    dynamic var values = RLMArray(objectClassName: "RealmString")
    
    override class func primaryKey() -> String {
        return "id"
    }
}

class RealmString: RLMObject {
    dynamic var value = ""
}

//class TableType: RLMObject {
//    dynamic var id: String = ""
//    //    dynamic var elementTypeId = ""
//    let properties = RLMArray(objectClassName: "TableProperty")
//}
//
//class TableDecorations: RLMObject {
//    dynamic var id: String = ""
//
//    let computedColumns = List<ComputedColumn>()
//    let computedRows = List<ComputedRow>()
//}
//
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

extension RLMCollection {
    subscript(i: Int) -> RLMObject {
        return self[UInt(i)] as! RLMObject
    }
    
    var count: Int { return Int(count) }
}

extension RLMObject {
    var array: [AnyObject] {
        return objectSchema.properties.map { prop in self[prop.name]! }
    }
    
    var dict: [String : AnyObject] {
        var result = [String : AnyObject]()
        for propName in objectSchema.properties.map({ $0.name }) {
            result[propName] = self[propName]
        }
        
        return result
    }
}

// Meta
// Elk, Elque
// Moose
// Boss
// Money
// Hype, Hypr
