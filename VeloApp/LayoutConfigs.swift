//
//  LayoutConfigs.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 29/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

struct TableConfig: CustomStringConvertible {
    let indexColumns: Int
    let columns: Int
    let emptyColumns: Int
    let compColumns: Int
    let emptyCompColumns: Int
    
    private let headerRows: Int
    private let emptyRows: Int
    private let compRows: Int
    
    init(columns: Int) {
        self.indexColumns = 1
        self.columns = columns
        self.emptyColumns = 1
        self.compColumns = 0
        self.emptyCompColumns = 0
        
        self.headerRows = 1
        self.emptyRows = 1
        self.compRows = 0
    }
    
    func rowConfig(rowCount: Int) -> RowConfig {
        return RowConfig(headerRows: headerRows, rows: rowCount, emptyRows: emptyRows, compRows: compRows)
    }
    
    var totalColumns: Int { return indexColumns + columns + emptyColumns + compColumns + emptyCompColumns }
    
    var firstIndexColumn: Int { return 0 }
    var firstColumn: Int { return firstIndexColumn + indexColumns }
    var firstEmptyColumn: Int { return firstColumn + columns }
    var firstCompColumn: Int { return firstEmptyColumn + emptyColumns}
    var firstEmptyCompColumn: Int { return firstCompColumn + compColumns}
    
    private func range(from: Int, length: Int) -> Range<Int> { return from..<(from + length) }
    
    var indexColumnRange: Range<Int> { return range(firstIndexColumn, length: indexColumns) }
    var columnsRange: Range<Int> { return range(firstColumn, length: columns) }
    var emptyColumnsRange: Range<Int> { return range(firstEmptyColumn, length: emptyColumns) }
    var compColumnsRange: Range<Int> { return range(firstCompColumn, length: compColumns) }
    var emptyCompColumnsRange: Range<Int> { return range(firstEmptyCompColumn, length: emptyCompColumns) }
    
    func isEmptyColumn(column: Int) -> Bool {
        return emptyColumnsRange.contains(column) || emptyCompColumnsRange.contains(column)
    }
    
    var description: String {
        return " Columns: \(columns)\n EmptyColumns: \(emptyColumns)"
    }
}

struct RowConfig: CustomStringConvertible {
    init(headerRows: Int, rows: Int, emptyRows: Int, compRows: Int) {
        self.headerRows = headerRows
        self.rows = rows
        self.emptyRows = emptyRows
        self.compRows = compRows
    }
    
    let headerRows: Int
    let rows: Int
    let emptyRows: Int
    let compRows: Int
    
    var totalRows: Int { return headerRows + rows + emptyRows + compRows }
    
    var firstHeaderRow: Int { return 0 }
    var firstRow: Int { return firstHeaderRow + headerRows }
    var firstEmptyRow: Int { return firstRow + rows }
    var firstCompRow: Int { return firstEmptyRow + emptyRows}
    
    private func range(from: Int, length: Int) -> Range<Int> { return from..<(from + length) }
    
    var headerRowRange: Range<Int> { return range(firstHeaderRow, length: headerRows) }
    var rowsRange: Range<Int> { return range(firstRow, length: rows) }
    var emptyRowsRange: Range<Int> { return range(firstEmptyRow, length: emptyRows) }
    var compRowsRange: Range<Int> { return range(firstCompRow, length: compRows) }
    
    func isEmptyRow(row: Int) -> Bool {
        return emptyRowsRange.contains(row)
    }
    
    var description: String {
        return "Rows:\(rows), EmptyRows:\(emptyRows), CompRows: \(compRows)"
    }
}
