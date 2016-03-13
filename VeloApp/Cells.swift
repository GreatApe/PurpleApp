//
//  Cells.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 29/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

extension UIView {
    func flash(color: UIColor) {
        let oldColor = backgroundColor
        backgroundColor = color
        UIView.animateWithDuration(1.5) {
            self.backgroundColor = oldColor
        }
    }
}

extension UITextField {
    func flashText(color: UIColor) {
        let oldColor = textColor
        textColor = color
        UIView.animateWithDuration(1) {
            self.textColor = oldColor
        }
    }
}

protocol LabeledCell {
    var label: UILabel! { get }
}

extension LabeledCell {
    func flashText(color: UIColor) {
        let oldColor = label.textColor
        label.textColor = color
        UIView.animateWithDuration(1) {
            self.label.textColor = oldColor
        }
    }
}

class MetaLabelCell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    override func prepareForReuse() {
        print("Reusing MetaLabelCell")
    }
    
    @IBOutlet weak var label: UILabel!
}

class IndexNameCell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

    @IBOutlet weak var label: UILabel!
}

class FieldNameCell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

    @IBOutlet weak var label: UILabel!
}

class CompFieldNameCell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

    @IBOutlet weak var label: UILabel!
}

class IndexCell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

    @IBOutlet weak var label: UILabel!
}

class Cell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }
    
    override func prepareForReuse() {
        print("Reusing Cell")
    }


    @IBOutlet weak var label: UILabel!
}

class CompColumnCell: UICollectionViewCell, LabeledCell {
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return layoutAttributes
    }

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
    case Index(index: [Int], row: Int)
    case EmptyIndex
    case Cell(index: [Int], row: Int, column: Int)
    case EmptyCell
    case CompColumnCell(index: [Int], row: Int, column: Int)
    case EmptyCompColumnCell
    case CompCell(index: [Int], row: Int, column: Int)
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
    
    init(rowConfig r: RowConfig, tableConfig c: TableConfig, index: [Int], row: Int, column: Int) {
        switch (row, column) {
        case (r.headerRowRange, c.indexColumnRange): self = .IndexName(column: column)
        case (r.headerRowRange, c.columnsRange): self = .FieldName(column: column)
        case (r.headerRowRange, c.emptyColumnsRange): self = .EmptyFieldName
        case (r.headerRowRange, c.compColumnsRange): self = .CompFieldName(column: column - c.firstCompColumn)
        case (r.headerRowRange, c.emptyCompColumnsRange): self = .EmptyCompFieldName
            
        case (r.rowsRange, c.indexColumnRange): self = .Index(index: index, row: row - r.firstRow)
        case (r.rowsRange, c.columnsRange): self = .Cell(index: index, row: row - r.firstRow, column: column)
        case (r.rowsRange, c.emptyColumnsRange): self = .EmptyCell
        case (r.rowsRange, c.compColumnsRange): self = .CompColumnCell(index: index, row: row - r.firstRow, column: column - c.firstCompColumn)
        case (r.rowsRange, c.emptyCompColumnsRange): self = .EmptyCompColumnCell
            
        case (r.emptyRowsRange, c.indexColumnRange): self = .EmptyIndex
        case (r.emptyRowsRange, c.columnsRange): self = .EmptyCell
        case (r.emptyRowsRange, c.emptyColumnsRange): self = .EmptyCell
        case (r.emptyRowsRange, c.compColumnsRange): self = .EmptyCompColumnCell
        case (r.emptyRowsRange, c.emptyCompColumnsRange): self = .Spacer
            
        case (r.compRowsRange, c.indexColumnRange): self = .Spacer
        case (r.compRowsRange, c.columnsRange): self = .CompCell(index: index, row: row - r.firstCompRow, column: column)
        case (r.compRowsRange, c.emptyColumnsRange): self = .Spacer
        case (r.compRowsRange, c.compColumnsRange): self = .CompCell(index: index, row: row - r.firstCompRow, column: column - c.firstCompColumn)
        case (r.compRowsRange, c.emptyCompColumnsRange): self = .Spacer
            
        default: fatalError("Cell error")
        }
    }
}
