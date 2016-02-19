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

//class CollectionBase: RLMObject {
//    dynamic var id = ""
//    dynamic var categoryIds = RLMArray(objectClassName: "RealmString")
//    dynamic var rows = RLMArray(objectClassName: "TableBase")
//}
//
//class TaggedTableBase: RLMObject {
//    dynamic var categoryValueIds = RLMArray(objectClassName: "RealmString")
//    dynamic var table: TableBase?
//}

class TableBase: RLMObject {
    dynamic var id: String = ""
    //    var elementTypeId: String { return rows.objectClassName }
    
    //        dynamic var sourceTable: TableX?
    //        dynamic var tableFunction: Function?
    //        dynamic var elementFunction: Function?
    
    dynamic var rows = RLMArray(objectClassName: "ElementBase")
    
    //    let computedColumns = List<ComputedColumn>()
    //    let computedRows = List<ComputedRow>()
    
    
    override class func primaryKey() -> String {
        return "id"
    }
}

class ElementBase: RLMObject {
    dynamic var index = ""
    dynamic var something = ""
    // Add properties dynamically
    
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
//
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

extension RLMRealm {
    func newElementClass(name: String) {
        RLMObjectSchema(className: name, objectClass: RLMObject.self, properties: schema["TableBase"].properties)
        
        //        schema.obj
        //            = objectSchema
    }
    
    func addProperty(property: RLMProperty, to className: String, value: AnyObject? = nil) {
        let objectSchema = schema[className]
        objectSchema.properties += [property]
        
        let config = configuration
        config.schemaVersion += 1
        let newVersion = config.schemaVersion
        config.migrationBlock = { migration, oldVersion in
            print("Migrating from \(oldVersion) to \(newVersion)")
            guard let value = value else { return }
            
            if oldVersion < newVersion {
                migration.enumerateObjects(className) { oldObject, newObject in
                    newObject?[property.name] = value
                }
            }
        }
        
        RLMRealm.migrateRealm(config)
    }
    
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

