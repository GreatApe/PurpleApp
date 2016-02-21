//
//  Canvas.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 20/02/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class VeloCanvasViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var canvas: UIView!
    @IBOutlet weak var canvasWidth: NSLayoutConstraint!
    @IBOutlet weak var canvasHeight: NSLayoutConstraint!
    
    private var veloTables = [VeloTableViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func newTable(point: CGPoint) {
        if let tvc = storyboard?.instantiateViewControllerWithIdentifier("VeloTable") as? VeloTableViewController {
            let tableId = Engine.shared.makeTable()
            Engine.shared.addProperty(.Double, toTable: tableId)
            Engine.shared.addRandomRowToTable(tableId)
            
            tvc.tableId = tableId
            let container = UIView()
            
            canvas.addSubview(container)
            tvc.willMoveToParentViewController(self)
            container.addSubview(tvc.view)
            addChildViewController(tvc)
            tvc.didMoveToParentViewController(self)
            
            container.translatesAutoresizingMaskIntoConstraints = false
            tvc.view.translatesAutoresizingMaskIntoConstraints = false
            
//            container.backgroundColor = UIColor.redColor()
//            tvc.view.leftAnchor.constraintEqualToAnchor(container.leftAnchor, constant: 10).active = true
//            tvc.view.rightAnchor.constraintEqualToAnchor(container.rightAnchor, constant: -10).active = true
//            tvc.view.topAnchor.constraintEqualToAnchor(container.topAnchor, constant: 10).active = true
//            tvc.view.bottomAnchor.constraintEqualToAnchor(container.bottomAnchor, constant: -10).active = true
            
            tvc.view.leftAnchor.constraintEqualToAnchor(container.leftAnchor).active = true
            tvc.view.rightAnchor.constraintEqualToAnchor(container.rightAnchor).active = true
            tvc.view.topAnchor.constraintEqualToAnchor(container.topAnchor).active = true
            tvc.view.bottomAnchor.constraintEqualToAnchor(container.bottomAnchor).active = true
            
            container.leftAnchor.constraintEqualToAnchor(canvas.leftAnchor, constant: point.x).active = true
            container.topAnchor.constraintEqualToAnchor(canvas.topAnchor, constant: point.y).active = true
            
            veloTables.append(tvc)
        }
    }
    
    // MARK: User actions
    
    @IBAction func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            newTable(sender.locationInView(canvas))
        }
    }

    
    
    @IBAction func tappedButton() {
        scrollView.contentSize.width = scrollView.contentSize.width + 200
        print(scrollView.contentSize)
    }
    
    @IBAction func tappedOtherButton() {
        canvasWidth.constant = canvasWidth.constant + 200
        scrollView.layoutIfNeeded()
        
//        Engine.shared.describe()
        print(scrollView.contentSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.x + scrollView.frame.size.width - scrollView.contentSize.width > 200 {
            scrollView.scrollEnabled = false
            scrollView.scrollEnabled = true
            
            scrollView.contentOffset.x = scrollView.contentOffset.x + 200

            UIView.animateWithDuration(0.2, animations: {
                scrollView.backgroundColor = UIColor.whiteColor()
//                self.canvasWidth.constant = self.canvasWidth.constant + 200
//                scrollView.layoutIfNeeded()
                
                }) { _ in
                    self.canvasWidth.constant = self.canvasWidth.constant + 200
                    scrollView.layoutIfNeeded()
                    scrollView.backgroundColor = UIColor.lightGrayColor()
            }
        }
    
        for veloTable in veloTables {
            if let tableContainer = veloTable.view.superview {
                veloTable.canvasScrolled(scrollView.contentOffset.x - tableContainer.frame.minX)
            }
        }
    }
}