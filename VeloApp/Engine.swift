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

typealias ChangeCallback = CollectionChange -> ()

class Engine: SyncDelegate {
    private let sync = DataSync()
    
    static var shared = Engine()
    
    private var realm: RLMRealm
    
    private var cache = [String : RLMObject]()
    
    private var changeCallbacks = [String : ChangeCallback]()

    private init() {
        let schema: RLMSchema? = realmExists("store") ? nil : RLMRealm.defaultRealm().schema
        realm = try! RLMRealm.dynamicRealm("store", schema: schema)
        
        sync.delegate = self
    }

    // MARK: Subscription

    func listenToChanges(callback: ChangeCallback) -> String {
        let subscriptionId = sync.getSyncId()
        changeCallbacks[subscriptionId] = callback
        return subscriptionId
    }
    
    func removeListener(subscriptionId: String) {
        changeCallbacks[subscriptionId] = nil
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
    
    func getMetaData(collectionId: String) -> MetaData {
        let c = (collectionId |> getCollection)!

        let schema = getSchema(collectionId)!
        let (name, header, cats) = c |> (getName, getTableClass >>> getRowClass >>> getRowType >>> getHeader, getCategories)
        
        return MetaData(id: collectionId, displayName: name, header: header, schema: schema, categories: cats)
    }
    
    func getRowCounts(collectionId: String) -> [Int] {
        let c = (collectionId |> getCollection)!
        return c |> getTables >>> map(getRowCount)
    }
    
    func getCollection(collectionId: String) -> RLMObject? {
        if let cached = cache[collectionId] {
            return cached
        }
        
        guard let info = getCollectionInfo(collectionId) else {
            return nil
        }
        
        let collection = realm.objectWithClassName(info.collectionClass, forPrimaryKey: info.collectionId)
        cache[collectionId] = collection
        return collection
    }
    
    func getData(collectionId: String, index: [Int], row: Int, column: Int) -> AnyObject {
        guard let c = getCollection(collectionId) else { return 0 }
        return c |> getTable(index) >>> getRows >>> getCell(row, column)
    }
    
    func getSchema(collectionId: String) -> [RLMPropertyType]? {
        guard let collection = collectionId |> getCollection else { return nil }
        return realm.schema[collection |> getTableClass |> getRowClass].properties.map { $0.type }
    }
    
    private func getCollectionInfo(collectionId: String) -> CollectionInfo? {
        let collectionInfo: RLMObject? = realm.objectWithClassName("CollectionInfo", forPrimaryKey: collectionId)
        return collectionInfo.map(CollectionInfo.make)
    }

    // MARK: Creation Methods
    
    func makeCollection(metaData: MetaData) -> RLMObject {
        let tableClass = newCollectionClass(metaData.id)
        let rowClass = tableClass |> getRowClass
        
        for (type, name) in zip(metaData.schema, metaData.header) {
            addProperty(type, rowClass: rowClass, displayName: name)
        }
        
        realm.beginWriteTransaction()
        
        let cats: [RLMObject] = metaData.categories.map { cat in
            if let category = realm.objectWithClassName(Category.className(), forPrimaryKey: cat.id) {
                return category
            }
            else {
                let values = cat.values.map { value in
                    realm.createObject(RealmString.className(), withValue: ["value" : value])
                }
                let val = ["values" : values, "id" : cat.id, "displayName" : cat.name]
                return realm.createObject(Category.className(), withValue: val)
            }
        }
        
        let tables = Tensor(size: metaData.categories.map { $0.values.count }).all.map { i -> RLMObject in
            let id = "table-" + i.map(String.init).joinWithSeparator("_")
            return realm.createObject(tableClass, withValue: ["id" : id])
        }
        
        let collectionClass = tableClass |> getCollectionClass
        let val: [String: AnyObject] = ["displayName" : metaData.displayName ?? "", "tables" : tables, "id" : metaData.id, "categories" : cats]
        let collection = realm.createObject(collectionClass, withValue: val)
        try! realm.commitWriteTransaction()
        
        return collection
    }
    
//    func newCollection() -> RLMObject {
//        let collectionId = sync.getSyncId()
//        let tableClass = newCollectionClass(collectionId)
//        let collectionClass = tableClass |> getCollectionClass
//        
//        realm.beginWriteTransaction()
//        let table = realm.createObject(tableClass, withValue: [])
//        let value = ["displayName" : "My data", "tables" : [table], "id" : collectionId]
//        let collection = realm.createObject(collectionClass, withValue: value)
//        try! realm.commitWriteTransaction()
//        
//        return collection
//    }

    func newCollectionClass(collectionId: String) -> String {
        let tableClass = "Class" + sync.getSyncId()
        
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
        
        cache.removeAll()
        
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
    
    // MARK: Update Methods
    
    private func updateCollection(metaData: MetaData) {
        let c = getCollection(metaData.id)!
        
        let headerChanges = updateHeader(c, header: metaData.header).map(MetaChange.Header)
        let nameChange = updateDisplayName(c, name: metaData.displayName) ? [MetaChange.DisplayName] : []
        
        let change = CollectionChange.Meta(data: metaData, changes: headerChanges + nameChange)
        changeCallbacks.values.forEach { callback in callback(change) }
    }

    private func updateDisplayName(collection: RLMObject, name: String?) -> Bool {
        if getName(collection) == name {
            return false
        }
        
        realm.beginWriteTransaction()
        collection["displayName"] = name
        try! realm.commitWriteTransaction()
        
        return true
    }
    
    private func updateHeader(collection: RLMObject, header: [String]) -> [Int] {
        let props = collection |> getTableClass >>> getRowClass >>> getRowType >>> getProperties
        
        var changed = [Int]()
        
        realm.beginWriteTransaction()

        for (index, (prop, name)) in zip(props, header).enumerate() where getName(prop) != name {
            changed.append(index)
            prop["displayName"] = name
        }
        
        try! realm.commitWriteTransaction()
        
        return changed
    }

//    private func addOrUpdateRow(collectionId: String, tableIndex: [Int], row: Int, data: RowData, isNew: Bool) {
//        let table = getCollection(collectionId)! |> getTable(tableIndex)
//        
//        let rowChange: RowChange
//        if isNew && row < getRowCount(table) {
//            rowChange = addRow(table, schema: getSchema(collectionId)!, rowData: data)
//        }
//        else {
//            rowChange = updateRow(table, schema: getSchema(collectionId)!, row: row, rowData: data)
//        }
//
//        let tableChange = TableChange(tableIndex: tableIndex, rowChanges: [rowChange])
//        
//        let change = CollectionChange.Table(collectionId: collectionId, changes: [tableChange])
//        changeCallbacks.values.forEach { callback in callback(change) }
//    }
    
    private func addRow(table: RLMObject, schema: [RLMPropertyType], rowData: [AnyObject]) -> RowChange {
        let rows = table["rows"] as! RLMArray
        
        realm.beginWriteTransaction()
        rows.addObject(realm.createObject(rows.objectClassName, withValue: rowData))
        try! realm.commitWriteTransaction()
        
        return RowChange(row: rows.count - 1, columnChanges: Array(rowData.indices), added: true)
    }
    
    private func updateRow(table: RLMObject, schema: [RLMPropertyType], row: Int, rowData: [AnyObject]) -> RowChange {
        let oldRow = table |> getRow(row)

        var changed = [Int]()

        for (index, (old, new)) in zip(oldRow, rowData).enumerate() {
            switch (schema[index], old, new) {
            case (.Double, let old as Double, let new as Double): if new != old { changed.append(index) }
            case (.String, let old as String, let new as String): if new != old { changed.append(index) }
            case (.Int, let old as Int, let new as Int): if new != old { changed.append(index) }
            default: continue
            }
        }
        
        let rows = table["rows"] as! RLMArray

        realm.beginWriteTransaction()
        rows.replaceObjectAtIndex(UInt(row), withObject: realm.createObject(rows.objectClassName, withValue: rowData))
        try! realm.commitWriteTransaction()
        
        return RowChange(row: row, columnChanges: changed, added: false)
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
    
    // MARK: Sync Delegate
    
    func collectionAdded(metaData: MetaData) {
        print("ENGINE: Got collection metaData: \(metaData.displayName), \(metaData.header), \(metaData.categories.count) cats. \(metaData.schema.map(describe))")
        
        if realm.objectWithClassName("CollectionInfo", forPrimaryKey: metaData.id) == nil {
            makeCollection(metaData)
        }
        else {
            updateCollection(metaData)
        }
    }
    
    func collectionChanged(metaData: MetaData) {
        print("ENGINE: collectionChanged: \(metaData.displayName), \(metaData.header), \(metaData.categories.count) cats. \(metaData.schema.map(describe))")
        updateCollection(metaData)
    }
    
//    func tableAdded(collectionId: String, tableIndex: [Int], data: TableData) {
//        let table = getCollection(collectionId)! |> getTable(tableIndex)
//        
//        realm.beginWriteTransaction()
//        let rowClass = table.objectSchema.className |> getRowClass
//        let rows = RLMArray(objectClassName: rowClass)
//        
//        for row in data {
//            rows.addObject(realm.createObject(rowClass, withValue: row))
//        }
//        table["rows"] = rows
//        try! realm.commitWriteTransaction()
//    }
    
    func rowChanged(collectionId: String, tableIndex: [Int], row: Int, data: RowData) {
        print("ENGINE: Row \(row) changed for table: \(tableIndex), \(data.count) columns")

        let table = getCollection(collectionId)! |> getTable(tableIndex)
        
        let rowChange: RowChange
        if row < getRowCount(table) {
            rowChange = updateRow(table, schema: getSchema(collectionId)!, row: row, rowData: data)
        }
        else {
            rowChange = addRow(table, schema: getSchema(collectionId)!, rowData: data)
        }
        
        let tableChange = TableChange(tableIndex: tableIndex, rowChanges: [rowChange])
        
        let change = CollectionChange.Table(collectionId: collectionId, changes: [tableChange])
        changeCallbacks.values.forEach { callback in callback(change) }
    }
    
    //    func rowAdded(collectionId: String, tableIndex: [Int], row: Int, data: RowData) {
//        print("ENGINE: Got new row for table: \(tableIndex), \(data.count) columns")
//        addOrUpdateRow(collectionId, tableIndex: tableIndex, row: row, data: data, isNew: true)
//    }
    
//    private func addTable(table: Table) {
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
//    }
    
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
    
    
    // MARK: Creation methods
    
    
//    func tableCell(tableId: String, rowIndex: Int, propertyId: String) -> AnyObject {
//        return tableRowObject(tableId, rowIndex: rowIndex)[propertyId]!
//    }

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
    
    func describeState() {
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
        addProperty(.String, rowClass: rowClass, displayName: "School")
        addProperty(.Double, rowClass: rowClass, displayName: "Number")
        addProperty(.Double, rowClass: rowClass, displayName: "Age")

        let collectionClass = tableClass |> getCollectionClass
        
        realm.beginWriteTransaction()
        
        let t = Tensor(size: [Int(1 + rand() % 5), Int(1 + rand() % 5), Int(1 + rand() % 5)])
        
        var cats = [RLMObject]()
        t.size.enumerate().forEach { i, s in
            let id = sync.getSyncId()
            let name = "cat-" + String(i)
            let values = (0..<s).map { v in
                realm.createObject(RealmString.className(), withValue: ["value" : name + "_" + String(v)])
            }
            cats.append(realm.createObject(Category.className(), withValue: ["values" : values, "id" : id, "displayName" : name]))
        }
        
        let tables = RLMArray(objectClassName: tableClass)
        
        for i in t.all {
            let id = "table-" + getFireIndex(i)
            
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

func map<S, T>(f: S -> T) -> [S] -> [T] {
    return { $0.map(f) }
}

func map<S, T>(f: S -> T) -> S? -> T? {
    return { $0.map(f) }
}

func getName(object: RLMObject) -> String {
    return object["displayName"] as! String
}

func getProperties(rowType: RLMObject) -> RLMArray {
    return rowType["properties"] as! RLMArray
}

func getHeader(rowType: RLMObject) -> [String] {
    return (rowType["properties"] as! RLMArray).map { $0["displayName"] as! String }
}

//func getCategories(collection: RLMObject) -> [[String]] {
//    let categories = collection["categories"] as! RLMArray
//    
//    func getValues(category: RLMObject) -> [String] {
//        func getValue(string: RLMObject) -> String {
//            return string["value"] as! String
//        }
//        
//        let values = category["values"] as! RLMArray
//        return values.map(getValue)
//    }
//    
//    return categories.map(getValues)
//}

func getString(key: String) -> RLMObject -> String {
    return { obj in
        return obj[key] as! String
    }
}

typealias Cat = (id: String, name: String, values: [String])

func getCategories(collection: RLMObject) -> [Cat] {
    let categories = collection["categories"] as! RLMArray
    
    func getValues(category: RLMObject) -> [String] {
        func getValue(string: RLMObject) -> String {
            return string["value"] as! String
        }
        
        let values = category["values"] as! RLMArray
        return values.map(getValue)
    }
    
    return categories.map { cat in cat |> (getString("id"), getString("displayName"), getValues) }
}

func getSize(collection: RLMObject) -> [Int] {
    let categories = collection["categories"] as! RLMArray
    
    func getValueCount(category: RLMObject) -> Int {
        return (category["values"] as! RLMArray).count
    }
    
    return categories.map(getValueCount)
}

//func getSize<T>(arrayOfArrays: [[T]]) -> [Int] {
//    return arrayOfArrays.map { $0.count }
//}

func getTables(collection: RLMObject) -> RLMArray {
    return collection["tables"] as! RLMArray
}

func getTable(index: [Int]) -> RLMObject -> RLMObject {
    return { collection  in
        let (tensor, tables) = collection |> (getSize >>> Tensor.init, getTables)
        return tables[index |> tensor.linearise]
    }
}

func getCell<T>(row: Int, _ column: Int) -> [[T]] -> T {
    return { $0[row][column] }
}

func getRow(row: Int) -> RLMObject -> [AnyObject] {
    return { table in (table["rows"] as! RLMArray)[row].array }
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

// MARK: Change Management

enum CollectionChange {
    case Meta(data: MetaData, changes: [MetaChange])
    case Table(collectionId: String, changes: [TableChange])
    
    var collectionId: String {
        switch self {
        case .Meta(data: let metaData, changes: _): return metaData.id
        case .Table(collectionId: let id, changes: _): return id
        }
    }
}

enum MetaChange {
    case DisplayName
    case Header(Int)
    case Schema
    case Categories
}

struct TableChange {
    let tableIndex: [Int]
    let rowChanges: [RowChange]
}

struct RowChange {
    let row: Int
    let columnChanges: [Int]
    let added: Bool
}

struct MetaData: CustomStringConvertible {
    let id: String
    let displayName: String?
    let header: [String]
    let schema: [RLMPropertyType]
    let categories: [Cat]
    
    var description: String {
        return "\(displayName), header: \(header), categories: \(categories.map { $2 })"
    }
}

// Parsing

extension RLMPropertyType {
    static func make(name: NSString) -> RLMPropertyType {
        switch name {
        case "String": return .String
        case "Int": return .Int
        case "Double": return .Double
        case "Date": return .Date
        case "Data": return .Data
        case "Object": return .Object
        case "Array": return .Array
        case "Bool": return .Bool
        case "Array": return .Array
        default: return .Any
        }
    }
}

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

func parseRow(schema: [RLMPropertyType]) -> RowData -> RowData {
    return { row in
        return zip(row, schema).map { value, type in
            switch (value, type) {
            case (let value as String, .String): return value
            case (_, .String): return ""
            case (let value as NSNumber, .Double): return value.doubleValue
            case (_, .Double): return 0.0
            case (let value as NSNumber, .Int): return value.integerValue ?? 0
            case (_, .Int): return 0
            default: fatalError("Wrong type")
            }
        }
    }
}
