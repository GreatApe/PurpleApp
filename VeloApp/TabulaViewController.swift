//
//  TabulaViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 22/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TabulaViewController: UICollectionViewController {
    @IBOutlet weak var tabulaLayout: TableFlowLayout!
    
    var tableId: String!
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        collectionView.
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