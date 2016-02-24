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
    private let sync = DataSync()
    
    static var shared = Engine()
    
    private var realm: RLMRealm
    
    private init() {
        let schema: RLMSchema? = realmExists("store") ? nil : RLMRealm.defaultRealm().schema
        realm = try! RLMRealm.dynamicRealm("store", schema: schema)
        
        sync.tableAdded = onTableAdded
        sync.tableChanged = onTableChanged
        sync.tableRemoved = onTableRemoved
    }
    
    // MARK: Sync methods

    func onTableAdded(table: Table) {
        print("---- Table Added ----")
        let tableClass = makeTable(table.tableId)
        for (propName, cellValue) in zip(table.headers, table.data[0]).dropFirst() {
            addProperty(typeForCell(cellValue), tableClass: tableClass, displayName: propName)
        }
        
        printt()
        print(realm.schema[rowClassFor(tableClass)])
        
        replaceTableRows(table.data, tableId: table.tableId, tableClass: tableClass)
        printt()
        describe()
    }
    
    private func replaceTableRows(data: [[AnyObject]], tableId: String, tableClass: String) {
        let realmTable = realm.objectWithClassName(tableClass, forPrimaryKey: tableId)
        
        realm.beginWriteTransaction()
        let rowClass = rowClassFor(tableClass)
        let rows = RLMArray(objectClassName: rowClass)
        for row in data {
            rows.addObject(realm.createObject(rowClass, withValue: row))
        }
        realmTable["rows"] = rows
        try! realm.commitWriteTransaction()
    }
    
    func onTableChanged(table: Table) {
    }

    func onTableRemoved(table: Table) {
    }
    
    // MARK: Creation methods
    
    func makeTable(tableId: String) -> String {
        let tableClass = "TableClass" + String(Int(arc4random() % 10000))
        newTableClass(tableClass)
        createTable(tableClass, tableId: tableId)
        
        return tableClass
    }

    // MARK: Information methods

    func schemaForTableClass(tableClass: String) -> [RLMPropertyType] {
        return realm.schema[tableClass].properties.map { $0.type }
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
        let tableClass = getTableClass(tableId)
        let rows = realm.objectWithClassName(tableClass, forPrimaryKey: tableId)["rows"] as! RLMArray

        return rows.map { row in row.array }
    }
    
    // Internal
    
    func tableRowObject(tableId: String, rowIndex: Int) -> RLMObject {
        return tableRowsArray(tableId)[rowIndex]
    }
    
    func tableRowsArray(tableId: String) -> RLMArray {
        let tableClass = getTableClass(tableId)
        return realm.objectWithClassName(tableClass, forPrimaryKey: tableId)["rows"] as! RLMArray
    }
    
    func tableProperties(tableId: String) -> [RLMProperty] {
        let rowClass = rowClassFor(getTableClass(tableId))
        return realm.schema.schemaForClassName(rowClass)!.properties
    }
    
    // MARK: Schema editing methods
    
    func newTableClass(tableClass: String) {
        let rowClassName = rowClassFor(tableClass)
        let rowProps = realm.schema["RowBase"].properties
        let rowSchema = RLMObjectSchema(className: rowClassName, objectClass: RowBase.self, properties: rowProps)

        realm.beginWriteTransaction()
        let rowType = RowType()
        rowType.rowClassName = rowClassName
        realm.addObject(rowType)
        try! realm.commitWriteTransaction()
        
        let tableBaseProps = realm.schema["TableBase"].properties
        let rowProp = RLMProperty(name: "rows", type: .Array, objectClassName: rowClassName, indexed: false, optional: false)
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
    
//    func addProperty(type: RLMPropertyType, toTable tableId: String, value: AnyObject? = nil) -> String {
//        return addProperty(type, to: tableClassForId[tableId]!, value: value)
//    }
    
    func printt() {
        for _ in 0..<10 { print("*") }
    }
    
    func addProperty(type: RLMPropertyType, tableClass: String, displayName: String, value: AnyObject? = nil) -> String {
        let rowClassName = rowClassFor(tableClass)
        let rowTypeProperties = realm.objectWithClassName("RowType", forPrimaryKey: rowClassName)["properties"] as! RLMArray
        let propertyId = "prop" + String(rowTypeProperties.count + 1)
        
        realm.beginWriteTransaction()
        let rowFieldProperty = RowFieldProperty()
        rowFieldProperty.displayName = displayName
        
        rowTypeProperties.addObject(rowFieldProperty)
        try! realm.commitWriteTransaction()
        
        let prop = RLMProperty(name: propertyId, type: type, objectClassName: nil, indexed: false, optional: false)

        addProperty(prop, to: tableClass)
        
        return propertyId
    }
    
    private func addProperty(property: RLMProperty, to className: String, value: AnyObject? = nil) {
        let rowClassName = rowClassFor(className)
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
    
    // MARK: Helper methods
    
    // Table creation
    
    private func createTable(tableClass: String, tableId: String) -> RLMObject {
        setTableClass(tableClass, forTableId: tableId)
        realm.beginWriteTransaction()
        let object = realm.createObject(tableClass, withValue: ["id" : tableId, "rowType" : rowTypeFor(tableClass)])
        try! realm.commitWriteTransaction()

        return object
    }

    // Class names

    private func setTableClass(tableClass: String, forTableId tableId: String) {
        realm.beginWriteTransaction()
        realm.createObject("TableClass", withValue: [tableClass, tableId])
        try! realm.commitWriteTransaction()
    }
    
    private func getTableClass(tableId: String) -> String {
        return realm.objectWithClassName("TableClass", forPrimaryKey: tableId)["tableClass"] as! String
    }

    private func rowTypeFor(tableClass: String) -> RLMObject {
        return realm.objectWithClassName("RowType", forPrimaryKey: rowClassFor(tableClass))
    }
    
    private func rowClassFor(tableClass: String) -> String {
        return "Row_" + tableClass
    }
    
    // Property types
    
    private func typeForCell(value: AnyObject) -> RLMPropertyType {
        let type: RLMPropertyType
        switch value {
        case is NSNumber: type = .Double
        case is Int: type = .Int
        case is Float: type = .Float
        case is Double: type = .Double

        default: type = .String
        }
        
        return type
    }
    
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
        let className = getTableClass(tableId)
        realm.beginWriteTransaction()
        let table = realm.objectWithClassName(className, forPrimaryKey: tableId)
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
