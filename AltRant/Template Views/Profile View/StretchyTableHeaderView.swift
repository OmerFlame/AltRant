//
//  StretchyTableHeaderView.swift
//  AltRant
//
//  Created by Omer Shamai on 12/9/20.
//

import UIKit
import SwiftHEXColors

/*class StretchyTableHeaderView: UIView {
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
    
    /*required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews() {
        let nib = UINib(nibName: "StretchyTableHeaderView", bundle: .main)
        nib.instantiate(withOwner: self, options: nil)
        addSubview(containerView)
    }*/
    
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
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
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "StretchyTableHeaderView", bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
*/

class StretchyTableHeaderView: UIView {
    var imageContainerHeight = NSLayoutConstraint()
    var imageContainerBottom = NSLayoutConstraint()
        
    var imageViewHeight = NSLayoutConstraint()
    var imageViewBottom = NSLayoutConstraint()
    var imageViewTop = NSLayoutConstraint()
        
        
    var containerView: UIView!
    var imageContainer: UIView!
    var imageView: UIImageView!
        
    var largeTitleOpacity = Double()
    var tinyTitleOpacity = Double()
        
    var largeLabel: UILabel!
    var tinyLabel: UILabel!
    
    var maskBlurView: UIVisualEffectView!
        
    var containerViewHeight = NSLayoutConstraint()
        
    var stack: UIStackView!
        
        //var title: StretchyHeaderTitle!
        
    weak var segControl: UISegmentedControl?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
            
        createViews()
            
        setViewConstraints()
            
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
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
    
    func setMaskBlurView(newBlurView: UIVisualEffectView!) {
        if maskBlurView != nil {
            maskBlurView.removeFromSuperview()
        }
        
        maskBlurView = newBlurView
        
        imageContainer.addSubview(maskBlurView)
        
        maskBlurView.translatesAutoresizingMaskIntoConstraints = false
        maskBlurView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor).isActive = true
        maskBlurView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor).isActive = true
        maskBlurView.topAnchor.constraint(equalTo: imageContainer.topAnchor).isActive = true
        maskBlurView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor).isActive = true
    }
        
    func createViews() {
            
        // Container View
        containerView = UIView()
        //containerView.backgroundColor = UIColor(hexString: "d55161")
        self.addSubview(containerView)
            
        imageContainer = UIView()
        //imageContainer.backgroundColor = UIColor(hexString: "d55161")
        //imageContainer.contentMode = .scaleAspectFill
        imageContainer.clipsToBounds = true
        containerView.addSubview(imageContainer)
        
        // ImageView for background
        imageView = UIImageView()
        //imageView.clipsToBounds = true
        //imageView.backgroundColor = UIColor(hexString: "d55161")
        imageView.contentMode = .scaleAspectFill
        imageContainer.addSubview(imageView)
        
        //maskBlurView = UINavigationBar().visualEffectView?.copyView()
        //imageContainer.addSubview(maskBlurView)
    }
        
    func setViewConstraints() {
        // UIView Constraints
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            self.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            self.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])
        
        // Container View Constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.widthAnchor.constraint(equalTo: imageContainer.widthAnchor).isActive = true
        containerViewHeight = containerView.heightAnchor.constraint(equalTo: self.heightAnchor)
        containerViewHeight.isActive = true
        
        // ImageView Constraints
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainerBottom = imageContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        imageContainerBottom.isActive = true
        imageContainerHeight = imageContainer.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        imageContainerHeight.isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageViewBottom = imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: -50)
        //imageViewBottom = imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: -100)
        
        imageViewBottom.isActive = true
        
        imageViewTop = imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 50)
        //imageViewTop = imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 100)
        
        imageViewTop.isActive = true
        
        imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor).isActive = true
        
        //maskBlurView.translatesAutoresizingMaskIntoConstraints = false
        //maskBlurView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor).isActive = true
        //maskBlurView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor).isActive = true
        //maskBlurView.topAnchor.constraint(equalTo: imageContainer.topAnchor).isActive = true
        //maskBlurView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor).isActive = true
    }
        
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //imageViewHeight.constant = max(offsetY + scrollView.contentInset.top, scrollView.contentInset.top) - 100
        
        containerViewHeight.constant = scrollView.contentInset.top
        let offsetY = -(scrollView.contentOffset.y + scrollView.contentInset.top)
        
        containerView.clipsToBounds = offsetY <= 0
        imageContainerBottom.constant = offsetY >= 0 ? 0 : -offsetY / 2
        imageContainerHeight.constant = max(offsetY + scrollView.contentInset.top, scrollView.contentInset.top)
        imageContainer.clipsToBounds = offsetY <= 0
        
        
        imageViewBottom.constant = (offsetY >= 0 ? 0 : -offsetY / 2) - 50
        //imageViewBottom.constant = (offsetY >= 0 ? 0 : -offsetY / 2) - 100
        
        imageViewTop.constant = (offsetY >= 0 ? 0 : -offsetY / 2) + 50
        //imageViewTop.constant = (offsetY >= 0 ? 0 : -offsetY / 2) + 100
        
        //imageViewHeight.constant = max(offsetY + scrollView.contentInset.top, scrollView.contentInset.top) - 100
    }
}
