//
//  TabulaViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TabulaViewController: UICollectionViewController {
    var tableId: String!
    
    var selected = true { didSet { changedSelected() } }
    
    private var columns = 3
    private var computedColumns = 2
    private var rows = 3
    private var computedRows = 2

    private var layout: TableLayout { return collectionView!.collectionViewLayout as! TableLayout }
    
    // MARK: Setters
    
    private func changedSelected() {
        let newLayout = layout.duplicate
        newLayout.selected = selected
        collectionView!.setCollectionViewLayout(newLayout, animated: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        collectionView.
    }
    
    override func viewDidLoad() {
        layout.indexWidth = 100
        layout.mainWidths = [80, 80, 80, 80, 80, 30]
        layout.computedWidths = [60, 60, 30]
        layout.rows = 4
        layout.computedRows = 2
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("NewCell", forIndexPath: indexPath)
        return cell
    }
    
    // MARK: From containing View Controller
    
    func canvasScrolled(offset: CGFloat) {
//        let stopWidth = addComputedColumnsWidth.constant + (computedColumns.frame.width == 0 ? mainStack.spacing : 0)
//        leftIndexColumnOffset.constant = clamp(offset, 0, view.frame.width - leftIndexTableView.frame.width - stopWidth)
    }
}