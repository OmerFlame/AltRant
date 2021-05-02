//
//  AvatarEditorViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import UIKit
import FloatingPanel

class AvatarEditorViewController: UIViewController, FloatingPanelControllerDelegate {
    //private var originalPullUpControllerViewSize: CGSize = .zero
    @IBOutlet weak var currentAvatarImageView: UIImageView!
    var fpc: FloatingPanelController!
    
    var customizationResults: AvatarCustomizationResults!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addPullUpController()
        
        // TODO: - Ask for the current image while initializing the class, don't get it manually
        APIRequest().getProfileFromID(UserDefaults.standard.integer(forKey: "DRUserID"), userContentType: .rants, skip: 0, completionHandler: { result in
            APIRequest().getAvatarCustomizationOptions(option: "g", subOption: nil, currentImageURL: result!.profile.avatar.i!, shouldGetPossibleOptions: true, completionHandler: { customizationResults in
                self.customizationResults = customizationResults
                
                if let options = self.customizationResults.options {
                    DispatchQueue.main.async {
                        
                        self.currentAvatarImageView.image = self.customizationResults.avatars.first(where: { ($0.isSelected ?? false) })?.image.fullImage
                        (self.fpc.contentViewController as! AvatarEditorPickerViewController).updateOptions(options: options)
                        (self.fpc.contentViewController as! AvatarEditorPickerViewController).updateImages(images: self.customizationResults.avatars)
                    }
                }
            })
        })
    }
    
    func addPullUpController() {
        fpc = FloatingPanelController()
        
        let contentVC = UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarPicker") as! AvatarEditorPickerViewController
        
        
        
        fpc.set(contentViewController: contentVC)
        
        fpc.delegate = self
        
        fpc.layout = CustomFloatingPanelLayout()
        
        fpc.addPanel(toParent: self)
    }
    
    func floatingPanelDidMove(_ fpc: FloatingPanelController) {
        if fpc.isAttracting == false {
            let loc = fpc.surfaceLocation
            let minY = fpc.surfaceLocation(for: .full).y
            let maxY = fpc.surfaceLocation(for: .tip).y
            fpc.surfaceLocation = CGPoint(x: loc.x, y: min(max(loc.y, minY), maxY))
        }
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

class CustomFloatingPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition = .bottom
    var initialState: FloatingPanelState = .tip
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 194, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 66, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}
