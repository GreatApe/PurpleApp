//
//  VeloTableViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 11/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit
import RealmSwift

class VeloTableViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var leftIndexColumnOffset: NSLayoutConstraint!
    
    @IBOutlet weak var leftIndexTableView: UITableView!
    @IBOutlet weak var coreTableView: UITableView!
    @IBOutlet weak var computedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftIndexTableView.dataSource = IndexDataSource()
        coreTableView.dataSource = RowDataSource()
        computedTableView.dataSource = RowDataSource()
    }

    // MARK: UITableViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        leftIndexTableView.contentOffset = scrollView.contentOffset
        coreTableView.contentOffset = scrollView.contentOffset
        computedTableView.contentOffset = scrollView.contentOffset
    }

    // MARK: User Actions
    
    @IBAction func tableNameChanged(sender: UITextField) {
        sender.invalidateIntrinsicContentSize()
    }
}

class IndexDataSource: NSObject, UITableViewDataSource {
    let data = ["Donald", "Mickey", "Minney"]
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

class RowDataSource: NSObject, UITableViewDataSource {
    let data = ["Donald", "Mickey", "Minney"]
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}



