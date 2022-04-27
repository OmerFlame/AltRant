//
//  AvatarEditorPickerViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import UIKit
//import Haptica
import BadgeControl
import SwiftRant
import SwiftHEXColors

protocol AvatarEditorPickerViewControllerDelegate {
    func editorPickerView(_ editorPickerView: AvatarEditorPickerViewController, didSelectCategory category: AvatarCustomizationResults.AvatarCustomizationType)
    func editorPickerView(_ editorPickerView: AvatarEditorPickerViewController, didSelectOption option: AvatarCustomizationResults.AvatarCustomizationOption)
	func showInsufficientPointsAlert(imageToShow: UIImage, requiredAmount: Int)
}

extension AvatarEditorPickerViewControllerDelegate {
    func editorPickerView(_ editorPickerView: AvatarEditorPickerViewController, didSelectCategory category: AvatarCustomizationResults.AvatarCustomizationType) {
        
    }
    
    func editorPickerView(_ editorPickerView: AvatarEditorPickerViewController, didSelectOption option: AvatarCustomizationResults.AvatarCustomizationOption) {
        
    }
	
	func testAlert(imageToShow: UIImage) {
		
	}
}

class AvatarEditorPickerViewController: UIViewController, UICollectionViewDelegate, UIPopoverPresentationControllerDelegate, TagListViewDelegate {
    @IBOutlet weak var categoryContainerView: UIView!
    @IBOutlet weak var categorySeparatorView: UIView! {
        didSet {
            categorySeparatorView.layer.cornerRadius = categorySeparatorView.frame.height / 2
        }
    }
    
    @IBOutlet weak var secondPreviewView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var disablerView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var categoryPickerContentView: UIView!
    @IBOutlet weak var categoryPickerTagListView: TagListView!
    
	
    //var pickerView: UIPickerView!
	
	var popoverPickerController: UITableViewController!
    
    var types = [AvatarCustomizationResults.AvatarCustomizationType]()
    var preferences = [AvatarCustomizationResults.AvatarCustomizationOption]()
    
    public var portraitSize: CGSize = .zero
    public var landscapeFrame: CGRect = .zero
    
    var selectedIndexPath: IndexPath!
    
    var testImage = UIImage(named: "testheader")!
    
    var delegate: AvatarEditorPickerViewControllerDelegate?
	
	var currentSelectedCategoryRow: Int!
	
	var userPoints: Int!
    
    private var safeAreaAdditionalOffset: CGFloat {
        hasSafeArea ? 20 : 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		collectionView.delegate = self
		collectionView.dataSource = self
        
        categoryPickerTagListView.delegate = self
        
        //categoryPickerButton.tintColor = .label
        
        /*pickerView = UIPickerView()
        
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
		
		currentSelectedCategoryRow = pickerView.selectedRow(inComponent: 0)*/
    }
    
    func updateTypes(types: [AvatarCustomizationResults.AvatarCustomizationType]) {
        self.types = types
        
        var tags = [String]()
        
        for type in self.types {
            tags.append(type.label)
        }
        
        DispatchQueue.main.async {
            self.categoryPickerTagListView.removeAllTags()
            
            self.categoryPickerTagListView.addTags(tags)
            
            self.categoryPickerContentView.frame.size.width = self.categoryPickerTagListView.totalTagViewsWidth
            self.categoryPickerTagListView.frame.size.width = self.categoryPickerTagListView.totalTagViewsWidth
        }
        
        //pickerView.reloadAllComponents()
    }
    
    func updateOptions(options: [AvatarCustomizationResults.AvatarCustomizationOption]) {
		var indexPathsToUpdate = (0 ..< preferences.count).map { IndexPath(row: $0, section: 0) }
		
		preferences = []
		
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: indexPathsToUpdate)
                
                self.preferences = options
                indexPathsToUpdate = (0 ..< options.count).map { IndexPath(row: $0, section: 0) }
                
                self.collectionView.insertItems(at: indexPathsToUpdate)
            }, completion: nil)
            
            self.preferences = options
            
            self.collectionView.reloadData()
        }
    }
    
	/*@IBAction func openPopoverPicker() {
		popoverPickerController = UITableViewController()
		
		popoverPickerController.tableView.backgroundColor = .clear
		let blurEffect = UIBlurEffect(style: .regular)
		let blurEffectView = UIVisualEffectView(effect: blurEffect)
		
		popoverPickerController.tableView.backgroundView = blurEffectView
		popoverPickerController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
		
		popoverPickerController.modalPresentationStyle = .popover
		popoverPickerController.tableView.dataSource = self
		popoverPickerController.tableView.delegate = self
		
		popoverPickerController.preferredContentSize = CGSize(width: 300, height: 220)
		
		let ppc = popoverPickerController.popoverPresentationController
		ppc?.backgroundColor = .clear
		ppc?.permittedArrowDirections = .down
		ppc?.delegate = self
		//ppc?.sourceRect = navigationItem.titleView!.bounds
		ppc?.sourceRect = categoryPickerButton.bounds
		//ppc?.sourceView = navigationItem.titleView!
		ppc?.sourceView = categoryPickerButton
		
		present(popoverPickerController, animated: true, completion: nil)
	}*/
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
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

/*extension AvatarEditorPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    // TODO: - Actually implement the picker data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return types.count
        
        //5
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        150
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        //return "bruh \(row)"
        
        return types[row].label
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: pickerContainerView.frame.width / 2, height: 136))
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        label.text = types[row].label
        label.textAlignment = .center
        
        label.font = UIFont.systemFont(ofSize: 23.50, weight: .regular)
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        view.addSubview(label)
        
        view.transform = CGAffineTransform(rotationAngle: 90 * (.pi / 180))
        
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard row != currentSelectedCategoryRow else { return }
		
		currentSelectedCategoryRow = row
		
        delegate?.editorPickerView(self, didSelectCategory: types[row])
		
		activityIndicator.stopAnimating()
    }
}*/

/*extension AvatarEditorPickerViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		
		cell.textLabel?.text = types[indexPath.row].label
		
		return cell
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		types.count
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.row != currentSelectedCategoryRow else { popoverPickerController.dismiss(animated: true, completion: nil); return }
		
		currentSelectedCategoryRow = indexPath.row
		
		categoryPickerButton.setTitle(types[indexPath.row].label, for: .normal)
		categoryPickerButton.sizeToFit()
		
		popoverPickerController.dismiss(animated: true, completion: { self.delegate?.editorPickerView(self, didSelectCategory: self.types[indexPath.row]) })
	}
}*/

extension AvatarEditorPickerViewController: UICollectionViewDataSource {
    // TODO: - Actaully implement the collection view's data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        preferences.count
        
        //25
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreferenceCell", for: indexPath) as! PreferenceCell
        
		print("CONFIGURING ROW \(indexPath.row)")
		print("SHOULD SHOW LOCK: \(preferences[indexPath.row].requiredPoints ?? 0 <= userPoints ? false : true)")
		
		/*cell.dimView.layer.removeAllAnimations()
		for sublayer in cell.dimView.layer.sublayers ?? [] {
			sublayer.removeFromSuperlayer()
		}*/
		
		
		cell.configure(image: preferences[indexPath.row].image, isAlreadySelected: indexPath == selectedIndexPath ? true : false, shouldShowLock: preferences[indexPath.row].requiredPoints ?? 0 <= userPoints ? false : true, badgeValue: preferences[indexPath.row].requiredPoints ?? 0 <= userPoints ? preferences[indexPath.row].requiredPoints : nil)
        
        /*if preferences[indexPath.row].isSelected ?? false {
            selectedIndexPath = indexPath
        }*/
        
        //cell.configure(image: <#T##AvatarCustomizationImage#>, isAlreadySelected: <#T##Bool#>)
        
        //UIGraphicsBeginImageContextWithOptions(CGSize(width: 112, height: 112), false, CGFloat(testImage.size.height / 112))
        //testImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 112, height: 112)))
        //let newImage = UIGraphicsGetImageFromCurrentImageContext()
        //UIGraphicsEndImageContext()
        
        //cell.imageView.image = newImage
        
        //cell.shouldBeSelected = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //print("THIS RUNS")
        
        guard indexPath != selectedIndexPath else {
            return
        }
		
		guard preferences[indexPath.row].requiredPoints ?? 0 <= userPoints else {
			//delegate?.showInsufficientPointsAlert(imageToShow: (collectionView.cellForItem(at: indexPath) as! PreferenceCell).imageView.image!, requiredAmount: preferences[indexPath.row].requiredPoints ?? 0)
			let insufficientPointsPopupController = UIViewController()
			
			insufficientPointsPopupController.view.backgroundColor = .clear
			let blurEffect = UIBlurEffect(style: .regular)
			let blurEffectView = UIVisualEffectView(effect: blurEffect)
			
			insufficientPointsPopupController.view.addSubview(blurEffectView)
			
			blurEffectView.translatesAutoresizingMaskIntoConstraints = false
			blurEffectView.leadingAnchor.constraint(equalTo: insufficientPointsPopupController.view.leadingAnchor).isActive = true
			blurEffectView.trailingAnchor.constraint(equalTo: insufficientPointsPopupController.view.trailingAnchor).isActive = true
			blurEffectView.topAnchor.constraint(equalTo: insufficientPointsPopupController.view.topAnchor).isActive = true
			blurEffectView.bottomAnchor.constraint(equalTo: insufficientPointsPopupController.view.bottomAnchor).isActive = true
			
			//popoverPickerController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
			
			insufficientPointsPopupController.modalPresentationStyle = .popover
			//popoverPickerController.tableView.dataSource = self
			//popoverPickerController.tableView.delegate = self
			
			let label = UILabel()
			label.font = .preferredFont(forTextStyle: .caption1)
			label.text = "You need \(preferences[indexPath.row].requiredPoints ?? 0)++\'s in order to equip this."
			label.numberOfLines = 0
			label.lineBreakMode = .byWordWrapping
			label.textAlignment = .center
			
			let imageView = UIImageView()
			imageView.image = (collectionView.cellForItem(at: indexPath) as! PreferenceCell).imageView.image!
			imageView.clipsToBounds = true
			imageView.layer.cornerRadius = 15
			
			label.translatesAutoresizingMaskIntoConstraints = false
			imageView.translatesAutoresizingMaskIntoConstraints = false
			
			blurEffectView.contentView.addSubview(imageView)
			blurEffectView.contentView.addSubview(label)
			
			imageView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor, constant: 10).isActive = true
			imageView.widthAnchor.constraint(equalToConstant: 128).isActive = true
			imageView.heightAnchor.constraint(equalToConstant: 128).isActive = true
			imageView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 10).isActive = true
			imageView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -10).isActive = true
			
			let labelSize = label.text!.boundingRect(with: CGSize(width: 128, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)], context: nil).size
			
			label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10).isActive = true
			
			#if targetEnvironment(macCatalyst)
			label.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor, constant: -10).isActive = true
			insufficientPointsPopupController.preferredContentSize = CGSize(width: 148, height: 158 + labelSize.height)
			#else
			label.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor, constant: -20).isActive = true
			insufficientPointsPopupController.preferredContentSize = CGSize(width: 148, height: 187)
			#endif
			label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
			label.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
			label.heightAnchor.constraint(equalToConstant: labelSize.height).isActive = true
			
			let ppc = insufficientPointsPopupController.popoverPresentationController
			ppc?.backgroundColor = .clear
			ppc?.permittedArrowDirections = .down
			ppc?.delegate = self
			//ppc?.sourceRect = navigationItem.titleView!.bounds
			ppc?.sourceRect = collectionView.cellForItem(at: indexPath)!.bounds
			//ppc?.sourceView = navigationItem.titleView!
			ppc?.sourceView = collectionView.cellForItem(at: indexPath)!
			
			present(insufficientPointsPopupController, animated: true, completion: nil)
			
			return
		}
        
		(collectionView.cellForItem(at: selectedIndexPath) as? PreferenceCell)?.shouldBeSelected = false
        
        selectedIndexPath = indexPath
        
        (collectionView.cellForItem(at: selectedIndexPath) as! PreferenceCell).shouldBeSelected = true
        
        delegate?.editorPickerView(self, didSelectOption: preferences[selectedIndexPath.row])
    }
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        for (idx, type) in types.enumerated() {
            if type.label == title {
                self.delegate?.editorPickerView(self, didSelectCategory: self.types[idx])
            }
        }
    }
}

class PreferenceCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var doneAnimationView: DoneAnimationView!
	
	private var upperRightBadge: BadgeController!
	
	var lockLayer: CALayer!
    
    var shouldBeSelected = false {
        didSet {
            if self.shouldBeSelected {
                self.doneAnimationView.removeAnimatableLayer()
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.dimView.alpha = self.shouldBeSelected ? 0.6 : 0
            }, completion: { _ in
                if self.shouldBeSelected {
					self.doneAnimationView.isHidden = false
                    self.doneAnimationView.show()
                    //Haptic.notification(.success).generate()
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
				} else {
					self.doneAnimationView.isHidden = true
				}
            })
        }
    }
	
	override func prepareForReuse() {
		//print("REUSING")
		
		if dimView != nil {
			super.prepareForReuse()
            self.imageView.image = nil
			//print("REUSING")
			
			if lockLayer != nil {
				//print("remove the layer now!")
				lockLayer.removeFromSuperlayer()
			}
		}
	}
    
    var preference: AvatarCustomizationResults.AvatarCustomizationImage!
    
    func configure(image: AvatarCustomizationResults.AvatarCustomizationImage, isAlreadySelected: Bool, shouldShowLock: Bool = false, badgeValue: Int? = nil) {
        preference = image
		imageView.backgroundColor = UIColor(hexString: preference.backgroundColor)!
		
        preference.getMidCompleteImage(shouldUseCache: true, completion: { image in
			DispatchQueue.main.async {
				self.imageView.image = image
			}
		})
		
		//imageView.image = preference.midCompleteImage
		
        if isAlreadySelected {
            dimView.alpha = 0.6
			doneAnimationView.isHidden = false
            doneAnimationView.show(animated: false)
		} else if shouldShowLock {
			if let badgeValue = badgeValue {
				let badgeBackgroundColor = UIColor(hexString: "37495b")!
				
				upperRightBadge = BadgeController(for: self, in: BadgeCenterPosition.upperRightCorner, badgeBackgroundColor: badgeBackgroundColor, badgeTextColor: UIColor.white, borderWidth: 0, badgeHeight: 20)
				upperRightBadge.addOrReplaceCurrent(with: "\(badgeValue)", animated: false)
			}
			
			doneAnimationView.isHidden = true
			dimView.alpha = 0.6
			
			let symbolConfig = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 51), scale: .default)
			
			lockLayer = CALayer()
			lockLayer.frame = CGRect(x: 28, y: 28, width: 54.5, height: 56)
			lockLayer.contentsGravity = .resize
			lockLayer.magnificationFilter = .linear
			
			let maskImage = UIGraphicsImageRenderer(size: CGSize(width: 56, height: 56)).image { (context) in UIImage(systemName: "lock.fill")!.draw(in: CGRect(origin: .zero, size: CGSize(width: 56, height: 56))) }.cgImage
			let width = maskImage!.width
			let height = maskImage!.height
			let bounds = CGRect(x: 0, y: 0, width: width, height: height)
			
			let colorSpace = CGColorSpaceCreateDeviceRGB()
			let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
			let bitmapContext = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
			
			bitmapContext?.clip(to: bounds, mask: maskImage!)
			bitmapContext?.setFillColor(UIColor.white.cgColor)
			bitmapContext?.fill(bounds)
			
			let finalImage = bitmapContext?.makeImage()
			
			lockLayer.contents = finalImage
			
			dimView.layer.addSublayer(lockLayer)
		} else {
			doneAnimationView.removeAnimatableLayer()
			doneAnimationView.isHidden = true
			dimView.alpha = 0
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
    
    public func show(animated: Bool = true) {
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
        animatableLayer.strokeEnd = animated ? 0 : 1
        layer.addSublayer(animatableLayer)
        
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 0.3
            animation.fromValue = 0
            animation.toValue = 1
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animatableLayer.strokeEnd = 1
            animatableLayer.add(animation, forKey: "animation")
        }
    }
	
	public func showLock() {
		/*let imageLayer = CALayer()
		imageLayer.frame = bounds
		imageLayer.contents = UIImage(systemName: "lock.circle")!.cgImage
		
		//layer.addSublayer(imageLayer)
		layer.mask = imageLayer*/
		
		
		//maskView.layer.addSublayer(gradientMask)
		
		/*
		let maskView = UIImageView(frame: CGRect(origin: .zero, size: frame.size))
		maskView.image = UIImage(systemName: "lock.circle")!
		maskView.tintColor = .white
		
		mask = maskView
		*/
		
		let animatablePath = UIBezierPath()
		
		let animatableLayer = CAShapeLayer()
		animatableLayer.path = animatablePath.cgPath
		animatableLayer.fillColor = UIColor(patternImage: UIImage(systemName: "lock.fill")!.withTintColor(.clear, renderingMode: .alwaysTemplate)).cgColor
		animatableLayer.strokeColor = UIColor.white.cgColor //tintColor?.cgColor
		animatableLayer.lineWidth = 9
		animatableLayer.lineCap = .round
		animatableLayer.lineJoin = .round
		animatableLayer.strokeEnd = 1
		layer.addSublayer(animatableLayer)
	}
    
    public func removeAnimatableLayer() {
		// if animatableLayer != nil { print("REMOVING ANIMATABLE LAYER") }
		
		//print("LAYERS: \(layer.sublayers ?? [])")
		
        //animatableLayer?.removeFromSuperlayer()
		
		layer.removeAllAnimations()
		layer.sublayers = []
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
