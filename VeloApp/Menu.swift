//
//  Menu.swift
//  VeloApp
//
//  Created by Gustaf Kugelberg on 04/03/16.
//  Copyright © 2016 purple. All rights reserved.
//

import UIKit

class MenuBar: UIView {
    var dropDowns = [DropDown]()
    
    @IBOutlet weak var barHeight: NSLayoutConstraint!
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        guard dropDowns.contains({ $0.frame.contains(point) }) else {
            dropDowns.forEach { $0.collapse() }
            return false
        }
        
        return true
    }
    
    func addDropDown(dropDown: DropDown) {
        dropDown.bar = self
        addSubview(dropDown)
        dropDown.tag = dropDowns.count
        dropDowns.append(dropDown)
    }
    
    func expanded(dropDown: DropDown) {
        dropDowns.filter { $0.expanded && $0.tag != dropDown.tag }.forEach { $0.collapse() }
        updateHeight()
    }
    
    func collapsed(dropDown: DropDown) {
        updateHeight()
    }
    
    private func updateHeight() {
        barHeight.constant = dropDowns.contains { $0.expanded } ? superview!.frame.height : 40
        layoutIfNeeded()
    }
}

class DropDown: UIView {
    typealias Item = (text: String, image: UIImage?, selectable: Bool)
    
    // MARK: Public variables
    
    var selection: Int? { didSet { update() } }
    var expanded = false
    
    weak var bar: MenuBar?
    
    // MARK: Private variables
    
    private var size: CGSize
    private var shouldSelectAction: (DropDown, Int) -> Bool
    private var buttons = [(btn: UIButton, hide: Bool)]()
    
    // MARK: Public methods
    
    func hide(index: Int) {
        buttons[index].hide = true
    }
    
    func show(index: Int) {
        buttons[index].hide = false
    }
    
    init(frame: CGRect, items: [Item], shouldSelectAction: (DropDown, Int) -> Bool) {
        self.size = frame.size
        self.shouldSelectAction = shouldSelectAction
        super.init(frame: frame)
        items.forEach(addItem)
        backgroundColor = UIColor.menu()
        layer.cornerRadius = 3
        collapse()
    }
    
    // MARK: Private methods
    
    func boldString(text: String) -> NSAttributedString {
        let attrs = [NSFontAttributeName : UIFont.boldSystemFontOfSize(17), NSForegroundColorAttributeName : UIColor.whiteColor()]
        return NSMutableAttributedString(string:text, attributes:attrs)
    }
    
    func normalString(text: String) -> NSAttributedString {
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(17), NSForegroundColorAttributeName : UIColor.whiteColor()]
        return NSMutableAttributedString(string:text, attributes:attrs)
    }
    
    private func addItem(item: Item) {
        let button = UIButton()
        button.frame.size = self.frame.size
        button.addTarget(self, action: "tappedButton:", forControlEvents: .TouchUpInside)
        button.setAttributedTitle(normalString(item.text), forState: .Normal)
        button.setAttributedTitle(boldString(item.text), forState: .Selected)
        button.imageView?.image = item.image
        button.tag = buttons.count
        button.backgroundColor = UIColor.menu()
        button.opaque = true
//        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
//        button.setTitleColor(UIColor.whiteColor(), forState: .Selected)
        button.layer.cornerRadius = 3
        buttons.append((button, false))
        self.addSubview(button)
    }
    
    func tappedButton(sender: UIButton!) {
        if expanded {
            if shouldSelectAction(self, sender.tag) {
                selection = sender.tag
            }
            
            collapse()
        }
        else {
            expand()
        }
    }
    
    private func update() {
        for (index, button) in self.buttons.enumerate() {
            button.btn.layer.zPosition = 100 + (index == selection ? 10 : 0) + (index == 0 ? 5 : 0)
            button.btn.selected = button.btn.tag == selection
        }
    }
    
    private func expand() {
        guard !expanded else { return }

        let visibleButtons = buttons.filter({ !$0.hide })
        
        UIView.animateWithDuration(0.1) {
            for (index, button) in visibleButtons.enumerate() {
                button.btn.frame.origin.y = CGFloat(index)*self.size.height
            }
            self.frame.size.height = CGFloat(visibleButtons.count)*self.size.height
        }
        expanded = true
        bar?.expanded(self)
    }
    
    private func collapse() {
        guard expanded else { return }
        
        UIView.animateWithDuration(0.1) {
            for button in self.buttons {
                button.btn.frame.origin.y = 0
            }
            
            self.frame.size.height = self.size.height
        }
        update()
        expanded = false
        bar?.collapsed(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
