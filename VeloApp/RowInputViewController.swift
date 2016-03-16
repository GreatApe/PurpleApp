//
//  RowInputViewController.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 13/03/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class HeaderCell: UITableViewCell {
    @IBOutlet weak var cat0: UILabel!
    @IBOutlet weak var cat1: UILabel!
    @IBOutlet weak var index: UILabel!
}

class SelectionCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var selector: UISegmentedControl!
}

class DateCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var picker: UIDatePicker!
}

class RowInputViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
//    override func viewDidLoad() {
//        UIApplication.sharedApplication().applicationIconBadgeNumber = 1
//    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.item {
        case 0: return 100
        case 1: return 95
        case 2: return 245
        case 3: return 245
        default: return 44
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let id: String
        switch indexPath.item {
        case 0: id = "HeaderCell"
        case 1: id = "SelectionCell"
        case 2: id = "DateCell"
        case 3: id = "DateCell"
        default: fatalError()
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(id, forIndexPath: indexPath)
        
        switch (indexPath.item, cell) {
        case (1, let cell as SelectionCell):
            cell.title.text = "Location"
        case (2, let cell as DateCell):
            cell.title.text = "Shift start"
            cell.picker.date = NSDate(timeIntervalSince1970: 8*3600)
        case (3, let cell as DateCell):
            cell.title.text = "Shift end"
            cell.picker.date = NSDate(timeIntervalSince1970: 16*3600)
        default: break
        }

        return cell
    }
    
    @IBAction func tappedSave(sender: UIBarButtonItem) {
        sender.title = "Saved"
        sender.enabled = false
    }
    
    
}
