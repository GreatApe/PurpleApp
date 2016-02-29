//
//  LayoutConfigs.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 29/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

struct ColumnConfig: CustomStringConvertible {
    let indexColumns = 1
    var columns = 2
    var emptyColumns = 1
    var compColumns = 1
    var emptyCompColumns = 1
    
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
        return " Columns: \(columns)\n EmptyColumns: \(emptyColumns)" +
        "\n indexColumnRange: \(indexColumnRange)\n columnsRange: \(columnsRange)\n emptyColumnsRange: \(emptyColumnsRange)\n compColumnsRange: \(compColumnsRange)\n emptyCompColumnsRange: \(emptyCompColumnsRange)"
    }
}

struct RowConfig: CustomStringConvertible {
    let headerRows = 1
    var rows = 2
    var emptyRows = 1
    var compRows = 2
    
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

