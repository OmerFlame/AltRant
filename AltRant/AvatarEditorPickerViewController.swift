//
//  AvatarEditorPickerViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import UIKit
import PullUpController

class AvatarEditorPickerViewController: PullUpController {
    
    enum InitialState {
        case contracted
        case expanded
    }
    
    var initialState: InitialState = .contracted
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var categoryContainerView: UIView!
    @IBOutlet weak var categorySeparatorView: UIView! {
        didSet {
            categorySeparatorView.layer.cornerRadius = categorySeparatorView.frame.height / 2
        }
    }
    
    @IBOutlet weak var secondPreviewView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pickerView: UIPickerView! {
        didSet {
            pickerView.transform = CGAffineTransform(rotationAngle: -90 * (.pi / 180))
        }
    }
    
    var initialPointOffset: CGFloat {
        switch initialState {
        case .contracted:
            return (categoryContainerView?.frame.height ?? 0) + safeAreaAdditionalOffset
        case .expanded:
            return pullUpControllerPreferredSize.height
        }
    }
    
    private var categories = [AvatarCustomizationOption]()
    private var preferences = [AvatarCustomizationResult]()
    
    public var portraitSize: CGSize = .zero
    public var landscapeFrame: CGRect = .zero
    
    private var safeAreaAdditionalOffset: CGFloat {
        hasSafeArea ? 20 : 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        portraitSize = CGSize(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: secondPreviewView.frame.maxY)
        landscapeFrame = CGRect(x: 5, y: 50, width: 280, height: 194)
        
        collectionView.attach(to: self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AvatarEditorPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        
        label.textColor = .label
        label.text = categories[row].label
        label.textAlignment = .center
        label.transform = CGAffineTransform(rotationAngle: 90 * (.pi / 180))
        
        return label
    }
}

extension AvatarEditorPickerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        preferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreferenceCell", for: indexPath) as! PreferenceCell
        
        cell.configure(image: preferences[indexPath.row].image, isAlreadySelected: preferences[indexPath.row].isSelected ?? false)
        
        return cell
    }
}

class PreferenceCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var doneAnimationView: DoneAnimationView!
    
    var shouldBeSelected = false {
        didSet {
            UIView.animate(withDuration: 0.4, animations: {
                self.dimView.alpha = self.shouldBeSelected ? 0.6 : 0
            }, completion: { _ in
                self.doneAnimationView.animate()
            })
        }
    }
    
    var preference: AvatarCustomizationImage!
    
    func configure(image: AvatarCustomizationImage, isAlreadySelected: Bool) {
        preference = image
        imageView.image = preference.midCompleteImage
        
        if isAlreadySelected {
            shouldBeSelected = true
        }
        
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPreference)))
    }
    
    @objc func didTapPreference() {
        guard shouldBeSelected else {
            return
        }
        
        shouldBeSelected = true
    }
}

class DoneAnimationView: UIView {
    public func animate() {
            let length = frame.width
            let animatablePath = UIBezierPath()
            animatablePath.move(to: CGPoint(x: length * 0.196, y: length * 0.527))
            animatablePath.addLine(to: CGPoint(x: length * 0.47, y: length * 0.777))
            animatablePath.addLine(to: CGPoint(x: length * 0.99, y: length * 0.25))
            
            let animatableLayer = CAShapeLayer()
            animatableLayer.path = animatablePath.cgPath
            animatableLayer.fillColor = UIColor.clear.cgColor
            animatableLayer.strokeColor = tintColor?.cgColor
            animatableLayer.lineWidth = 9
            animatableLayer.lineCap = .round
            animatableLayer.lineJoin = .round
            animatableLayer.strokeEnd = 0
            layer.addSublayer(animatableLayer)
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 0.3
            animation.fromValue = 0
            animation.toValue = 1
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animatableLayer.strokeEnd = 1
            animatableLayer.add(animation, forKey: "animation")
        }
}
