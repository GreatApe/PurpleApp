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
    
    private var veloTables = [TabulaViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        Engine.shared.createRandomCollection()
        
//        let id = Engine.shared.createRandomCollection()
//        let cats = Engine.shared.getCategories(id)
//        let size = cats.map { $0.count }
//        let tensor = Tensor(size: size)
//        
//        func pp(s: Slice, t: Tensor) {
//            print("Coords of \(s.slicing): \(t.coords(s).map(t.linearise))")
//        }
    }
    
    func newTabula(point: CGPoint) -> TabulaViewController {
        let tabula = storyboard!.instantiateViewControllerWithIdentifier("Tabula") as! TabulaViewController
            let container = UIView()
            
            canvas.addSubview(container)
            tabula.willMoveToParentViewController(self)
            container.addSubview(tabula.view)
            addChildViewController(tabula)
            tabula.didMoveToParentViewController(self)

            container.frame = CGRect(origin: point, size: CGSize(width: 800, height: 500))
            tabula.view.frame = container.bounds
            
//            container.translatesAutoresizingMaskIntoConstraints = false
//            tvc.view.translatesAutoresizingMaskIntoConstraints = false
            
            container.backgroundColor = UIColor.redColor()
//            tvc.view.leftAnchor.constraintEqualToAnchor(container.leftAnchor, constant: 10).active = true
//            tvc.view.rightAnchor.constraintEqualToAnchor(container.rightAnchor, constant: -10).active = true
//            tvc.view.topAnchor.constraintEqualToAnchor(container.topAnchor, constant: 10).active = true
//            tvc.view.bottomAnchor.constraintEqualToAnchor(container.bottomAnchor, constant: -10).active = true
            
//            tvc.view.leftAnchor.constraintEqualToAnchor(container.leftAnchor).active = true
//            tvc.view.rightAnchor.constraintEqualToAnchor(container.rightAnchor).active = true
//            tvc.view.topAnchor.constraintEqualToAnchor(container.topAnchor).active = true
//            tvc.view.bottomAnchor.constraintEqualToAnchor(container.bottomAnchor).active = true
//            
//            container.leftAnchor.constraintEqualToAnchor(canvas.leftAnchor, constant: point.x).active = true
//            container.topAnchor.constraintEqualToAnchor(canvas.topAnchor, constant: point.y).active = true
            
            veloTables.append(tabula)

        return tabula
    }
    
    // MARK: User actions
    
    @IBAction func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            let tabula = newTabula(sender.locationInView(canvas))
            
//            tabula.collectionId = Engine.shared.createRandomCollection()
            
            if let list = storyboard?.instantiateViewControllerWithIdentifier("CollectionList") as? CollectionListViewController {
                list.modalPresentationStyle = .FormSheet
                list.collections = Engine.shared.getList()
                
                list.onSelection = { collectionId in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    tabula.collectionId = collectionId
                    tabula.collectionIndex = [0, 0, 0]
                    tabula.reload()
                }
                
                presentViewController(list, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func tappedButton() {
        veloTables.forEach { tabula in
            tabula.collectionIndex = [0, 0, 0]
            tabula.reload()
//            tabula.addRow(1)
        }
    }
    
    @IBAction func tappedOtherButton() {
        veloTables.forEach { tabula in
            tabula.collectionIndex = [0, 1, 0]
            tabula.reload()

//            tabula.deleteRow(1)
        }
    }
    
    @IBAction func tappedThirdButton() {
        veloTables.forEach { tabula in
            tabula.collectionIndex = [1, 2, 3]
            tabula.reload()

//            tabula.addColumn(1)
        }
    }

    @IBAction func tappedFourthButton() {
        veloTables.forEach { tabula in
//            tabula.deleteColumn(1)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
//        if scrollView.dragging && scrollView.contentOffset.x + scrollView.frame.size.width - scrollView.contentSize.width > 100 {
//            scrollView.scrollEnabled = false
//            scrollView.scrollEnabled = true
//            scrollView.contentOffset.x = scrollView.contentOffset.x + 100
//
//            let newOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y)
//            scrollView.setContentOffset(newOffset, animated: false)
//
//            UIView.animateWithDuration(0.2, animations: {
//                scrollView.backgroundColor = UIColor.whiteColor()
//                }) { _ in
//                    self.canvasWidth.constant = self.canvasWidth.constant + scrollView.frame.size.width
//                    scrollView.layoutIfNeeded()
//                    scrollView.backgroundColor = UIColor.lightGrayColor()
//            }
//        }
//        
//        for veloTable in veloTables {
//            if let tableContainer = veloTable.view.superview {
//                veloTable.canvasScrolled(scrollView.contentOffset.x - tableContainer.frame.minX)
//            }
//        }
    }
}
