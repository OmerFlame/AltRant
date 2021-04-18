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
    var fpc: FloatingPanelController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addPullUpController()
    }
    
    /*private func makePickerControllerIfNeeded() -> AvatarEditorPickerViewController {
        let currentPullUpController = children.filter({ $0 is AvatarEditorPickerViewController }).first as? AvatarEditorPickerViewController
        
        let pullUpController: AvatarEditorPickerViewController = currentPullUpController ?? UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarPicker") as! AvatarEditorPickerViewController
        
        //pullUpController.initialState = .expanded
        
        if originalPullUpControllerViewSize == .zero {
            originalPullUpControllerViewSize = pullUpController.view.bounds.size
        }
        
        return pullUpController
    }*/
    
    /*private func addPullUpController() {
        let pullUpController = makePickerControllerIfNeeded()
        
        _ = pullUpController.view
        
        addPullUpController(pullUpController, initialStickyPointOffset: pullUpController.initialPointOffset, animated: false)
    }*/
    
    func addPullUpController() {
        fpc = FloatingPanelController()
        
        let contentVC = UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarPicker") as! AvatarEditorPickerViewController
        
        
        
        fpc.set(contentViewController: contentVC)
        
        fpc.delegate = self
        
        fpc.layout = CustomFloatingPanelLayout()
        
        //fpc.track(scrollView: contentVC.collectionView)
        
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
