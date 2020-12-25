//
//  ComposeViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/24/20.
//

import UIKit

class ComposeViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var remainingLettersLabel: UILabel!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var tagTextField: UITextField!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet var submitButton: UIBarButtonItem!
    
    var viewControllerThatPresented: UIViewController!
    
    //let placeholder: String
    var isComment: Bool!
    var rantID: Int?
    
    var inputImage: UIImage? {
        didSet {
            if inputImage == nil {
                attachmentButton.setTitle("Attach img/gif", for: .normal)
            } else {
                attachmentButton.setTitle("Remove image", for: .normal)
            }
        }
    }
    
    /*init?(coder: NSCoder, isComment: Bool, rantID: Int?, viewControllerThatPresented: UIViewController) {
        self.isComment = isComment
        self.rantID = rantID
        self.viewControllerThatPresented = viewControllerThatPresented
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        contentTextView.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .black : .white
        contentTextView.placeholder = self.isComment ? "Add your 2 cents..." : "The rant starts here..."
        contentTextView.placeholderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hex: "464649") : UIColor(hex: "c5c5c7")
        contentTextView.delegate = self
        
        remainingLettersLabel.text = !isComment ? String(5000 - contentTextView.text.count) : String(1000 - contentTextView.text.count)
        
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        
        contentTextView.inputAccessoryView = keyboardToolbar
        tagTextField.inputAccessoryView = keyboardToolbar
        
        navigationItem.title = self.isComment ? "New Comment" : "New Rant/Story"
        
        if isComment {
            tagTextField.isHidden = true
        }
        
        KeyboardAvoiding.avoidingView = mainStackView
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
    
    func textViewDidChange(_ textView: UITextView) {
        remainingLettersLabel.text = !isComment ? String(5000 - contentTextView.text.count) : String(1000 - contentTextView.text.count)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        contentTextView.backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? .black : .white
        contentTextView.placeholderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hex: "464649") : UIColor(hex: "c5c5c7")
        contentTextView.layer.borderColor = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor(hex: "ffffff")!.withAlphaComponent(0.20).cgColor : UIColor(red: 0, green: 0, blue: 0, alpha: 0.20).cgColor
        contentTextView.layer.borderWidth = 0.333
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: UIBarButtonItem) {
        //let originalSubmitButton = submitButton
        /*DispatchQueue.global(qos: .background).sync {
            /*let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.startAnimating()
            activityIndicator.hidesWhenStopped = true
            //activityIndicator.color = .lightGray
            
            //submitButton = UIBarButtonItem(customView: activityIndicator)
            //navigationItem.setRightBarButton(UIBarButtonItem(customView: activityIndicator), animated: false)
            //navigationItem.rightBarButtonItem?.isEnabled = false
            
            
            let dimView = UIView()
            dimView.backgroundColor = .black
            dimView.alpha = 0
            dimView.addSubview(activityIndicator)*/
            
            DispatchQueue.main.async {
                /*UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(dimView)
                
                dimView.translatesAutoresizingMaskIntoConstraints = false
                dimView.leadingAnchor.constraint(equalTo: UIApplication.shared.windows.first(where: { $0.isKeyWindow })!.leadingAnchor).isActive = true
                dimView.trailingAnchor.constraint(equalTo: UIApplication.shared.windows.first(where: { $0.isKeyWindow })!.trailingAnchor).isActive = true
                dimView.topAnchor.constraint(equalTo: UIApplication.shared.windows.first(where: { $0.isKeyWindow })!.topAnchor).isActive = true
                dimView.bottomAnchor.constraint(equalTo: UIApplication.shared.windows.first(where: { $0.isKeyWindow })!.bottomAnchor).isActive = true
                
                UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.bringSubviewToFront(dimView)
                
                UIView.animate(withDuration: 0.5) {
                    dimView.alpha = 0.5
                }*/
                
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        
        
            
            if self.isComment {
                var addedContent = [CommentModel]()
                
                let success = APIRequest().postComment(rantID: self.rantID!, content: self.contentTextView.text, image: self.inputImage)
                
                if (self.viewControllerThatPresented as! RantViewController).comments.isEmpty {
                    addedContent = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: (self.viewControllerThatPresented as! RantViewController).comments.last?.id ?? 0)!.comments
                }
                
                let start = (self.viewControllerThatPresented as! RantViewController).comments.count
                //var end = response!.profile.content.content.rants.count + start
                let end = addedContent.count + start
                
                (self.viewControllerThatPresented as! RantViewController).comments.append(contentsOf: addedContent)
                
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                
                for i in (self.viewControllerThatPresented as! RantViewController).comments[start..<end] {
                    if let attachedImage = i.attached_image {
                        //let completionSemaphore = DispatchSemaphore(value: 0)
                        
                        //var image = UIImage()
                        
                        /*URLSession.shared.dataTask(with: URL(string: attachedImage.url!)!) { data, _, _ in
                            image = UIImage(data: data!)!
                            
                            completionSemaphore.signal()
                        }.resume()
                        
                        completionSemaphore.wait()*/
                        
                        (self.viewControllerThatPresented as! RantViewController).commentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                        //self.commentContentImages.
                    } else {
                        (self.viewControllerThatPresented as! RantViewController).commentImages.append(nil)
                    }
                }
                
                DispatchQueue.main.async {
                    //self.submitButton = originalSubmitButton
                    //self.navigationItem.setRightBarButton(originalSubmitButton, animated: false)
                    //self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    /*UIView.animate(withDuration: 0.5) {
                        dimView.alpha = 0
                    }
                    
                    dimView.removeFromSuperview()*/
                    
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    if !success {
                        self.showAlertWithError("An error occurred while posting the rant. Please revise the content that you are trying to send and try again.", retryHandler: { self.submit(sender) })
                    } else {
                        let viewControllerThatPresented = self.viewControllerThatPresented
                        
                        self.navigationController?.dismiss(animated: true, completion: {
                            //(viewControllerThatPresented as! RantViewController).
                            
                            (viewControllerThatPresented as! RantViewController).tableView.beginUpdates()
                            (viewControllerThatPresented as! RantViewController).tableView.insertRows(at: indexPaths, with: .automatic)
                            (viewControllerThatPresented as! RantViewController).tableView.endUpdates()
                            
                            (viewControllerThatPresented as! RantViewController).tableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: true)
                        })
                    }
                }
            } else {
                let rantID = APIRequest().postRant(postType: .rant, content: self.contentTextView.text, tags: self.tagTextField.text, image: self.inputImage)
                
                DispatchQueue.main.async {
                    //self.submitButton = originalSubmitButton
                    //self.navigationItem.setRightBarButton(originalSubmitButton, animated: false)
                    //self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    /*UIView.animate(withDuration: 0.5) {
                        dimView.alpha = 0
                    }
                    
                    dimView.removeFromSuperview()*/
                    
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    if rantID == -1 {
                        self.showAlertWithError("An error occurred while posting the rant. Please revise the content that you are trying to send and try again.", retryHandler: { self.submit(sender) })
                    } else {
                        let viewControllerThatPresented = self.viewControllerThatPresented!
                        
                        self.navigationController?.dismiss(animated: true, completion: {
                            let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(identifier: "RantViewController", creator: { coder in
                                return RantViewController(coder: coder, rantID: rantID, rantInFeed: nil, supplementalRantImage: nil, loadCompletionHandler: nil)
                            })
                            
                            viewControllerThatPresented.navigationController?.pushViewController(rantVC, animated: true)
                        })
                    }
                }
            }
        }*/
        
        //NotificationCenter.default.addObserver(<#T##observer: Any##Any#>, selector: <#T##Selector#>, name: <#T##NSNotification.Name?#>, object: <#T##Any?#>)
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            if self.isComment {
                var addedContent = [CommentModel]()
                let lastCommentID = (self.viewControllerThatPresented as! RantViewController).comments.last!.id
                
                let success = APIRequest().postComment(rantID: self.rantID!, content: self.contentTextView.text, image: self.inputImage)
                
                if (self.viewControllerThatPresented as! RantViewController).comments.isEmpty {
                    addedContent = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: 0)!.comments
                } else {
                    addedContent = try! APIRequest().getRantFromID(id: self.rantID!, lastCommentID: lastCommentID)!.comments
                }
                
                let start = (self.viewControllerThatPresented as! RantViewController).comments.count
                //var end = response!.profile.content.content.rants.count + start
                let end = addedContent.count + start
                
                (self.viewControllerThatPresented as! RantViewController).comments.append(contentsOf: addedContent)
                
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 1) }
                
                for i in (self.viewControllerThatPresented as! RantViewController).comments[start..<end] {
                    if let attachedImage = i.attached_image {
                        //let completionSemaphore = DispatchSemaphore(value: 0)
                        
                        //var image = UIImage()
                        
                        /*URLSession.shared.dataTask(with: URL(string: attachedImage.url!)!) { data, _, _ in
                            image = UIImage(data: data!)!
                            
                            completionSemaphore.signal()
                        }.resume()
                        
                        completionSemaphore.wait()*/
                        
                        (self.viewControllerThatPresented as! RantViewController).commentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                        //self.commentContentImages.
                    } else {
                        (self.viewControllerThatPresented as! RantViewController).commentImages.append(nil)
                    }
                }
                
                DispatchQueue.main.async {
                    //self.submitButton = originalSubmitButton
                    //self.navigationItem.setRightBarButton(originalSubmitButton, animated: false)
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    if !success {
                        self.showAlertWithError("An error occurred while posting the rant. Please revise the content that you are trying to send and try again.", retryHandler: { self.submit(sender) })
                    } else {
                        let viewControllerThatPresented = self.viewControllerThatPresented
                        
                        self.navigationController?.dismiss(animated: true, completion: {
                            //(viewControllerThatPresented as! RantViewController).
                            
                            (viewControllerThatPresented as! RantViewController).tableView.beginUpdates()
                            (viewControllerThatPresented as! RantViewController).tableView.insertRows(at: indexPaths, with: .automatic)
                            (viewControllerThatPresented as! RantViewController).tableView.endUpdates()
                            
                            (viewControllerThatPresented as! RantViewController).tableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: true)
                        })
                    }
                }
            } else {
                let rantID = APIRequest().postRant(postType: .rant, content: self.contentTextView.text, tags: self.tagTextField.text, image: self.inputImage)
                
                DispatchQueue.main.async {
                    //self.submitButton = originalSubmitButton
                    //self.navigationItem.setRightBarButton(originalSubmitButton, animated: false)
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.navigationItem.leftBarButtonItem?.isEnabled = true
                    
                    if rantID == -1 {
                        self.showAlertWithError("An error occurred while posting the rant. Please revise the content that you are trying to send and try again.", retryHandler: { self.submit(sender) })
                    } else {
                        let viewControllerThatPresented = self.viewControllerThatPresented!
                        
                        self.navigationController?.dismiss(animated: true, completion: {
                            let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(identifier: "RantViewController", creator: { coder in
                                return RantViewController(coder: coder, rantID: rantID, rantInFeed: nil, supplementalRantImage: nil, loadCompletionHandler: nil)
                            })
                            
                            viewControllerThatPresented.navigationController?.pushViewController(rantVC, animated: true)
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func selectImage(_ sender: UIButton) {
        if inputImage == nil {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            
            pickerController.isModalInPresentation = true
            
            present(pickerController, animated: true, completion: nil)
        } else {
            inputImage = nil
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            self.inputImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
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
