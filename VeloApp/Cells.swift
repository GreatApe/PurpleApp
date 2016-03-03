//
//  Cells.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 29/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

protocol LabeledCell {
    var label: UILabel! { get }
}

class MetaLabelCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class IndexNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class FieldNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class CompFieldNameCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class IndexCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class Cell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class CompColumnCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var label: UILabel!
}

class CompCell: UICollectionViewCell, LabeledCell {
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var label: UILabel!
}

enum CellType {
    case Mask
    case CategoryValue(category: Int, value: Int)
    case IndexName(column: Int)
    case FieldName(column: Int)
    case EmptyFieldName
    case CompFieldName(column: Int)
    case EmptyCompFieldName
    case Index(row: Int)
    case EmptyIndex
    case Cell(row: Int, column: Int)
    case EmptyCell
    case CompColumnCell(row: Int, column: Int)
    case EmptyCompColumnCell
    case CompCell(row: Int, column: Int)
    case EmptyCompCell
    case Spacer
    
    var id: String {
        switch self {
        case Mask: return "Mask"
        case CategoryValue: return "MetaLabel"
        case IndexName: return "IndexNameCell"
        case FieldName, EmptyFieldName: return "FieldNameCell"
        case CompFieldName, EmptyCompFieldName: return "CompFieldNameCell"
        case Index, EmptyIndex: return "IndexCell"
        case Cell, EmptyCell: return "Cell"
        case CompColumnCell, EmptyCompColumnCell: return "CompColumnCell"
        case CompCell, EmptyCompCell: return "CompCell"
        case Spacer: return "SpacerCell"
        }
    }
    
    var isEmpty: Bool {
        switch self {
        case EmptyFieldName, EmptyCompFieldName, EmptyIndex, EmptyCell, EmptyCompColumnCell, EmptyCompCell: return true
        default: return false
        }
    }
    
    init(rowConfig r: RowConfig, tableConfig c: TableConfig, row: Int, column: Int) {
        switch (row, column) {
        case (r.headerRowRange, c.indexColumnRange): self = .IndexName(column: column)
        case (r.headerRowRange, c.columnsRange): self = .FieldName(column: column)
        case (r.headerRowRange, c.emptyColumnsRange): self = .EmptyFieldName
        case (r.headerRowRange, c.compColumnsRange): self = .CompFieldName(column: column - c.firstCompColumn)
        case (r.headerRowRange, c.emptyCompColumnsRange): self = .EmptyCompFieldName
            
        case (r.rowsRange, c.indexColumnRange): self = .Index(row: row - r.firstRow)
        case (r.rowsRange, c.columnsRange): self = .Cell(row: row - r.firstRow, column: column)
        case (r.rowsRange, c.emptyColumnsRange): self = .EmptyCell
        case (r.rowsRange, c.compColumnsRange): self = .CompColumnCell(row: row - r.firstRow, column: column - c.firstCompColumn)
        case (r.rowsRange, c.emptyCompColumnsRange): self = .EmptyCompColumnCell
            
        case (r.emptyRowsRange, c.indexColumnRange): self = .EmptyIndex
        case (r.emptyRowsRange, c.columnsRange): self = .EmptyCell
        case (r.emptyRowsRange, c.emptyColumnsRange): self = .EmptyCell
        case (r.emptyRowsRange, c.compColumnsRange): self = .EmptyCompColumnCell
        case (r.emptyRowsRange, c.emptyCompColumnsRange): self = .Spacer
            
        case (r.compRowsRange, c.indexColumnRange): self = .Spacer
        case (r.compRowsRange, c.columnsRange): self = .CompCell(row: row - r.firstCompRow, column: column)
        case (r.compRowsRange, c.emptyColumnsRange): self = .Spacer
        case (r.compRowsRange, c.compColumnsRange): self = .CompCell(row: row - r.firstCompRow, column: column - c.firstCompColumn)
        case (r.compRowsRange, c.emptyCompColumnsRange): self = .Spacer
            
        default: fatalError("Cell error")
        }
    }
}
