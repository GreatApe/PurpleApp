//
//  Models.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: Dynamic models

class TableX: Object {
    dynamic var id = ""
    dynamic var tableType: TableType?
    
//    dynamic var sourceTable: TableX?
//    dynamic var tableFunction: Function?
//    dynamic var elementFunction: Function?
    
    let elements = List<ElementX>()
    
    var objectType: String { return elements._rlmArray.objectClassName }
}

class ElementX: Object {
//    let hiddenFieldIds = List<RealmString>()
    
    dynamic var index = ""
    dynamic var d0: Double = 0.0
    dynamic var d1: Double = 0.0
//    dynamic var d2: Double = 0.0
//    dynamic var d3: Double = 0.0
    
    dynamic var s0 = ""
    dynamic var s1 = ""
//    dynamic var s2 = ""
//    dynamic var s3 = ""

//    dynamic var t0 = NSDate.distantPast()
//    dynamic var t1 = NSDate.distantPast()
//    dynamic var t2 = NSDate.distantPast()
//    dynamic var t3 = NSDate.distantPast()
}

// MARK: Fixed models

class TableType: Object {
    dynamic var id = ""
    dynamic var elementTypeId = ""
    
    let computedColumns = List<ComputedColumn>()
    let computedRows = List<ComputedRow>()
}

class ComputedColumn: Object {
    dynamic var id = ""
    dynamic var function: Function?
}

class ComputedRow: Object {
    dynamic var id = ""
    let computedRows = List<ComputedCell>()
}

class ComputedCell: Object {
    dynamic var id = ""
    dynamic var function: Function?
}

class Function: Object {
    dynamic var id = ""
    dynamic var elementTypeId = ""
}

class Canvas: Object {
    dynamic var id = ""
    let collections = List<Collection>()
    let collectionLayouts = List<CollectionLayout>()
    
    let categories = List<Category>()
    let mappings = List<Mapping>()
}

class Collection: Object {
    dynamic var id = ""
    let categoryValueIds = List<RealmString>()
    
    let categoryIds = List<RealmString>()
    let groups = List<Group>()
}

class Group: Object {
    dynamic var id = ""
    
    let tableIds = List<RealmString>()
}

class CollectionLayout: Object {
    dynamic var collectionId = ""
    
    dynamic var leftCollection: CollectionLayout?
    dynamic var leftDistance = 0
    dynamic var topCollection: CollectionLayout?
    dynamic var topDistance = 0
    
    let height = RealmOptional<Int>()
    let width = RealmOptional<Int>()
}

class Category: Object {
    dynamic var id = ""
    let values = List<RealmString>()
}

class RealmString: Object {
    dynamic var value = ""
}

class Mapping: Object {
    dynamic var id = ""
    let values = List<Correspondence>()
}

class Correspondence: Object {
    dynamic var id = ""
    dynamic var label = ""
}

// Meta
// Elk, Elque
// Moose
// Boss
// Money
// Hype, Hypr

