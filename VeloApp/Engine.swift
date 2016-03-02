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
        
//        sync.tableAdded = onTableAdded
//        sync.tableChanged = onTableChanged
//        sync.tableRemoved = onTableRemoved
    }
    
    // MARK: Collection Retrieval
    
    func getList() -> [(id: String, name: String)] {
        func getId(collectionInfo: RLMObject) -> String { return collectionInfo["collectionId"] as! String }
        func getDisplayName(collection: RLMObject) -> String { return collection["displayName"] as! String }
        
        return realm.allObjects("CollectionInfo").map(getId).map { id in (id, (id |> self.getCollection)! |> getDisplayName) }
    }
    
    func getRowType(rowClass: String) -> RLMObject {
        return realm.objectWithClassName("RowType", forPrimaryKey: rowClass)
    }
    
    // MARK: Collection Helpers
    
    func getSchema(rowClass: String) -> [RLMPropertyType] {
        return realm.schema[rowClass].properties.map { $0.type }
    }
    
    func getCollectionData(collectionId: String) -> (name: String, header: [String], categories: [[String]], rowCounts: [Int]) {
        let collection = (collectionId |> getCollection)!
        
//        printt()
//        print(collection |> getTableClass >>> getRowClass >>> getRowType)
//        print((collection |> getTables).firstObject())
        
        let getRowCounts = getTables >>> map(getRowCount)
        return collection |> (getName, getTableClass >>> getRowClass >>> getRowType >>> getHeader, getCategories, getRowCounts)
    }
    
    func getCollection(collectionId: String) -> RLMObject? {
        guard let info = getCollectionInfo(collectionId) else { return nil }
        return realm.objectWithClassName(info.collectionClass, forPrimaryKey: info.collectionId)
    }
    
    private func getCollectionInfo(collectionId: String) -> CollectionInfo? {
        let collectionInfo: RLMObject? = realm.objectWithClassName("CollectionInfo", forPrimaryKey: collectionId)
        return collectionInfo.map(CollectionInfo.make)
    }

    // MARK: Creation Methods
    
    func newCollection() -> RLMObject {
        let collectionId = sync.getSyncId()
        let tableClass = newCollectionClass(collectionId)
        let collectionClass = tableClass |> getCollectionClass
        
        realm.beginWriteTransaction()
        let table = realm.createObject(tableClass, withValue: [])
        let value = ["displayName" : "My data", "tables" : [table], "id" : collectionId]
        let collection = realm.createObject(collectionClass, withValue: value)
        try! realm.commitWriteTransaction()
        
        return collection
    }
    
    func updateDisplayName(collection: RLMObject, name: String) -> Bool {
        if collection["displayName"] as! String == name {
            return false
        }
    
        realm.beginWriteTransaction()
        collection["displayName"] = name
        try! realm.commitWriteTransaction()
        
        return true
    }
    
    func newCollectionClass(collectionId: String) -> String {
        let tableClass = "Class" + String(Int(arc4random() % 10000))
        
        let rowClass = tableClass |> getRowClass
        let rowSchema = RLMObjectSchema(className: rowClass, objectClass: RowBase.self, properties: realm.schema["RowBase"].properties)
        
        let tableBaseProps = realm.schema["TableBase"].properties
        let rowsProp = RLMProperty(name: "rows", type: .Array, objectClassName: rowClass, indexed: false, optional: false)
        let tableProps = tableBaseProps.filter { prop in prop.name != "rows" } + [rowsProp]
        let tableSchema = RLMObjectSchema(className: tableClass, objectClass: TableBase.self, properties: tableProps)
        
        let collectionClass = tableClass |> getCollectionClass
        let collectionBaseProps = realm.schema["CollectionBase"].properties
        let tablesProp = RLMProperty(name: "tables", type: .Array, objectClassName: tableClass, indexed: false, optional: false)
        let collectionProps = collectionBaseProps.filter { prop in prop.name != "tables" } + [tablesProp]
        let collectionSchema = RLMObjectSchema(className: collectionClass, objectClass: CollectionBase.self, properties: collectionProps)

        realm.beginWriteTransaction()
        realm.addObject(RowType.makeWithRowClass(rowClass))
        realm.addObject(CollectionInfo.make(collectionId, collectionClass: collectionClass))
        try! realm.commitWriteTransaction()
        
        realm.schema.objectSchema += [tableSchema, rowSchema, collectionSchema]
        
        printt()
        print("Table Class Created")
        print(rowSchema)
        print(tableSchema)
        print(collectionSchema)
        
        migrate()
        
        return tableClass
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
    
    func addProperty(type: RLMPropertyType, rowClass: String, displayName: String) -> String {
        let rowTypeProperties = realm.objectWithClassName("RowType", forPrimaryKey: rowClass)["properties"] as! RLMArray
        let propertyId = "prop" + String(rowTypeProperties.count + 1)
        
        realm.beginWriteTransaction()
        let rowFieldProperty = RowFieldProperty()
        rowFieldProperty.displayName = displayName
        rowTypeProperties.addObject(rowFieldProperty)
        try! realm.commitWriteTransaction()
        
        let prop = RLMProperty(name: propertyId, type: type, objectClassName: nil, indexed: false, optional: false)
        
        addProperty(prop, to: rowClass)
        
        return propertyId
    }
    
    private func addProperty(property: RLMProperty, to rowClass: String, value: AnyObject? = nil) {
        let objectSchema = realm.schema[rowClass]
        objectSchema.properties += [property]
        
        let config = realm.configuration
        config.schemaVersion += 1
        let newVersion = config.schemaVersion
        config.migrationBlock = { migration, oldVersion in
            print("Migrating \(oldVersion) -> \(newVersion)")
            guard let value = value else { return }
            
            if oldVersion < newVersion {
                migration.enumerateObjects(rowClass) { oldObject, newObject in
                    newObject?[property.name] = value
                }
            }
        }
        
        RLMRealm.migrateRealm(config)
        realm = try! RLMRealm.dynamicRealm("store")
    }
    
//    private func createTable(tableClass: String, tableId: String) -> RLMObject {
//        let rowType = realm.objectWithClassName("RowType", forPrimaryKey: getRowClassFor(tableClass))
//        
//        realm.beginWriteTransaction()
//        let collectionInfo = CollectionInfo.make(tableId, tableClass: tableClass)
//        realm.addObject(collectionInfo)
//        let object = realm.createObject(tableClass, withValue: ["id" : tableId, "rowType" : rowType])
//        try! realm.commitWriteTransaction()
//        
//        return object
//    }
    
    // MARK: Sync methods

    func onTableAdded(table: Table) {
        if realm.objectWithClassName("TableInfo", forPrimaryKey: table.tableId) == nil {
            addTable(table)
        }
        else {
            updateTable(table)
        }
    }
    
    private func addTable(table: Table) {
//        let tableClass = "Class" + String(Int(arc4random() % 10000))
//        newTableClass(tableClass)
//        
//        for (propName, cellValue) in zip(table.headers, table.data[0]) {
//            addProperty(Engine.typeForCell(cellValue), tableClass: tableClass, displayName: propName)
//        }
//        
//        createTable(tableClass, tableId: table.tableId, displayName: table.name)
//        replaceTableRows(table.data, tableId: table.tableId, tableClass: tableClass)
//        
//        printt()
//        print("Table Added")
//        print(realm.objectWithClassName(tableClass, forPrimaryKey: table.tableId))
    }
    
    private func replaceTableRows(data: [[AnyObject]], tableId: String, tableClass: String) {
        let realmTable = realm.objectWithClassName(tableClass, forPrimaryKey: tableId)
        
        realm.beginWriteTransaction()
        
        realm.deleteObjects(realmTable["rows"]!)
        
        let rowClass = tableClass |> getRowClass
        let rows = RLMArray(objectClassName: rowClass)
        for row in data {
            rows.addObject(realm.createObject(rowClass, withValue: row))
        }
        realmTable["rows"] = rows
        try! realm.commitWriteTransaction()
    }
    
    func onTableChanged(table: Table) {
        updateTable(table)
    }

    private func updateTable(table: Table) {
//        let displayNameChange = updateDisplayName(table.tableId, displayName: table.name)
//        let propertyNameChanges = updatePropertyNames(table.tableId, propertyNames: table.headers)
//        
//        let tableClass = getTableInfo(table.tableId)!.tableClass
//        replaceTableRows(table.data, tableId: table.tableId, tableClass: tableClass)
//
//        printt()
//        print("Table Changed (name: \(displayNameChange), prop names: \(propertyNameChanges))")
//        print(realm.objectWithClassName(tableClass, forPrimaryKey: table.tableId))
    }
    
    func onTableRemoved(table: Table) {
        
    }
    
    // MARK: Creation methods
    

    
    //    func getTableClass(tableId: String) -> String {
    //        return getTableInfo(tableId)!.tableClass
    //    }

    
//    func tableCell(tableId: String, rowIndex: Int, propertyId: String) -> AnyObject {
//        return tableRowObject(tableId, rowIndex: rowIndex)[propertyId]!
//    }
//
//    func tableRow(tableId: String, rowIndex: Int) -> [String : AnyObject] {
//        return tableRowObject(tableId, rowIndex: rowIndex).dict
//    }
    
//    func tableColumn(tableId: String, propertyId: String) -> (type: RLMPropertyType, values: [AnyObject]) {
//        let props = tableProperties(tableId)
//        let columnIndex = props.map { $0.name }.indexOf(propertyId)!
//        let type = props[columnIndex].type
//        let values = tableColumn(tableId, columnIndex: columnIndex)
//        
//        return (type, values)
//    }

//    func tableColumn(tableId: String, columnIndex: Int) -> [AnyObject] {
//        return tableRows(tableId).map { row in row[columnIndex] }
//    }
    
    
    // Internal
    
//    func tableRowObject(tableId: String, rowIndex: Int) -> RLMObject {
//        return tableRowsArray(tableId)[rowIndex]
//    }
    
//    func tableRowsArray(tableId: String) -> RLMArray {
//        let tableClass = getTableInfo(tableId)!.tableClass
//        return realm.objectWithClassName(tableClass, forPrimaryKey: tableId)["rows"] as! RLMArray
//    }
//    
//    func tableProperties(tableId: String) -> [RLMProperty] {
//        let rowClass = getRowClassFor(getTableInfo(tableId)!.tableClass)
//        return realm.schema.schemaForClassName(rowClass)!.properties
//    }
    

    // MARK: Update Methods

//    private func updateDisplayName(collectionId: String, displayName: String) -> Bool {
//        let tableInfo = getTableInfo(collectionId)!
//        
//        if tableInfo.displayName == displayName {
//            return false
//        }
//        
//        realm.beginWriteTransaction()
//        tableInfo.displayName = displayName
//
//        try! realm.commitWriteTransaction()
//        
//        return true
//    }
    
//    private func updatePropertyNames(tableId: String, propertyNames: [String]) -> [Bool] {
//        let tableInfo = getTableInfo(tableId)!
//        let properties = getRowType(tableInfo.tableClass).properties
//        let zipped = zip(properties, propertyNames)
//        let changes = zipped.map { property, newName in newName != property["displayName"] as! String }
//        
//        if changes.contains(idendity) {
//            realm.beginWriteTransaction()
//            zipped.forEach { property, newName in property["displayName"] = newName }
//            try! realm.commitWriteTransaction()
//        }
//        
//        return changes
//    }
    
    private func updateRows(tableId: String, data: [[AnyObject]]) -> [[Bool]] {
        realm.beginWriteTransaction()
        
        try! realm.commitWriteTransaction()
        
        return [[true]]
    }
    
    private func updateRow(index: Int, table: RLMObject, rowData: [AnyObject]) -> [Bool] {
        realm.beginWriteTransaction()
        
        try! realm.commitWriteTransaction()
        
        return [true]
    }
    
    //    private func getRowType(tableClass: String) -> RowType {
    //        let rowType = realm.objectWithClassName("RowType", forPrimaryKey: getRowClassFor(tableClass))
    //        return RowType.make(rowType)
    //    }

//    private func getTableInfo(tableId: String) -> TableInfo? {
//        let tableInfo: RLMObject? = realm.objectWithClassName("TableInfo", forPrimaryKey: tableId)
//        return tableInfo.map(TableInfo.make)
//    }
    
//    private func rowTypeFor(tableClass: String) -> RLMObject {
//        return realm.objectWithClassName("RowType", forPrimaryKey: rowClassFor(tableClass))
//    }
    
    // Property types
    
    class func typeForCell(value: AnyObject) -> RLMPropertyType {
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
        printt()
        print("= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =")
        print("Schema \(realm.configuration.schemaVersion)")
        print(realm.schema)
        
        for className in realm.schema.objectSchema.map({ $0.className }) {
            print("---- \(className) ----")
            print(realm.allObjects(className))
        }
    }
    
    func printt() {
        for _ in 0..<10 { print("*") }
    }

    func createRandomCollection() -> String {
        let collectionId = sync.getSyncId()
        let tableClass = newCollectionClass(collectionId)
        let rowClass = tableClass |> getRowClass
        
        addProperty(.String, rowClass: rowClass, displayName: "Name")
        addProperty(.Double, rowClass: rowClass, displayName: "Number")

        let collectionClass = tableClass |> getCollectionClass
        
        realm.beginWriteTransaction()
        
        let t = Tensor(size: [2, 3, 4])
        
        var cats = [RLMObject]()
        t.size.enumerate().forEach { i, s in
            let id = "cat-" + String(i)
            let values = (0..<s).map { v in
                realm.createObject(RealmString.className(), withValue: ["value" : id + "_" + String(v)])
            }
            cats.append(realm.createObject(Category.className(), withValue: ["values" : values, "id" : id]))
        }
        
        let tables = RLMArray(objectClassName: tableClass)
        
        for i in 0..<t.count {
            let id = "table-" + t.vectorise(i).map(String.init).joinWithSeparator("_")
            
            let rows = RLMArray(objectClassName: rowClass)
            for _ in 0..<(rand() % 5 + 2) {
                rows.addObject(createRandomRow(rowClass)!)
            }
            
            tables.addObject(realm.createObject(tableClass, withValue: ["id" : id, "rows" : rows]))
        }
        
        let value = ["displayName" : "My random data", "tables" : tables, "id" : collectionId, "categories" : cats]
        print(realm.createObject(collectionClass, withValue: value))
        try! realm.commitWriteTransaction()
        
        
        return collectionId
    }
    
    func createRandomRow(className: String) -> RLMObject? {
        guard let objectSchema = realm.schema.schemaForClassName(className) else {
            return nil
        }
        
        var value = [String : AnyObject]()
        
        for prop in objectSchema.properties {
            switch prop.type {
            case .Double: value[prop.name] = Double(arc4random() % 100)
            case .String: value[prop.name] = "str" + String(Int(arc4random() % 1000))
            default: break
            }
        }
        
        return realm.createObject(className, withValue: value)
    }
}

// MARK: Pure functions

func map<T>(f: RLMObject -> T) -> RLMArray -> [T] {
    return { $0.map(f) }
}

func getName(collection: RLMObject) -> String {
    return collection["displayName"] as! String
}

func getHeader(rowType: RLMObject) -> [String] {
    return (rowType["properties"] as! RLMArray).map { $0["displayName"] as! String }
}

func getCategories(collection: RLMObject) -> [[String]] {
    let categories = collection["categories"] as! RLMArray
    
    func getValues(category: RLMObject) -> [String] {
        func getValue(string: RLMObject) -> String {
            return string["value"] as! String
        }
        
        let values = category["values"] as! RLMArray
        return values.map(getValue)
    }
    
    return categories.map(getValues)
}

func getSize(collection: RLMObject) -> [Int] {
    let categories = collection["categories"] as! RLMArray
    
    func getValueCount(category: RLMObject) -> Int {
        return (category["values"] as! RLMArray).count
    }
    
    return categories.map(getValueCount)
}

func getSize<T>(arrayOfArrays: [[T]]) -> [Int] {
    return arrayOfArrays.map { $0.count }
}

func getTables(collection: RLMObject) -> RLMArray {
    return collection["tables"] as! RLMArray
}

func getTable(index: [Int]) -> RLMObject -> RLMObject {
    return { collection  in
        let tensor = collection |> getSize |> Tensor.init
        let tables = collection |> getTables
        
        return tables[index |> tensor.linearise]
    }
}

func getRows(table: RLMObject) -> [[AnyObject]] {
    return (table["rows"] as! RLMArray).map { row in row.array }
}

func getRowCount(table: RLMObject) -> Int {
    return (table["rows"] as! RLMArray).count
}

func getTableClass(collection: RLMObject) -> String {
    return (collection["tables"] as! RLMArray).objectClassName
}

func getRowClass(tableClass: String) -> String {
    return "Row_" + tableClass
}

func getCollectionClass(tableClass: String) -> String {
    return "Coll_" + tableClass
}

func idendity<T>(value: T) -> T {
    return value
}
