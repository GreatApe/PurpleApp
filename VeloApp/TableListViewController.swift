//
//  TableListViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 25/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class TableListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var tables: [TableInfo]!
    
    var onSelection: (String? -> Void)!
    
    // MARK: Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tables.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let id = "TableListCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(id) ?? UITableViewCell(style: .Default, reuseIdentifier: id)
        cell.textLabel?.text = tables[indexPath.row].displayName
        return cell
    }
    
    // MARK: Table View Delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        onSelection(tables[indexPath.row].tableId)
    }
    
    // MARK: User Actions

    @IBAction func tappedCreateNew() {
        onSelection(nil)
    }
}
