//
//  StretchyTableHeaderView.swift
//  AltRant
//
//  Created by Omer Shamai on 12/9/20.
//

import UIKit

@IBDesignable
open class StretchyTableHeaderView: UIView {
    @IBOutlet weak var imageContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var imageContainerBottom: NSLayoutConstraint!
    
    @IBOutlet weak var imageViewBottom: NSLayoutConstraint!
    @IBOutlet weak var imageViewTop: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var largeHeaderTitle: UIStackView!
    @IBOutlet weak var smallHeaderTitle: UIStackView!
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        let nib = UINib(nibName: "StretchyTableHeaderView", bundle: Bundle(for: type(of: self)))
        nib.instantiate(withOwner: self, options: nil)
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled,
              !isHidden,
              alpha >= 0.01,
              let sc = segControl
        else { return nil }
        
        let convertedPoint = sc.convert(point, from: self)
        if let v = sc.hitTest(convertedPoint, with: event) {
            return v
        }
        
        guard self.point(inside: point, with: event) else { return nil }
        
        return self
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        containerViewHeight.constant = scrollView.contentInset.top
        let offsetY = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        
        containerView.clipsToBounds = offsetY <= 0
        imageContainerBottom.constant = offsetY >= 0 ? 0 : -offsetY / 2
        imageContainerHeight.constant = max(offsetY + scrollView.contentInset.top, scrollView.contentInset.top)
        imageContainer.clipsToBounds = offsetY <= 0
        
        imageViewBottom.constant = (offsetY >= 0 ? 0 : -offsetY / 2) - 50
        imageViewTop.constant = (offsetY >= 0 ? 0 : -offsetY / 2) + 50
    }
}
