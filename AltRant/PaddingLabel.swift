//
//  PaddingLabel.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 10/30/20.
//

import UIKit

@IBDesignable class PaddingLabel: UILabel {
    @IBInspectable public var topInset: CGFloat = 0
    @IBInspectable public var bottomInset: CGFloat = 0
    @IBInspectable public var leftInset: CGFloat = 0
    @IBInspectable public var rightInset: CGFloat = 0
    
    @IBInspectable public var cornerRadius: CGFloat = 0.0
    
    /*init?(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat, coder: NSCoder) {
        self.topInset = top
        self.bottomInset = bottom
        self.leftInset = left
        self.rightInset = right
        super.init(coder: coder)
    }
    
    init(withInsets top: CGFloat, _ bottom: CGFloat, _ left: CGFloat, _ right: CGFloat) {
        self.topInset = top
        self.bottomInset = bottom
        self.leftInset = left
        self.rightInset = right
        super.init(frame: .zero)
    }*/
    
    /*@available(*, unavailable, renamed: "init(top:bottom:left:right:coder:)")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
        //topInset = coder.decodeObject(forKey: "topInset") as! CGFloat
        //bottomInset = coder.decodeObject(forKey: "bottomInset") as! CGFloat
        //leftInset = coder.decodeObject(forKey: "leftInset") as! CGFloat
        //rightInset = coder.decodeObject(forKey: "rightInset") as! CGFloat
        
        //super.init(frame: .zero)
    }*/
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = cornerRadius
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
}
