//
//  CollectionListViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 25/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class CollectionListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var collections: [(id: String, name: String)]!
    
    var onSelection: (String? -> Void)!
    
    // MARK: Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let id = "CollectionListCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(id) ?? UITableViewCell(style: .Default, reuseIdentifier: id)
        cell.textLabel?.text = collections[indexPath.row].name
        return cell
    }
    
    // MARK: Table View Delegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        onSelection(collections[indexPath.row].id)
    }
    
    // MARK: User Actions

    @IBAction func tappedCreateNew() {
        onSelection(nil)
    }
}
