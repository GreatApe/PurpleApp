//
//  Engine.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 19/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation
import Realm

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

class Engine {
    static var shared = Engine()
    
    var realm: RLMRealm
    
    private init() {
        let schema: RLMSchema? = realmExists("store") ? nil : RLMRealm.defaultRealm().schema
        realm = try! RLMRealm.dynamicRealm("store", schema: schema)
    }
    
    func newTableClass(id: String) {
        let rowName = "Row" + id
        let rowProps = realm.schema["RowBase"].properties
        let rowSchema = RLMObjectSchema(className: rowName, objectClass: RowBase.self, properties: rowProps)

        let tableBaseProps = realm.schema["TableBase"].properties
        let rowProp = RLMProperty(name: "rows", type: .Array, objectClassName: rowName, indexed: false, optional: false)
        let tableProps = tableBaseProps.filter { prop in prop.name != "rows" } + [rowProp]
        let tableSchema = RLMObjectSchema(className: "Table" + id, objectClass: TableBase.self, properties: tableProps)

        realm.schema.objectSchema += [tableSchema, rowSchema]

        migrate()
    }
    
    func migrate() {
        let config = realm.configuration
        config.schemaVersion += 1
        let newVersion = config.schemaVersion
        config.migrationBlock = { migration, oldVersion in
            print("Migrating \(oldVersion) -> \(newVersion)")
        }

        RLMRealm.migrateRealm(config)
        realm = try! RLMRealm.dynamicRealm("store")
    }
    
    func addProperty(type: RLMPropertyType, to className: String, value: AnyObject? = nil) -> String {
        let name = "prop-" + String(Int(arc4random() % 1000))
        let prop = RLMProperty(name: name, type: type, objectClassName: nil, indexed: false, optional: false)

        addProperty(prop, to: className)
        
        return name
    }
    
    func addProperty(property: RLMProperty, to className: String, value: AnyObject? = nil) {
        let objectSchema = realm.schema[className]
        objectSchema.properties += [property]
        
        let config = realm.configuration
        config.schemaVersion += 1
        let newVersion = config.schemaVersion
        config.migrationBlock = { migration, oldVersion in
            print("Migrating \(oldVersion) -> \(newVersion)")
            guard let value = value else { return }
            
            if oldVersion < newVersion {
                migration.enumerateObjects(className) { oldObject, newObject in
                    newObject?[property.name] = value
                }
            }
        }
        
        RLMRealm.migrateRealm(config)
    }
    
    func createTable(tableClassName: String, id: String) -> RLMObject {
        return realm.createObject(tableClassName, withValue: ["id" : id])
    }
    
    func tableHeader(table: RLMObject) -> [String] {
        let rows = table["rows"] as! RLMArray
        return realm.schema.schemaForClassName(rows.objectClassName)!.properties.map { $0.name }.filter { $0 != "index" }
    }
    
    func table(className: String, id: String) -> RLMObject {
        return realm.objectWithClassName(className, forPrimaryKey: id)
    }
    
    func tableRows(tableId: String) -> RLMArray {
        fatalError()
    }

    // Helper methods
    
    // Debugging methods

    func describe() {
        print("= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =")
        print("Schema \(realm.configuration.schemaVersion)")
        print(realm.schema)
        
        for className in realm.schema.objectSchema.map({ $0.className }) {
            print("---- \(className) ----")
            print(realm.allObjects(className))
        }
    }
    
    func createRandomTable(className: String, name: String? = nil) -> RLMObject {
        realm.beginWriteTransaction()
        
        let t = createTable(className, id: name ?? "abcd" + String(Int(arc4random() % 1000)))
        print("Created table: \(t)")
        
        for _ in 0..<3 {
            addRandomRowToTable(t)
        }
        
        print("Added rows table: \(t)")

        try! realm.commitWriteTransaction()
        
        return t
    }
    
    func addRandomRowToTable(table: RLMObject) {
        let rows = table["rows"] as! RLMArray
        
        if let row = createRandomRow(rows.objectClassName) {
            print("Adding object row: \(row)")

            rows.addObject(row)
        }
    }

    func createRandomRow(className: String) -> RLMObject? {
        guard let objectSchema = realm.schema.schemaForClassName(className) else {
            return nil
        }
        
        var value = [String : AnyObject]()
        
        for prop in objectSchema.properties {
            if prop.name == "id" {
                value[prop.name] = NSUUID().UUIDString
            }
            else {
                switch prop.type {
                case .Double: value[prop.name] = Double(arc4random() % 100)
                case .String: value[prop.name] = "str" + String(Int(arc4random() % 1000))
                default: break
                }
            }
        }
        print("Creating random row: \(value)")

        return realm.createObject(className, withValue: value)
    }
}
