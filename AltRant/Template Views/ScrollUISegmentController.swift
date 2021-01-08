//
//  ScrollUISegmentController.swift
//  AltRant
//
//  Created by Omer Shamai on 1/4/21.
//

import UIKit

protocol ScrollUISegmentControllerDelegate: class {
    func selectItemAt(index: Int, onScrollUISegmentController scrollUISegmentController: ScrollUISegmentController)
}

@IBDesignable
class ScrollUISegmentController: UIScrollView {
    private var segmentedControl: CustomizableSegmentedControl = CustomizableSegmentedControl()
    
    weak var segmentDelegate: ScrollUISegmentControllerDelegate?
    
    @IBInspectable
    public var segmentTintColor: UIColor = .black {
        didSet {
            self.segmentedControl.tintColor = self.segmentTintColor
        }
    }
    
    @IBInspectable
    public var itemWidth: CGFloat = 75 {
        didSet {
        }
    }
    
    public var segmentFont: UIFont = UIFont.systemFont(ofSize: 13) {
        didSet {
            self.segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: self.segmentFont], for: .normal)
        }
    }
    
    public var itemsCount: Int = 3
    public var segmentheight : CGFloat = 32.0
    
    public var segmentItems: Array = ["1","2","3"] {
        didSet {
            self.itemsCount = segmentItems.count
            self.createSegment()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.createSegment()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSegment()
    }
    
    init(frame: CGRect, andItems items: [String]) {
        super.init(frame: frame)
        self.segmentItems = items
        self.itemsCount = segmentItems.count
        self.createSegment()
    }
    
    func createSegment() {
        self.segmentedControl.removeFromSuperview()
        segmentheight =  self.frame.height
        var width = CGFloat(self.itemWidth * CGFloat(self.itemsCount))
        if width < self.frame.width {
            itemWidth =  CGFloat(self.frame.width) / CGFloat(itemsCount)
             width = CGFloat(self.itemWidth * CGFloat(self.itemsCount))
        }
        self.segmentedControl = CustomizableSegmentedControl(frame: CGRect(x: 0 , y: 0, width: width , height: segmentheight))
        self.addSubview(self.segmentedControl)
        self.backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        //NSLayoutConstraint(item: self.segmentedControl, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        //NSLayoutConstraint(item: self.segmentedControl, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        let contentHeight =  self.frame.height
        self.contentSize = CGSize (width: width, height: contentHeight)
        self.segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: self.segmentFont], for: .normal)
        
        if segmentedControl.gestureRecognizers != nil {
            for gestureRecognizer in segmentedControl.gestureRecognizers! {
                print(String(describing: type(of: gestureRecognizer)))
            }
        }
        
        //self.segmentedControl.removeGestureRecognizer((segmentedControl.gestureRecognizers?.first(where: { String(describing: type(of: $0)) == "UIScrollViewPanGestureRecognizer" }))!)
        self.segmentedControl.tintColor = self.segmentTintColor
        insertItems()
        self.segmentedControl.addTarget(self, action: #selector(segmentChangeSelectedIndex(_:)), for: .valueChanged)
        
        self.segmentedControl.selectedSegmentIndex = 0;
    }
    
    func insertItems() {
        for item in segmentItems {
            segmentedControl.insertSegment(withTitle: item, at: segmentItems.firstIndex(of: item)!, animated: true)
        }
    }
    
    @objc func segmentChangeSelectedIndex(_ sender: AnyObject) {
        segmentDelegate?.selectItemAt(index: self.segmentedControl.selectedSegmentIndex, onScrollUISegmentController: self)
    }
}

class CustomizableSegmentedControl: UISegmentedControl {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) {
            return false
        } else {
            return true
        }
    }
}
