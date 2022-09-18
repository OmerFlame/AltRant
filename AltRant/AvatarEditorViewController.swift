//
//  AvatarEditorViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import UIKit
import SwiftRant
import SwiftHEXColors

class AvatarEditorViewController: UIViewController, AvatarEditorPickerViewControllerDelegate {
    //private var originalPullUpControllerViewSize: CGSize = .zero
    @IBOutlet weak var currentAvatarImageContainer: UIView!
    @IBOutlet weak var currentAvatarImageView: UIImageView!
    //var fpc: FloatingPanelController!
    
    var pickerViewController: AvatarEditorPickerViewController!
    
    var customizationResults: AvatarCustomizationResults!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		let buttonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))
		
		navigationItem.rightBarButtonItems = [buttonItem]
		
        //addPullUpController()
        
        //addPickerController()
        
        //(fpc.contentViewController as! AvatarEditorPickerViewController).delegate = self
        
        UIView.animate(withDuration: 0.3, animations: {
            self.pickerViewController.disablerView.isHidden = false
            self.pickerViewController.disablerView.alpha = 0.7
        }, completion: { _ in
            self.pickerViewController.activityIndicator.startAnimating()
        })
        
        // TODO: - Ask for the current image while initializing the class, don't get it manually
        SwiftRant.shared.getProfileFromID(SwiftRant.shared.tokenFromKeychain!.authToken.userID, token: nil, userContentType: .rants, skip: 0, completionHandler: { [weak self] result in
            if case .success(let result) = result {
                SwiftRant.shared.getAvatarCustomizationOptions(nil, type: "g", subType: nil, currentImageID: result.avatar.avatarImage!, shouldGetPossibleOptions: true) { [weak self] customizationResult in
                    self?.customizationResults = try? customizationResult.get()
                    
                    if let options = self?.customizationResults.avatars {
                        DispatchQueue.main.async {
                            self?.currentAvatarImageView.backgroundColor = UIColor(hexString: self?.customizationResults.avatars.first(where: { $0.isSelected ?? false })!.image.backgroundColor ?? "")
                            self?.currentAvatarImageContainer.backgroundColor = UIColor(hexString: self?.customizationResults.avatars.first(where: { $0.isSelected ?? false })!.image.backgroundColor ?? "")
                        }
                        
                        //self?.currentAvatarImageView.image = self?.customizationResults.avatars.first(where: { ($0.isSelected ?? false) })?.image
                        
                        /*Task {
                            self?.currentAvatarImageView.image = await UIImage().loadFromWeb(url: self?.customizationResults.avatars.first(where: { $0.isSelected ?? false })?.image.)
                        }*/
                        
                        self?.customizationResults.avatars.first(where: { $0.isSelected ?? false })?.image.getFullImage(shouldUseCache: true) { [weak self] image in
                            DispatchQueue.main.async {
                                self?.currentAvatarImageView.image = image
                            }
                        }
                        
                        self?.pickerViewController.userPoints = result.score
                        self?.pickerViewController.selectedIndexPath = IndexPath(row: self?.customizationResults.avatars.firstIndex(where: { $0.isSelected ?? false })! ?? 0, section: 0)
                        self?.pickerViewController.updateTypes(types: self?.customizationResults.types ?? [])
                        self?.pickerViewController.updateOptions(options: options)
                        
                        DispatchQueue.main.async {
                            //self?.pickerViewController.categoryPickerButton.setTitle(self?.customizationResults.types?[0].label, for: .normal)
                            //self?.pickerViewController.categoryPickerButton.sizeToFit()
                            self?.pickerViewController.categoryPickerTagListView.tagViews[0].isSelected = true
                            
                            self?.pickerViewController.activityIndicator.stopAnimating()
                            
                            UIView.animate(withDuration: 0.3, animations: {
                                self?.pickerViewController.disablerView.alpha = 0
                                self?.pickerViewController.disablerView.isHidden = true
                            })
                        }
                    }
                }
            }
        })
        /*APIRequest().getProfileFromID(UserDefaults.standard.integer(forKey: "DRUserID"), userContentType: .rants, skip: 0, completionHandler: { result in
            
            APIRequest().getAvatarCustomizationOptions(option: "g", subOption: nil, currentImageURL: result!.profile.avatar.i!, shouldGetPossibleOptions: true, completionHandler: { customizationResults in
                self.customizationResults = customizationResults
                
                if let options = self.customizationResults.options {
                    DispatchQueue.main.async {
                        
						self.currentAvatarImageView.backgroundColor = UIColor(hexString: self.customizationResults.avatars.first(where: { $0.isSelected ?? false })!.image.backgroundColor)
						
                        //self.currentAvatarImageView.image = self.customizationResults.avatars.first(where: { ($0.isSelected ?? false) })?.image.fullImage
						
						self.customizationResults.avatars.first(where: { $0.isSelected ?? false })!.image.getFullImage(completion: { image in
							DispatchQueue.main.async {
								self.currentAvatarImageView.image = image
							}
						})
						
						(self.fpc.contentViewController as! AvatarEditorPickerViewController).userPoints = result?.profile.score
                        (self.fpc.contentViewController as! AvatarEditorPickerViewController).selectedIndexPath = IndexPath(row: self.customizationResults.avatars.firstIndex(where: { ($0.isSelected ?? false) })!, section: 0)
                        (self.fpc.contentViewController as! AvatarEditorPickerViewController).updateOptions(options: options)
                        (self.fpc.contentViewController as! AvatarEditorPickerViewController).updateImages(images: self.customizationResults.avatars)
						
						(self.fpc.contentViewController as! AvatarEditorPickerViewController).categoryPickerButton.setTitle(options[0].label, for: .normal)
						(self.fpc.contentViewController as! AvatarEditorPickerViewController).categoryPickerButton.sizeToFit()
                        
                        (self.fpc.contentViewController as! AvatarEditorPickerViewController).activityIndicator.stopAnimating()
                        
                        UIView.animate(withDuration: 0.3, animations: {
                            (self.fpc.contentViewController as! AvatarEditorPickerViewController).disablerView.alpha = 0
                            (self.fpc.contentViewController as! AvatarEditorPickerViewController).disablerView.isHidden = true
                        })
                    }
                }
            })
        })*/
    }
	
	@objc func save() {
		navigationController?.navigationBar.isUserInteractionEnabled = false
		navigationController?.navigationBar.tintColor = .systemGray
		
		navigationController?.interactivePopGestureRecognizer?.isEnabled = false
		
		let imageName = pickerViewController.preferences[pickerViewController.selectedIndexPath.row].image.fullImageName
		
        
        
        SwiftRant.shared.confirmAvatarCustomization(nil, fullImageID: "https://avatars.devrant.com/\(imageName)", completionHandler: { [weak self] result in
            if case .success() = result {
				DispatchQueue.main.async {
					self?.navigationController?.navigationBar.isUserInteractionEnabled = true
					self?.navigationController?.navigationBar.tintColor = .systemBlue
					
					self?.navigationController!.popViewController(animated: true)
				}
            } else if case .failure(let failure) = result {
                let alert = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
				
				let retryAction = UIAlertAction(title: "Retry", style: .default, handler: { _ in self?.save() })
				let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
				
				alert.addAction(retryAction)
				alert.addAction(cancelAction)
				
				DispatchQueue.main.async {
					self?.navigationController?.navigationBar.isUserInteractionEnabled = true
					self?.navigationController?.navigationBar.tintColor = .systemBlue
					
					self?.present(alert, animated: true, completion: nil)
				}
			}
		})
	}
	
	/*func showInsufficientPointsAlert(imageToShow: UIImage, requiredAmount: Int) {
		
		let margin:CGFloat = 10.0
		let rect = CGRect(x: 134.5 - 64, y: margin, width: 128, height: 128)
		let imageView = UIImageView(frame: rect)
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 15
		
		imageView.image = imageToShow
		
		let customView = UIView()
		customView.backgroundColor = .red
		
		customView.translatesAutoresizingMaskIntoConstraints = false
		customView.heightAnchor.constraint(equalToConstant: 128).isActive = true
		
		customView.addSubview(imageView)
		
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.heightAnchor.constraint(equalToConstant: 128).isActive = true
		imageView.widthAnchor.constraint(equalToConstant: 128).isActive = true
		imageView.centerXAnchor.constraint(equalTo: customView.centerXAnchor).isActive = true
		imageView.centerYAnchor.constraint(equalTo: customView.centerYAnchor).isActive = true
		
		let alertController = UIAlertController(title: "You need \(requiredAmount) ++\'s in order to equip this.", customView: customView, fallbackMessage: "You need \(requiredAmount) ++\'s in order to equip this.", preferredStyle: .actionSheet)
		
		//alertController.view.addSubview(customView)
		
		//printRecursiveViewSearch(parentView: alertController.view)
		
		//customView.translatesAutoresizingMaskIntoConstraints = false
		//customView.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: label!.frame.height + margin).isActive = true
		//customView.centerXAnchor.constraint(equalTo: customView.superview!.centerXAnchor).isActive = true
		//customView.heightAnchor.constraint(equalToConstant: 128).isActive = true
		//customView.widthAnchor.constraint(equalToConstant: 128).isActive = true
		
		//alertController.view.translatesAutoresizingMaskIntoConstraints = false
		//alertController.view.heightAnchor.constraint(equalToConstant: 255).isActive = true

		//let somethingAction = UIAlertAction(title: "Something", style: .default, handler: {(alert: UIAlertAction!) in print("something")})

		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

		//alertController.addAction(somethingAction)
		alertController.addAction(cancelAction)
		
		alertController.modalPresentationStyle = .automatic
		
		if let popoverController = alertController.popoverPresentationController {
			popoverController.sourceView = currentAvatarImageView
			popoverController.sourceRect = CGRect(x: currentAvatarImageView.frame.midX, y: currentAvatarImageView.frame.midY, width: 0, height: 0)
			popoverController.permittedArrowDirections = [.down]
		}

		self.present(alertController, animated: true, completion: nil)
		
		print(alertController.view.debugDescription)
	}*/
	
	func showInsufficientPointsAlert(imageToShow: UIImage, requiredAmount: Int) {
		let imageView = UIImageView(frame: CGRect(x: 220, y: 10, width: imageToShow.size.width, height: imageToShow.size.height))
		
		let alertMessage = UIAlertController(title: "My Title", message: "", preferredStyle: .alert)
		
		let action = UIAlertAction(title: "OK", style: .default, handler: nil)
		action.setValue(imageToShow, forKey: "image")
		action.isEnabled = false
		alertMessage.addAction(action)
		
		alertMessage.modalPresentationStyle = .automatic
		
		if let popoverController = alertMessage.popoverPresentationController {
			popoverController.sourceView = currentAvatarImageView
			popoverController.sourceRect = CGRect(x: currentAvatarImageView.frame.midX, y: currentAvatarImageView.frame.midY, width: 0, height: 0)
			popoverController.permittedArrowDirections = [.down]
		}

		self.present(alertMessage, animated: true, completion: nil)
		alertMessage.view.addSubview(imageView)
	}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedSegue" {
            if let childVC = segue.destination as? AvatarEditorPickerViewController {
                pickerViewController = childVC
                pickerViewController.delegate = self
            }
        }
    }
    
    /*func addPickerController() {
        let pickerController = UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarPicker") as! AvatarEditorPickerViewController
        
        pickerController.delegate = self
        
        addChild(pickerController)
        
        view.addSubview(pickerController.view)
        
        pickerController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pickerController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pickerController.view.topAnchor.constraint(equalTo: currentAvatarImageView.bottomAnchor).isActive = true
        pickerController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        pickerController.didMove(toParent: self)
        
        pickerViewController = pickerController
    }*/
    
    /*func addPullUpController() {
        fpc = FloatingPanelController()
        
        let contentVC = UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarPicker") as! AvatarEditorPickerViewController
        
        
        
        fpc.set(contentViewController: contentVC)
        
        fpc.delegate = self
        
        fpc.layout = CustomFloatingPanelLayout()
        
        fpc.addPanel(toParent: self)
    }*/
    
    /*func floatingPanelDidMove(_ fpc: FloatingPanelController) {
        if fpc.isAttracting == false {
            let loc = fpc.surfaceLocation
            let minY = fpc.surfaceLocation(for: .full).y
            let maxY = fpc.surfaceLocation(for: .tip).y
            fpc.surfaceLocation = CGPoint(x: loc.x, y: min(max(loc.y, minY), maxY))
        }
    }*/
    
    func editorPickerView(_ editorPickerView: AvatarEditorPickerViewController, didSelectOption option: AvatarCustomizationResults.AvatarCustomizationOption) {
        //currentAvatarImageView.image = option.image.fullImage
		
		currentAvatarImageView.backgroundColor = UIColor(hexString: option.image.backgroundColor)!
        currentAvatarImageContainer.backgroundColor = UIColor(hexString: option.image.backgroundColor)!
		
		currentAvatarImageView.image = nil
		
        option.image.getFullImage(shouldUseCache: true, completion: { image in
			DispatchQueue.main.async {
				self.currentAvatarImageView.image = image
			}
		})
    }
    
    func editorPickerView(_ editorPickerView: AvatarEditorPickerViewController, didSelectCategory category: AvatarCustomizationResults.AvatarCustomizationType) {
		let currentImageURL = editorPickerView.preferences[editorPickerView.selectedIndexPath.row].image.fullImageName
		
		editorPickerView.updateOptions(options: [])
		//editorPickerView.collectionView.deleteItems(at: (0..<editorPickerView.collectionView.numberOfItems(inSection: 0)).map { IndexPath(row: $0, section: 0) })
		
        UIView.animate(withDuration: 0.3, animations: {
            editorPickerView.disablerView.isHidden = false
            editorPickerView.disablerView.alpha = 0.7
        }, completion: { _ in
			//editorPickerView.activityIndicator.isHidden = false
            editorPickerView.activityIndicator.startAnimating()
        })
        
        SwiftRant.shared.getAvatarCustomizationOptions(nil, type: category.id, subType: category.subType, currentImageID: currentImageURL, shouldGetPossibleOptions: false, completionHandler: { [weak self] result in
            self?.customizationResults = try? result.get()
            
            DispatchQueue.main.async {
				self?.currentAvatarImageView.backgroundColor = UIColor(hexString: self?.customizationResults.avatars.first(where: { $0.isSelected ?? false })!.image.backgroundColor ?? "")
				
                self?.customizationResults.avatars.first(where: { $0.isSelected ?? false })!.image.getFullImage(shouldUseCache: true, completion: { image in
					DispatchQueue.main.async {
						self?.currentAvatarImageView.image = image
					}
				})
				
				DispatchQueue.main.async {
					editorPickerView.activityIndicator.stopAnimating()
					
					print("IS INDICATOR ANIMATING: \(editorPickerView.activityIndicator.isAnimating)")
				}
				
                //self.currentAvatarImageView.image = self.customizationResults.avatars.first(where: { ($0.isSelected ?? false) })?.image.fullImage
				editorPickerView.selectedIndexPath = IndexPath(row: self?.customizationResults.avatars.firstIndex(where: { ($0.isSelected ?? false) })! ?? 0, section: 0)
                editorPickerView.updateOptions(options: self?.customizationResults.avatars ?? [])
				//editorPickerView.activityIndicator.isHidden = true
				
				UIView.animate(withDuration: 0.3, animations: {
					editorPickerView.disablerView.alpha = 0
					editorPickerView.disablerView.isHidden = true
				}, completion: { _ in
                    self?.pickerViewController.activityIndicator.stopAnimating()
				})
            }
        })
    }
	
	private func recursiveViewSearch(parentView: UIView, typeName: String) -> UIView? {
		var finalView: UIView? = nil
		
		for subview in parentView.subviews {
			print(String(describing: type(of: subview)))
			/*if String(describing: type(of: subview)) == typeName { return subview }
			
			if recursiveViewSearch(parentView: subview, typeName: typeName) == nil {
				continue
			}*/
			
			if String(describing: type(of: subview)) == typeName {
				finalView = subview
				return finalView
			} else {
				finalView = recursiveViewSearch(parentView: subview, typeName: typeName)
				
				if String(describing: type(of: finalView ?? UIView())) == typeName {
					return finalView
				}
			}
		}
		
		return nil
	}
	
	private func printRecursiveViewSearch(parentView: UIView) {
		for subview in parentView.subviews {
			print(String(describing: type(of: subview)))
			
			printRecursiveViewSearch(parentView: subview)
		}
	}
}

/*class CustomFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition = .bottom
    var initialState: FloatingPanelState = .tip
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 171, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 43, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}*/
