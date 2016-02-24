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
    
    private var realm: RLMRealm
    private var tableClassForId = [String : String]()
    
    private init() {
        let schema: RLMSchema? = realmExists("store") ? nil : RLMRealm.defaultRealm().schema
        realm = try! RLMRealm.dynamicRealm("store", schema: schema)
    }
    
    // MARK: Access methods

    func tableHeader(tableId: String) -> [String] {
        return tableProperties(tableId).map { $0.name }.filter { $0 != "index" }
    }

    func tableRowCount(tableId: String) -> Int {
        return tableRowsArray(tableId).count
    }

    func tableCell(tableId: String, rowIndex: Int, propertyId: String) -> AnyObject {
        return tableRowObject(tableId, rowIndex: rowIndex)[propertyId]!
    }

    func tableRow(tableId: String, rowIndex: Int) -> [String : AnyObject] {
        return tableRowObject(tableId, rowIndex: rowIndex).dict
    }
    
    func tableColumn(tableId: String, propertyId: String) -> (type: RLMPropertyType, values: [AnyObject]) {
        let props = tableProperties(tableId)
        let columnIndex = props.map { $0.name }.indexOf(propertyId)!
        let type = props[columnIndex].type
        let values = tableColumn(tableId, columnIndex: columnIndex)
        
        return (type, values)
    }

    func tableColumn(tableId: String, columnIndex: Int) -> [AnyObject] {
        return tableRows(tableId).map { row in row[columnIndex] }
    }
    
    func tableRows(tableId: String) -> [[AnyObject]] {
        let tableClass = tableClassForId[tableId]!
        let rows = realm.objectWithClassName(tableClass, forPrimaryKey: tableId)["rows"] as! RLMArray

        return rows.map { row in row.array }
    }
    
    // Internal
    
    func tableRowObject(tableId: String, rowIndex: Int) -> RLMObject {
        return tableRowsArray(tableId)[rowIndex]
    }
    
    func tableRowsArray(tableId: String) -> RLMArray {
        let tableClass = tableClassForId[tableId]!
        return realm.objectWithClassName(tableClass, forPrimaryKey: tableId)["rows"] as! RLMArray
    }
    
    func tableProperties(tableId: String) -> [RLMProperty] {
        let rowClass = "Row" + tableClassForId[tableId]!
        return realm.schema.schemaForClassName(rowClass)!.properties
    }
    
    // MARK: Schema editing methods
    
    func newTableClass(tableClass: String) {
        let rowClass = "Row" + tableClass
        let rowProps = realm.schema["RowBase"].properties
        let rowSchema = RLMObjectSchema(className: rowClass, objectClass: RowBase.self, properties: rowProps)

        let tableBaseProps = realm.schema["TableBase"].properties
        let rowProp = RLMProperty(name: "rows", type: .Array, objectClassName: rowClass, indexed: false, optional: false)
        let tableProps = tableBaseProps.filter { prop in prop.name != "rows" } + [rowProp]
        let tableSchema = RLMObjectSchema(className: tableClass, objectClass: TableBase.self, properties: tableProps)

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
    
    func addProperty(type: RLMPropertyType, toTable tableId: String, value: AnyObject? = nil) -> String {
        return addProperty(type, to: tableClassForId[tableId]!, value: value)
    }
    
    func addProperty(type: RLMPropertyType, to className: String, value: AnyObject? = nil) -> String {
        let name = "prop-" + String(Int(arc4random() % 1000))
        let prop = RLMProperty(name: name, type: type, objectClassName: nil, indexed: false, optional: false)

        addProperty(prop, to: className)
        
        return name
    }
    
    func addProperty(property: RLMProperty, to className: String, value: AnyObject? = nil) {
        let rowClassName = "Row" + className
        let objectSchema = realm.schema[rowClassName]
        objectSchema.properties += [property]
        
        let config = realm.configuration
        config.schemaVersion += 1
        let newVersion = config.schemaVersion
        config.migrationBlock = { migration, oldVersion in
            print("Migrating \(oldVersion) -> \(newVersion)")
            guard let value = value else { return }
            
            if oldVersion < newVersion {
                migration.enumerateObjects(rowClassName) { oldObject, newObject in
                    newObject?[property.name] = value
                }
            }
        }
        
        RLMRealm.migrateRealm(config)
        realm = try! RLMRealm.dynamicRealm("store")
    }
    
    // MARK: Creation methods
    
    func makeTable() -> String {
        let tableId = "tableId" + String(Int(arc4random() % 1000))
        let tableClass = "TableClass" + String(Int(arc4random() % 10000))
        
        newTableClass(tableClass)
        realm.beginWriteTransaction()
        createTable(tableClass, tableId: tableId)
        try! realm.commitWriteTransaction()
        
        return tableId
    }
    
    // Internal
    
    func createTable(tableClassName: String, tableId: String) -> RLMObject {
        tableClassForId[tableId] = tableClassName
        return realm.createObject(tableClassName, withValue: ["id" : tableId])
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
        
        let t = createTable(className, tableId: name ?? "abcd" + String(Int(arc4random() % 10000)))
        
        for _ in 0..<30 {
            addRandomRowToTable(t)
        }
        
        try! realm.commitWriteTransaction()
        
        return t
    }
    
    func addRandomRowToTable(tableId: String) {
        realm.beginWriteTransaction()
        let table = realm.objectWithClassName(tableClassForId[tableId]!, forPrimaryKey: tableId)
        addRandomRowToTable(table)
        try! realm.commitWriteTransaction()
    }

    func addRandomRowToTable(table: RLMObject) {
        let rows = table["rows"] as! RLMArray
        
        if let row = createRandomRow(rows.objectClassName) {
            rows.addObject(row)
        }
    }

    func createRandomRow(className: String) -> RLMObject? {
        guard let objectSchema = realm.schema.schemaForClassName(className) else {
            return nil
        }
        
        var value = [String : AnyObject]()
        
        for prop in objectSchema.properties {
            if prop.name == "index" {
//                value[prop.name] = NSUUID().UUIDString
                value[prop.name] = "ndx" + String(Int(arc4random() % 10000))
            }
            else {
                switch prop.type {
                case .Double: value[prop.name] = Double(arc4random() % 100)
                case .String: value[prop.name] = "str" + String(Int(arc4random() % 1000))
                default: break
                }
            }
        }
        
        return realm.createObject(className, withValue: value)
    }
}
