//
//  ComposeViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/24/20.
//

import UIKit
import UniformTypeIdentifiers
import SwiftRant
import OSPlaceholderTextView
import SwiftHEXColors
//import SwiftUI

class ComposeViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var contentTextView: OSPlaceholderTextView!
    @IBOutlet weak var remainingLettersLabel: UILabel!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet var submitButton: UIBarButtonItem!
    
    var viewControllerThatPresented: UIViewController!
    
    var popoverPickerController: UITableViewController!
    
    //let placeholder: String
    var content: String?
    var tags: String?
    
    var isComment: Bool!
    var isEdit: Bool!
    var rantID: Int?
    var commentID: Int?
    
    var rantType: Rant.RantType = .rant
    
    /*let menu = UIMenu(title: "", children: [
        UIAction(title: "From File", image: UIImage(systemName: "folder.fill"), handler: { _ in
            openDocumentPicker()
        }),
    ])*/
    
    var menu: UIMenu {
        return UIMenu(title: "", children: [
            UIAction(title: "Import from File", image: UIImage(systemName: "folder.fill"), handler: { _ in
                self.openDocumentPicker()
            }),
            UIAction(title: "Import from Photo Library", image: UIImage(systemName: "photo.fill"), handler: { _ in
                self.openImagePicker()
            })
        ])
    }
    
    var inputImage: UIImage? {
        didSet {
            if inputImage == nil {
                attachmentButton.setTitle("Attach img/gif", for: .normal)
                
                attachmentButton.removeTarget(nil, action: nil, for: .primaryActionTriggered)
                attachmentButton.menu = menu
                attachmentButton.showsMenuAsPrimaryAction = true
                previewImageView.image = nil
            } else {
                attachmentButton.setTitle("Remove image", for: .normal)
                
                attachmentButton.menu = nil
                attachmentButton.showsMenuAsPrimaryAction = false
                
                attachmentButton.removeTarget(nil, action: nil, for: .primaryActionTriggered)
                attachmentButton.addTarget(self, action: #selector(discardImage), for: .primaryActionTriggered)
                previewImageView.image = inputImage
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attachmentButton.setTitleColor(UIButton().tintColor, for: .normal)
        // Do any additional setup after loading the view.
        
        contentTextView.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .black : .white
        contentTextView.placeholder = self.isComment ? "Add your 2 cents..." : "The rant starts here..."
        contentTextView.placeholderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hexString: "464649")! : UIColor(hexString: "c5c5c7")!
        //contentTextView.selectedTextRange = contentTextView.textRange(from: contentTextView.beginningOfDocument, to: contentTextView.beginningOfDocument)
        //contentTextView.placeholderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hexString: "464649") : UIColor(hexString: "c5c5c7")
        contentTextView.delegate = self
        
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        
        contentTextView.inputAccessoryView = keyboardToolbar
        tagTextField.inputAccessoryView = keyboardToolbar
        
        inputImage = nil
        
        if !isComment && !isEdit {
            navigationItem.title = "New Rant/Story"
            
            let titleButton = UIButton()
            titleButton.addTarget(self, action: #selector(openPopoverPicker), for: .touchUpInside)
            titleButton.setTitleColor(.label, for: .normal)
            titleButton.setTitle("New Rant/Story", for: .normal)
            titleButton.sizeToFit()
            titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            
            navigationItem.titleView = titleButton
            
        } else if isComment {
            navigationItem.title = "New Comment"
            contentTextView.text = content
        } else if isEdit {
            navigationItem.title = "Edit"
            contentTextView.text = content
            
            if !isComment {
                tagTextField.text = tags
                
                if (viewControllerThatPresented as! RantViewController).supplementalRantImage == nil {
                    inputImage = nil
                } else {
                    inputImage = UIImage(contentsOfFile: (viewControllerThatPresented as! RantViewController).supplementalRantImage?.previewItemURL.relativePath ?? "")
                }
            }
        } else if isEdit && isComment {
            navigationItem.title = "Edit"
            contentTextView.text = content
        }
        
        remainingLettersLabel.text = !isComment ? String(5000 - contentTextView.text.count) : String(1000 - contentTextView.text.count)
        
        if isComment {
            tagTextField.isHidden = true
        }
        
        KeyboardAvoiding.avoidingView = mainStackView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Rant/Story"
            return cell
            
        case 1:
            cell.textLabel?.text = "New Joke/Meme"
            return cell
            
        case 2:
            cell.textLabel?.text = "New Question"
            return cell
            
        case 3:
            cell.textLabel?.text = "New devRant-related Post"
            return cell
            
        default:
            cell.textLabel?.text = "New Random Post"
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            (self.navigationItem.titleView as! UIButton).setTitle("New Rant/Story", for: .normal)
            (self.navigationItem.titleView as! UIButton).sizeToFit()
            self.rantType = .rant
            
        case 1:
            (self.navigationItem.titleView as! UIButton).setTitle("New Joke/Meme", for: .normal)
            (self.navigationItem.titleView as! UIButton).sizeToFit()
            self.rantType = .meme
            
        case 2:
            (self.navigationItem.titleView as! UIButton).setTitle("New Question", for: .normal)
            (self.navigationItem.titleView as! UIButton).sizeToFit()
            self.rantType = .question
            
        case 3:
            (self.navigationItem.titleView as! UIButton).setTitle("New devRant-related Post", for: .normal)
            (self.navigationItem.titleView as! UIButton).sizeToFit()
            self.rantType = .devRant
            
        default:
            (self.navigationItem.titleView as! UIButton).setTitle("New Random Post", for: .normal)
            (self.navigationItem.titleView as! UIButton).sizeToFit()
            self.rantType = .random
        }
        
        popoverPickerController.dismiss(animated: true, completion: nil)
    }
    
    @objc func openPopoverPicker() {
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
        ppc?.permittedArrowDirections = .up
        ppc?.delegate = self
        ppc?.sourceRect = navigationItem.titleView!.bounds
        ppc?.sourceView = navigationItem.titleView!
        
        present(popoverPickerController, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    @objc func doneButtonPressed() {
        contentTextView.resignFirstResponder()
        tagTextField.resignFirstResponder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if isComment {
            return textView.text.count + (text.count - range.length) <= 1000
        } else {
            return textView.text.count + (text.count - range.length) <= 5000
        }
    }
    
    /*func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }*/
    
    func textViewDidChange(_ textView: UITextView) {
        remainingLettersLabel.text = !isComment ? String(5000 - contentTextView.text.count) : String(1000 - contentTextView.text.count)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        contentTextView.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .black : .white
        //contentTextView.placeholderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hexString: "464649") : UIColor(hexString: "c5c5c7")
        contentTextView.layer.borderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hexString: "ffffff")!.withAlphaComponent(0.20).cgColor : UIColor(red: 0, green: 0, blue: 0, alpha: 0.20).cgColor
        contentTextView.layer.borderWidth = 0.333
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        if isComment {
            if !isEdit {
                var addedContent = [Comment]()
                let lastCommentID = (viewControllerThatPresented as! RantViewController).comments.last?.id ?? 0
                
                SwiftRant.shared.postComment(nil, rantID: rantID!, content: contentTextView.text, image: inputImage) { [weak self] error, success in
                    if success {
                        SwiftRant.shared.getRantFromID(token: nil, id: self?.rantID ?? 0, lastCommentID: lastCommentID) { refetchError, _, comments in
                            if let comments = comments {
                                addedContent = comments
                                
                                let start = (self?.viewControllerThatPresented as! RantViewController).comments.count
                                
                                let end = addedContent.count + start
                                
                                (self?.viewControllerThatPresented as! RantViewController).comments.append(contentsOf: addedContent)
                                
                                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 1) }
                                
                                for i in (self?.viewControllerThatPresented as! RantViewController).comments[start..<end] {
                                    if let attachedImage = i.attachedImage {
                                        (self?.viewControllerThatPresented as! RantViewController).commentImages[i.id] = File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height))
                                    } else {
                                        (self?.viewControllerThatPresented as! RantViewController).commentImages[i.id] = nil
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    let viewControllerThatPresented = self?.viewControllerThatPresented
                                    
                                    self?.navigationController?.dismiss(animated: true, completion: {
                                        (viewControllerThatPresented as! RantViewController).tableView.beginUpdates()
                                        (viewControllerThatPresented as! RantViewController).tableView.insertRows(at: indexPaths, with: .automatic)
                                        (viewControllerThatPresented as! RantViewController).tableView.endUpdates()
                                        
                                        (viewControllerThatPresented as! RantViewController).tableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: true)
                                    })
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                                    
                                    let viewControllerThetPresented = self?.viewControllerThatPresented
                                    
                                    self?.navigationController?.dismiss(animated: true) {
                                        let alertController = UIAlertController(title: "Error", message: refetchError ?? "An unknown error has occurred while attempting to retrieve new comments that were posted to this rant. This error occured by either a bug in AltRant, or the creator of the rant deleted the rant right after you posted your comment.", preferredStyle: .alert)
                                        
                                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                        
                                        (viewControllerThetPresented as! RantViewController).present(alertController, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.navigationItem.rightBarButtonItem?.isEnabled = true
                            
                            self?.showAlertWithError(error ?? "An unknown error occurred while posting the comment.", retryHandler: { self?.submit(sender) })
                        }
                    }
                }
            } else {
                SwiftRant.shared.editComment(nil, commentID: commentID!, content: contentTextView.text, image: inputImage) { [weak self] error, success in
                    if success {
                        SwiftRant.shared.getCommentFromID(self?.commentID ?? 0, token: nil) { retrieveError, newComment in
                            if let newComment = newComment {
                                if (self?.viewControllerThatPresented as! RantViewController).commentImages[self?.commentID ?? 0] != nil {
                                    if UIImage(contentsOfFile: (self?.viewControllerThatPresented as! RantViewController).commentImages[self?.commentID ?? 0]!?.previewItemURL.relativePath ?? "") != self?.inputImage {
                                        if newComment.attachedImage != nil {
                                            (self?.viewControllerThatPresented as! RantViewController).commentImages[self?.commentID ?? 0] = File.loadFile(image: newComment.attachedImage!, size: CGSize(width: newComment.attachedImage!.width, height: newComment.attachedImage!.height))
                                        } else {
                                            (self?.viewControllerThatPresented as! RantViewController).commentImages[self?.commentID ?? 0] = nil
                                        }
                                    }
                                } else {
                                    if newComment.attachedImage != nil {
                                        (self?.viewControllerThatPresented as! RantViewController).commentImages[self?.commentID ?? 0] = File.loadFile(image: newComment.attachedImage!, size: CGSize(width: newComment.attachedImage!.width, height: newComment.attachedImage!.height))
                                    } else {
                                        (self?.viewControllerThatPresented as! RantViewController).commentImages[self?.commentID ?? 0] = nil
                                    }
                                }
                                
                                DispatchQueue.main.async {
                                    let viewControllerThatPresented = self?.viewControllerThatPresented
                                    
                                    self?.navigationController?.dismiss(animated: true) {
                                        let row = (viewControllerThatPresented as! RantViewController).comments.firstIndex(where: { $0.id == self?.commentID }) ?? 0
                                        
                                        (viewControllerThatPresented as! RantViewController).comments[row] = newComment
                                        (viewControllerThatPresented as! RantViewController).tableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
                                    }
                                }
                            } else {
                                
                                DispatchQueue.main.async {
                                    self?.showAlertWithError(retrieveError ?? "An unknown error occurred while retrieving the new edited comment.", retryHandler: nil)
                                }
                            }
                        }
                    } else {
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                        
                        self?.showAlertWithError(error ?? "An unknown error occurred while posting the comment.", retryHandler: { self?.submit(sender) })
                    }
                }
            }
        } else {
            if !isEdit {
                SwiftRant.shared.postRant(nil, postType: rantType, content: contentTextView.text, tags: tagTextField.text, image: inputImage) { [weak self] error, rantID in
                    DispatchQueue.main.async {
                        self?.navigationItem.rightBarButtonItem?.isEnabled = true
                        self?.navigationItem.leftBarButtonItem?.isEnabled = true
                        
                        if rantID == nil {
                            self?.showAlertWithError(error ?? "An unknown error has occurred.", retryHandler: { self?.submit(sender) })
                        } else {
                            let viewControllerThatPresented = self?.viewControllerThatPresented
                            
                            self?.navigationController?.dismiss(animated: true) {
                                viewControllerThatPresented?.performSegue(withIdentifier: "AfterCompose", sender: rantID)
                            }
                        }
                    }
                }
            } else {
                SwiftRant.shared.editRant(nil, rantID: rantID!, postType: rantType, content: contentTextView.text, tags: tagTextField.text, image: inputImage) { [weak self] error, success in
                    if success {
                        var file: File?
                        
                        SwiftRant.shared.getRantFromID(token: nil, id: self?.rantID ?? -1, lastCommentID: (self?.viewControllerThatPresented as! RantViewController).comments.last?.id ?? 0) { retrieveError, updatedRant, _ in
                            if let updatedRant = updatedRant {
                                if updatedRant.attachedImage != nil {
                                    file = File.loadFile(image: updatedRant.attachedImage!, size: CGSize(width: updatedRant.attachedImage!.width, height: updatedRant.attachedImage!.height))
                                }
                                
                                DispatchQueue.main.async {
                                    let viewControllerThatPresented = self?.viewControllerThatPresented
                                    
                                    self?.navigationController?.dismiss(animated: true) {
                                        (viewControllerThatPresented as! RantViewController).rant = updatedRant
                                        (viewControllerThatPresented as! RantViewController).supplementalRantImage = file
                                        
                                        (viewControllerThatPresented as! RantViewController).tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                                    
                                    self?.showAlertWithError(retrieveError ?? "An unknown error occurred while fetching the updated rant.", retryHandler: nil)
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.navigationItem.rightBarButtonItem?.isEnabled = true
                            
                            self?.showAlertWithError(error ?? "An unknown error occurred while updating the rant.", retryHandler: { self?.submit(sender) })
                        }
                    }
                }
            }
        }
        
        /*DispatchQueue.global(qos: .userInitiated).async {
            if self.isComment {
                if !self.isEdit {
                    var addedContent = [Comment]()
                    let lastCommentID = (self.viewControllerThatPresented as! RantViewController).comments.last?.id ?? 0
                    
                    let success = SwiftRant.shared.postComment(nil, rantID: self.rantID!, content: self.contentTextView.text, image: self.inputImage)
                    
                    /*if (self.viewControllerThatPresented as! RantViewController).comments.isEmpty {
                        addedContent = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: 0)!.comments
                    } else {
                        addedContent = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: lastCommentID)!.comments
                    }*/
                    
                    addedContent = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: lastCommentID)!.comments
                    
                    let start = (self.viewControllerThatPresented as! RantViewController).comments.count
                    //var end = response!.profile.content.content.rants.count + start
                    let end = addedContent.count + start
                    
                    (self.viewControllerThatPresented as! RantViewController).comments.append(contentsOf: addedContent)
                    
                    let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 1) }
                    
                    for i in (self.viewControllerThatPresented as! RantViewController).comments[start..<end] {
                        if let attachedImage = i.attached_image {
                            (self.viewControllerThatPresented as! RantViewController).commentImages[i.id] = File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!))
                        } else {
                            (self.viewControllerThatPresented as! RantViewController).commentImages[i.id] = nil
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        
                        if !success {
                            self.showAlertWithError("An error occurred while posting the rant. Please revise the content that you are trying to send and try again.", retryHandler: { self.submit(sender) })
                        } else {
                            let viewControllerThatPresented = self.viewControllerThatPresented
                            
                            self.navigationController?.dismiss(animated: true, completion: {
                                (viewControllerThatPresented as! RantViewController).tableView.beginUpdates()
                                (viewControllerThatPresented as! RantViewController).tableView.insertRows(at: indexPaths, with: .automatic)
                                (viewControllerThatPresented as! RantViewController).tableView.endUpdates()
                                
                                (viewControllerThatPresented as! RantViewController).tableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: true)
                            })
                        }
                    }
                } else {
                    let success = APIRequest().editComment(commentID: self.commentID!, content: self.contentTextView.text, image: self.inputImage)
                    
                    
                    if success {
                        let newComment = APIRequest().getCommentFromID(self.commentID!)
                        
                        if (self.viewControllerThatPresented as! RantViewController).commentImages[self.commentID!] != nil {
                            if UIImage(contentsOfFile: ((self.viewControllerThatPresented as! RantViewController).commentImages[self.commentID!]!!.previewItemURL.relativePath))! != self.inputImage {
                                
                                if newComment!.comment!.attached_image != nil {
                                    (self.viewControllerThatPresented as! RantViewController).commentImages[self.commentID!] = File.loadFile(image: newComment!.comment!.attached_image!, size: CGSize(width: newComment!.comment!.attached_image!.width!, height: newComment!.comment!.attached_image!.height!))
                                } else {
                                    (self.viewControllerThatPresented as! RantViewController).commentImages[self.commentID!] = nil
                                }
                            }
                        } else {
                            if newComment!.comment!.attached_image != nil {
                                (self.viewControllerThatPresented as! RantViewController).commentImages[self.commentID!] = File.loadFile(image: newComment!.comment!.attached_image!, size: CGSize(width: newComment!.comment!.attached_image!.width!, height: newComment!.comment!.attached_image!.height!))
                            } else {
                                (self.viewControllerThatPresented as! RantViewController).commentImages[self.commentID!] = nil
                            }
                        }
                        
                        DispatchQueue.main.async {
                            let viewControllerThatPresented = self.viewControllerThatPresented!
                            let commentID = self.commentID!
                            
                            self.navigationController?.dismiss(animated: true, completion: {
                                let row = (viewControllerThatPresented as! RantViewController).comments.firstIndex(where: {
                                    $0.id == commentID
                                })!
                                
                                (viewControllerThatPresented as! RantViewController).comments[row] = newComment!.comment!
                                (viewControllerThatPresented as! RantViewController).tableView.reloadRows(at: [IndexPath(row: row, section: 1)], with: .none)
                            })
                        }
                    }
                }
            } else {
                if !self.isEdit {
                    let rantID = APIRequest().postRant(postType: self.rantType, content: self.contentTextView.text, tags: self.tagTextField.text, image: self.inputImage)
                    
                    DispatchQueue.main.async {
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        self.navigationItem.leftBarButtonItem?.isEnabled = true
                        
                        if rantID == -1 {
                            self.showAlertWithError("An error occurred while posting the rant. Please revise the content that you are trying to send and try again.", retryHandler: { self.submit(sender) })
                        } else {
                            let viewControllerThatPresented = self.viewControllerThatPresented!
                            
                            self.navigationController?.dismiss(animated: true, completion: {
                                /*let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(identifier: "RantViewController", creator: { coder in
                                    return RantViewController(coder: coder, rantID: rantID, rantInFeed: nil, supplementalRantImage: nil, loadCompletionHandler: nil)
                                })
                                
                                viewControllerThatPresented.navigationController?.pushViewController(rantVC, animated: true)*/
                                
                                viewControllerThatPresented.performSegue(withIdentifier: "AfterCompose", sender: rantID)
                            })
                        }
                    }
                } else {
                    let success = APIRequest().editRant(rantID: self.rantID!, postType: self.rantType, content: self.contentTextView.text, tags: self.tagTextField.text, image: self.inputImage)
                    
                    if success {
                        var file: File?
                        
                        let updatedRant = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: (self.viewControllerThatPresented as! RantViewController).comments.last?.id ?? 0)!.rant
                        
                        if updatedRant.attached_image != nil {
                            file = File.loadFile(image: updatedRant.attached_image!, size: CGSize(width: updatedRant.attached_image!.width!, height: updatedRant.attached_image!.height!))
                        }
                        
                        DispatchQueue.main.async {
                            let viewControllerThatPresented = self.viewControllerThatPresented!
                            
                            self.navigationController?.dismiss(animated: true, completion: {
                                (viewControllerThatPresented as! RantViewController).rant = updatedRant
                                (viewControllerThatPresented as! RantViewController).supplementalRantImage = file
                                
                                (viewControllerThatPresented as! RantViewController).tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                            })
                        }
                    }
                }
            }
        }*/
    }
    
    /*func selectImage() {
        if inputImage == nil {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            
            pickerController.isModalInPresentation = true
            
            present(pickerController, animated: true, completion: nil)
        } else {
            inputImage = nil
        }
    }*/
    
    @objc func discardImage() {
        inputImage = nil
    }
    
    func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    func openImagePicker() {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        
        pickerController.isModalInPresentation = true
        
        present(pickerController, animated: true, completion: nil)
    }
    
    // MARK: - Image Picker Controller Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            print("IMAGE WIDTH:  \(image.size.width)")
            print("IMAGE HEIGHT: \(image.size.height)")
            
            self.inputImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Document Picker Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let image = UIImage(contentsOfFile: urls[0].path)
        
        inputImage = image
        
        //attachmentButton.menu = nil
        //attachmentButton.showsMenuAsPrimaryAction = false
        
        //attachmentButton.removeTarget(nil, action: nil, for: .primaryActionTriggered)
        //attachmentButton.addTarget(self, action: #selector(discardImage), for: .primaryActionTriggered)
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        inputImage = nil
        
        //attachmentButton.menu = menu
        //attachmentButton.showsMenuAsPrimaryAction = true
        controller.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func showAlertWithError(_ error: String, retryHandler: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: (retryHandler != nil ? { _ in retryHandler!() } : nil)))
        present(alert, animated: true, completion: nil)
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
