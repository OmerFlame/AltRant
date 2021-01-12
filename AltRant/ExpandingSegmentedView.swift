//
//  ExpandingSegmentedView.swift
//  AltRant
//
//  Created by Omer Shamai on 1/12/21.
//

import UIKit

@IBDesignable class ExpandingSegmentedView: UIView {
    // MARK: - Private Variables And Views
    
    // Main Buttons - (3 calls to 'createSegmentButton')
    private lazy var buttons = [createSegmentButton(), createSegmentButton(), createSegmentButton()]
    
    // Will contain main UIButtons
    lazy var stackView = UIStackView(arrangedSubviews: [])
    
    private var buttonTitles = ["Button", "Button", "Button"]
    private var buttonImages = [UIImage(), UIImage(), UIImage()]
    private var buttonSelectImages = [UIImage(), UIImage(), UIImage()]
    
    private var selectedSegmentIndex = 0
    
    lazy var slideView: UIView = {
        var view = UIView(frame: .zero)
        view.backgroundColor = selectedBackgroundColor
        return view
    }()
    
    // MARK: - Inspectables
    
    @IBInspectable var leftText = "Button" {
        didSet {
            buttons[0].setTitle(leftText, for: .normal)
            buttonTitles[0] = leftText
        }
    }
    
    @IBInspectable var middleText = "Button" {
        didSet {
            buttons[1].setTitle(middleText, for: .normal)
            buttonTitles[1] = middleText
        }
    }
    
    @IBInspectable var rightText = "Button" {
        didSet {
            buttons[2].setTitle(rightText, for: .normal)
            buttonTitles[2] = rightText
        }
    }
    
    @IBInspectable var leftImage = UIImage() {
        didSet {
            buttons[0].setImage(leftImage, for: .normal)
            buttonImages[0] = leftImage
        }
    }
    
    @IBInspectable var middleImage = UIImage() {
        didSet {
            buttons[1].setImage(middleImage, for: .normal)
            buttonImages[1] = middleImage
        }
    }
    
    @IBInspectable var rightImage = UIImage() {
        didSet {
            buttons[2].setImage(rightImage, for: .normal)
            buttonImages[2] = rightImage
        }
    }
    
    @IBInspectable var leftImageSelected = UIImage() {
        didSet {
            buttonSelectImages[0] = leftImageSelected
        }
    }
    
    @IBInspectable var middleImageSelected = UIImage() {
        didSet {
            buttonSelectImages[1] = middleImageSelected
        }
    }
    
    @IBInspectable var rightImageSelected = UIImage() {
        didSet {
            buttonSelectImages[2] = rightImageSelected
        }
    }
    
    @IBInspectable var selectedBackgroundColor = UIColor.blue {
        didSet {
            slideView.backgroundColor = selectedBackgroundColor
        }
    }
    
    @IBInspectable var selectedTextColor = UIColor.white
    
    @IBInspectable var startingIndex = 0
    
    // MARK: - Function Overrides
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupFirstSelection()
    }
    
    // MARK: - Functions
    
    func createSegmentButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 14)
        button.imageEdgeInsets = UIEdgeInsets(left: -15)
        return button
    }
    
    func setupView() {
        buttonTitles = [leftText, middleText, rightText]
        buttonImages = [leftImage, middleImage, rightImage]
        buttonSelectImages = [leftImageSelected, middleImageSelected, rightImageSelected]
        
        for (idx, button) in buttons.enumerated() {
            button.setTitle(buttonTitles[idx], for: .normal)
            
            button.sizeToFit()
            stackView.addArrangedSubview(button)
        }
        
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    func setupFirstSelection() {
        let index = startingIndex
        let newButton = buttons[index]
        newButton.setTitle(buttonTitles[index], for: .normal)
        newButton.setImage(buttonSelectImages[index], for: .normal)
        
        stackView.layoutSubviews()
        slideView.frame = newButton.frame
        slideView.layer.cornerRadius = slideView.frame.height / 2
        
        selectedSegmentIndex = index
    }
    
    func didSelectButton(at index: Int) {
        let oldButton = buttons[selectedSegmentIndex]
        let newButton = buttons[index]
        
        newButton.alpha = 0
        
        oldButton.setImage(buttonImages[selectedSegmentIndex], for: .normal)
        newButton.setImage(buttonSelectImages[index], for: .normal)
        
        UIView.animate(withDuration: 0.1) {
            oldButton.setTitle("", for: .normal)
            newButton.setTitle(self.buttonTitles[index], for: .normal)
            self.stackView.layoutSubviews()
            self.layoutIfNeeded()
            newButton.alpha = 1
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: []) {
            self.slideView.frame = newButton.frame
            self.layoutIfNeeded()
        }
        
        selectedSegmentIndex = index
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
