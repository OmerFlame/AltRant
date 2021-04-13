//
//  AvatarEditorViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import UIKit
import PullUpController

class AvatarEditorViewController: UIViewController {
    private var originalPullUpControllerViewSize: CGSize = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addPullUpController()
    }
    
    private func makePickerControllerIfNeeded() -> AvatarEditorPickerViewController {
        let currentPullUpController = children.filter({ $0 is AvatarEditorPickerViewController }).first as? AvatarEditorPickerViewController
        
        let pullUpController: AvatarEditorPickerViewController = currentPullUpController ?? UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarPicker") as! AvatarEditorPickerViewController
        
        pullUpController.initialState = .expanded
        
        if originalPullUpControllerViewSize == .zero {
            originalPullUpControllerViewSize = pullUpController.view.bounds.size
        }
        
        return pullUpController
    }
    
    private func addPullUpController() {
        let pullUpController = makePickerControllerIfNeeded()
        
        _ = pullUpController.view
        
        addPullUpController(pullUpController, initialStickyPointOffset: pullUpController.initialPointOffset, animated: false)
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
