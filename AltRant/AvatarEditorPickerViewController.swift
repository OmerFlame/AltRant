//
//  AvatarEditorPickerViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import UIKit
import Haptica

class AvatarEditorPickerViewController: UIViewController, UICollectionViewDelegate {
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var categoryContainerView: UIView!
    @IBOutlet weak var categorySeparatorView: UIView! {
        didSet {
            categorySeparatorView.layer.cornerRadius = categorySeparatorView.frame.height / 2
        }
    }
    
    @IBOutlet weak var secondPreviewView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pickerContainerView: UIView!
    
    var pickerView: UIPickerView!
    
    private var categories = [AvatarCustomizationOption]()
    private var preferences = [AvatarCustomizationResult]()
    
    public var portraitSize: CGSize = .zero
    public var landscapeFrame: CGRect = .zero
    
    var testImage = UIImage(named: "testheader")!
    
    private var safeAreaAdditionalOffset: CGFloat {
        hasSafeArea ? 20 : 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView = UIPickerView()
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.transform = CGAffineTransform(rotationAngle: -90 * (.pi / 180))
        pickerView.delegate = self
        pickerView.dataSource = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        pickerContainerView.addSubview(pickerView)
        pickerView.widthAnchor.constraint(equalToConstant: 56).isActive = true
        pickerView.heightAnchor.constraint(equalToConstant: pickerContainerView.frame.width).isActive = true
        
        pickerView.centerXAnchor.constraint(equalTo: pickerContainerView.centerXAnchor).isActive = true
        pickerView.centerYAnchor.constraint(equalTo: pickerContainerView.centerYAnchor).isActive = true
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
    // TODO: - Actually implement the picker data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //return categories.count
        
        5
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        70
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return "bruh \(row)"
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: pickerContainerView.frame.width / 2, height: 56))
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        label.text = "bruh \(row)"
        label.textAlignment = .center
        
        label.font = UIFont.systemFont(ofSize: 23.50, weight: .regular)
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        view.addSubview(label)
        
        view.transform = CGAffineTransform(rotationAngle: 90 * (.pi / 180))
        
        return view
    }
}

extension AvatarEditorPickerViewController: UICollectionViewDataSource {
    // TODO: - Actaully implement the collection view's data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //preferences.count
        
        25
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreferenceCell", for: indexPath) as! PreferenceCell
        
        //cell.configure(image: preferences[indexPath.row].image, isAlreadySelected: preferences[indexPath.row].isSelected ?? false)
        
        //cell.configure(image: <#T##AvatarCustomizationImage#>, isAlreadySelected: <#T##Bool#>)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 112, height: 112), false, CGFloat(testImage.size.height / 112))
        testImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 112, height: 112)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        cell.imageView.image = newImage
        
        cell.shouldBeSelected = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("THIS RUNS")
        
        (collectionView.cellForItem(at: indexPath) as! PreferenceCell).shouldBeSelected.toggle()
        
        
    }
}

class PreferenceCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var doneAnimationView: DoneAnimationView!
    
    var shouldBeSelected = false {
        didSet {
            if self.shouldBeSelected {
                self.doneAnimationView.removeAnimatableLayer()
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.dimView.alpha = self.shouldBeSelected ? 0.6 : 0
            }, completion: { _ in
                if self.shouldBeSelected {
                    self.doneAnimationView.animate()
                    Haptic.notification(.success).generate()
                }
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
    }
    
    @objc func didTapPreference() {
        print("TEST")
        
        guard !shouldBeSelected else {
            return
        }
        
        shouldBeSelected = true
    }
}

// I must give credit where credit is due: THIS CLASS IS NOT MINE, I DIDN'T WRITE IT!
// This is made by ivanvorobei on GitHub, in his package SPAlert https://github.com/ivanvorobei/SPAlert/blob/master/Sources/SPAlert/Icons/SPAlertIconDoneView.swift
// I didn't need the full package so I just copied the code I needed into the app.
class DoneAnimationView: UIView {
    private var animatableLayer: CAShapeLayer!
    
    public func animate() {
        let length = frame.width
        let animatablePath = UIBezierPath()
        animatablePath.move(to: CGPoint(x: length * 0.196, y: length * 0.527))
        animatablePath.addLine(to: CGPoint(x: length * 0.47, y: length * 0.777))
        animatablePath.addLine(to: CGPoint(x: length * 0.99, y: length * 0.25))
            
        animatableLayer = CAShapeLayer()
        animatableLayer.path = animatablePath.cgPath
        animatableLayer.fillColor = UIColor.clear.cgColor
        animatableLayer.strokeColor = UIColor.white.cgColor //tintColor?.cgColor
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
    
    public func removeAnimatableLayer() {
        animatableLayer?.removeFromSuperlayer()
    }
}

class CenterViewFlowLayout: UICollectionViewFlowLayout {
    override var collectionViewContentSize: CGSize {
        let count = self.collectionView?.dataSource?.collectionView(self.collectionView!, numberOfItemsInSection: 0)
        let canvasSize = self.collectionView!.frame.size
        var contentSize = canvasSize
        if self.scrollDirection == UICollectionView.ScrollDirection.horizontal {
            let rowCount = Int((canvasSize.height - self.itemSize.height) / (self.itemSize.height + self.minimumInteritemSpacing) + 1)
            let columnCount = Int((canvasSize.width - self.itemSize.width) / (self.itemSize.width + self.minimumLineSpacing) + 1)
            let page = ceilf(Float(count!) / Float(rowCount * columnCount))
            contentSize.width = CGFloat(page) * canvasSize.width
        }
        return contentSize
    }
    
    func frameForItemAtIndexPath(indexPath: IndexPath) -> CGRect {
        let canvasSize = self.collectionView!.frame.size
        let rowCount = Int((canvasSize.height - self.itemSize.height) / (self.itemSize.height + self.minimumInteritemSpacing) + 1)
        let columnCount = Int((canvasSize.width - self.itemSize.width) / (self.itemSize.width + self.minimumLineSpacing) + 1)
        
        let pageMarginX = (canvasSize.width - CGFloat(columnCount) * self.itemSize.width - (columnCount > 1 ? CGFloat(columnCount - 1) * self.minimumLineSpacing : 0)) / 2.0
        let pageMarginY = (canvasSize.height - CGFloat(rowCount) * self.itemSize.height - (rowCount > 1 ? CGFloat(rowCount - 1) * self.minimumInteritemSpacing : 0)) / 2.0
        
        let page = Int(CGFloat(indexPath.row) / CGFloat(rowCount * columnCount))
        let remainder = Int(CGFloat(indexPath.row) - CGFloat(page) * CGFloat(rowCount * columnCount))
        let row = Int(CGFloat(remainder) / CGFloat(columnCount))
        let column = Int(CGFloat(remainder) - CGFloat(row) * CGFloat(columnCount))
        
        var cellFrame = CGRect.zero
        cellFrame.origin.x = pageMarginX + CGFloat(column) * (self.itemSize.width + self.minimumLineSpacing)
        cellFrame.origin.y = pageMarginY + CGFloat(row) * (self.itemSize.height + self.minimumInteritemSpacing)
        cellFrame.size.width = self.itemSize.width
        cellFrame.size.height = self.itemSize.height
        
        if self.scrollDirection == UICollectionView.ScrollDirection.horizontal {
            cellFrame.origin.x += CGFloat(page) * canvasSize.width
        }
        
        return cellFrame
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = super.layoutAttributesForItem(at: indexPath as IndexPath)?.copy() as! UICollectionViewLayoutAttributes?
        //attr!.frame = self.frameForItemAtIndexPath(indexPath: indexPath)
        attr!.frame = self.frameForItemAtIndexPath(indexPath: indexPath)
        return attr
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let originAttrs = super.layoutAttributesForElements(in: rect)
        var attrs: [UICollectionViewLayoutAttributes]? = Array()
        
        for attr in originAttrs! {
            let idxPath = attr.indexPath
            let itemFrame = self.frameForItemAtIndexPath(indexPath: idxPath)
            if itemFrame.intersects(rect) {
                let nAttr = self.layoutAttributesForItem(at: idxPath)
                attrs?.append(nAttr!)
            }
        }
        
        return attrs
    }
    
}
