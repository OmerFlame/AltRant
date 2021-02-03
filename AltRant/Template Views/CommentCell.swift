//
//  CommentCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/7/20.
//

import UIKit
import SwiftUI
import QuickLook
import ActiveLabel

class CommentCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var userProfileImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: PaddingLabel!
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var actionsStackView: UIStackView!
    
    @IBOutlet weak var bodyLabel: ActiveLabel!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var reportModifyButton: UIButton!
    
    var attributedBodyString: NSAttributedString?
    var file: File?
    var attachedRantFile: File?
    var commentContents: CommentModel!
    var parentTableViewController: UIViewController? = nil
    var parentTableView: UITableView? = nil
    
    var commentInFeed: Binding<CommentModel>?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(with model: CommentModel, supplementalImage: File?, parentTableViewController: UIViewController?, parentTableView: UITableView?, commentInFeed: Binding<CommentModel>?, allowedToPreview: Bool) {
        self.commentContents = model
        self.file = supplementalImage
        self.parentTableViewController = parentTableViewController
        self.parentTableView = parentTableView
        self.commentInFeed = commentInFeed
        
        /*if model.attached_image != nil {
            let resizeMultiplier = getImageResizeMultiplier(imageWidth: CGFloat(commentContents!.attached_image!.width!), imageHeight: CGFloat(commentContents!.attached_image!.height!), multiplier: 1)
            
            let finalWidth = CGFloat(commentContents!.attached_image!.width!) / resizeMultiplier
            let finalHeight = CGFloat(commentContents!.attached_image!.height!) / resizeMultiplier
            
            self.file = Optional(File.loadFile(image: commentContents!.attached_image!, size: CGSize(width: finalWidth, height: finalHeight)))
        }*/
        
        upvoteButton.tintColor = (model.vote_state == 1 ? UIColor(hex: model.user_avatar.b)! : UIColor.systemGray)
        //scoreLabel.text = String(commentContents!.score)
        scoreLabel.text = formatNumber(commentContents!.score)
        downvoteButton.tintColor = (model.vote_state == -1 ? UIColor(hex: model.user_avatar.b)! : UIColor.systemGray)
        
        if supplementalImage == nil {
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            let resizeMultiplier = supplementalImage!.size!.width / bodyLabel.frame.size.width
            
            let finalWidth = supplementalImage!.size!.width / resizeMultiplier
            let finalHeight = supplementalImage!.size!.height / resizeMultiplier
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
            UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            supplementalImageView.image = newImage
            
            //supplementalImageView.image = supplementalImage
            //supplementalImageView.frame.size = supplementalImage!.size
        }
        
        upvoteButton.isEnabled = commentContents!.vote_state != -2
        downvoteButton.isEnabled = commentContents!.vote_state != -2
        
        bodyLabel.text = commentContents!.body
        
        if commentContents!.user_avatar.i == nil {
            userProfileImageView.image = UIImage(color: UIColor(hex: commentContents!.user_avatar.b)!, size: CGSize(width: 45, height: 45))
        } else {
            let resourceURL = URL(string: "https://avatars.devrant.com/" + commentContents!.user_avatar.i!)!
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var imageData: Data? = nil
            
            URLSession.shared.dataTask(with: resourceURL) { data, response, error in
                imageData = data ?? nil
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            userProfileImageView.image = UIImage(data: imageData ?? Data()) ?? nil
        }
        
        usernameLabel.text = commentContents!.user_username
        
        if commentContents!.user_score < 0 {
            userScoreLabel.text = String(commentContents!.user_score)
        } else {
            userScoreLabel.text = "+\(commentContents!.user_score)"
        }
        
        userScoreLabel.backgroundColor = UIColor(hex: commentContents!.user_avatar.b)
        
        scoreLabel.text = String(commentContents!.score)
        
        if allowedToPreview {
            let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            supplementalImageView.addGestureRecognizer(imageGestureRecognizer)
            
            let usernameGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUsernameTap(_:)))
            userStackView.addGestureRecognizer(usernameGestureRecognizer)
            
            if commentContents.user_id == UserDefaults.standard.integer(forKey: "DRUserID") && commentContents.user_username == UserDefaults.standard.string(forKey: "DRUsername")! {
                reportModifyButton.setTitle("Modify", for: .normal)
                
                let actionsMenu = UIMenu(title: "", children: [
                    UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")!, handler: { _ in
                        if Double(Date().timeIntervalSince1970) - Double(self.commentContents.created_time) >= 300 {
                            let alert = UIAlertController(title: "Editing Disabled", message: "Rants and comments can only be edited for 5 mins (30 mins for devRant++ subscribers) after they are posted.", preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))
                            
                            self.parentTableViewController?.present(alert, animated: true, completion: nil)
                        } else {
                            let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
                            (composeVC.viewControllers.first as! ComposeViewController).commentID = self.commentContents.id
                            (composeVC.viewControllers.first as! ComposeViewController).isComment = true
                            (composeVC.viewControllers.first as! ComposeViewController).isEdit = true
                            (composeVC.viewControllers.first as! ComposeViewController).content = self.commentContents.body
                            
                            (composeVC.viewControllers.first as! ComposeViewController).viewControllerThatPresented = self.parentTableViewController
                            
                            composeVC.isModalInPresentation = true
                            
                            self.parentTableViewController!.present(composeVC, animated: true, completion: nil)
                        }
                    }),
                    
                    UIAction(title: "Delete", image: UIImage(systemName: "trash")!, handler: { _ in
                        let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this comment?", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.delete() }))
                        
                        self.parentTableViewController?.present(alert, animated: true, completion: nil)
                    })
                ])
                
                reportModifyButton.showsMenuAsPrimaryAction = true
                reportModifyButton.menu = actionsMenu
            } else {
                reportModifyButton.setTitle("Report", for: .normal)
            }
            
            if let links = commentContents.links {
                //var textLinks = [TextLink]()
                let semiboldAttrString = NSMutableAttributedString(string: commentContents.body)
                
                for i in links {
                    if i.start == nil && i.end == nil {
                        let range = (commentContents.body as NSString).range(of: i.title)
                        
                        if i.type == "url" {
                            semiboldAttrString.replaceCharacters(in: range, with: i.url)
                            
                            let newRange = (semiboldAttrString.string as NSString).range(of: i.url)
                            
                            semiboldAttrString.addAttribute(.font, value: UIFont.systemFont(ofSize: bodyLabel.font.pointSize, weight: .semibold), range: newRange)
                        } else {
                            semiboldAttrString.addAttribute(.font, value: UIFont.systemFont(ofSize: bodyLabel.font.pointSize, weight: .semibold), range: range)
                        }
                        
                        /*if i.type == "url" {
                            textLinks.append(TextLink(text: i.title, range: range, action: {}))
                        }*/
                        
                        //bodyLabel.attributedText = semiboldAttrString
                        //bodyLabel.isUserInteractionEnabled = true
                        //bodyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleURLTap(_:))))
                    } else {
                        
                        
                        let range = NSRange(location: i.start! - 2 * (semiboldAttrString.string.components(separatedBy: "\n").count - 1), length: i.end! - i.start!)
                        
                        if i.type == "url" {
                            semiboldAttrString.replaceCharacters(in: range, with: i.url)
                            
                            let newLength = i.url.count - i.title.count
                            
                            let newRange = NSRange(location: i.start! - 2 * (semiboldAttrString.string.components(separatedBy: "\n").count - 1), length: i.end! + newLength - i.start!)
                            
                            semiboldAttrString.addAttribute(.font, value: UIFont.systemFont(ofSize: bodyLabel.font.pointSize, weight: .semibold), range: newRange)
                        }
                        
                        /*if i.type == "url" {
                            textLinks.append(TextLink(text: i.title, range: range, action: {}))
                        }*/
                        
                        
                        //bodyLabel.isUserInteractionEnabled = true
                    }
                }
                
                bodyLabel.urlMaximumLength = 27
                
                bodyLabel.attributedText = semiboldAttrString
                bodyLabel.isUserInteractionEnabled = true
                
                bodyLabel.mentionColor = .label
                bodyLabel.URLColor = .label
                
                bodyLabel.highlightFontName = ".AppleSystemUIFontEmphasized"
                bodyLabel.highlightFontSize = bodyLabel.font.pointSize
                
                print("FONT NAMES: \(UIFont.fontNames(forFamilyName: bodyLabel.font.familyName))")
                
                bodyLabel.enabledTypes = [.mention, .url]
                
                attributedBodyString = bodyLabel.attributedText
                
                /*bodyLabel.textFont = { _ in
                    return .systemFont(ofSize: self.bodyLabel.font.pointSize, weight: .semibold)
                }*/
                
                /*bodyLabel.underlineStyle = { linkResult in
                    return []
                }
                
                bodyLabel.foregroundColor = { _ in
                    return .label
                }*/
                
                bodyLabel.textColor = .label
                
                bodyLabel.handleMentionTap { handle in
                    if let links = self.commentContents.links {
                        for link in links {
                            if link.title == "@\(handle)" {
                                if let parentTableViewController = self.parentTableViewController {
                                    let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                                        return ProfileTableViewController(coder: coder, userID: Int(link.url)!)
                                    })
                                    
                                    print(String(describing: type(of: parentTableViewController)))
                                    print(String(describing: type(of: self)))
                                    
                                    parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
                                    
                                    break
                                    
                                    //bodyLabel.attributedText = attributedBodyString
                                }
                            }
                        }
                    }
                }
                
                bodyLabel.handleURLTap { url in
                    UIApplication.shared.open(url)
                }
                
                /*bodyLabel.didTouch = { touchResult in
                    self.handleURLTap(result: touchResult)
                }*/
                //bodyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleURLTap(_:))))
            }
        }
        
        if !allowedToPreview {
            //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            //textStackView.addGestureRecognizer(tapGesture)
            
            actionsStackView.isHidden = true
            
            /*if let rantAttachedImage = try! APIRequest().getRantFromID(id: commentContents.rant_id)!.rant.attached_image, self.attachedRantFile == nil {
                self.attachedRantFile = File.loadFile(image: rantAttachedImage, size: CGSize(width: rantAttachedImage.width!, height: rantAttachedImage.height!))
            }*/
        }
    }
    
    func delete() {
        let originalColor = self.parentTableViewController?.navigationController?.navigationBar.tintColor
        
        self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = false
        self.parentTableViewController?.navigationController?.navigationBar.tintColor = UIColor.systemGray
        
        let originalTitle = self.parentTableViewController?.title
        
        self.parentTableViewController?.title = "Deleting your comment..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = APIRequest().deleteComment(commentID: self.commentContents.id)
            
            if success {
                let typeCastedController = self.parentTableViewController as! RantViewController
                let commentIdx = typeCastedController.comments.firstIndex(where: {
                    $0.uuid == self.commentContents.uuid
                })!
                
                /*(self.parentTableViewController as! RantViewController).comments[(self.parentTableViewController as! RantViewController).comments.firstIndex(where: {
                    $0.uuid == self.commentContents.uuid
                })!]*/
                
                typeCastedController.comments.remove(at: commentIdx)
                typeCastedController.commentImages[self.commentContents.id] = nil
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.parentTableViewController?.navigationController?.navigationBar.tintColor = originalColor
                    
                    typeCastedController.tableView.deleteRows(at: [IndexPath(row: commentIdx, section: 1)], with: .fade)
                    
                    
                }
            } else {
                let failureAlertController = UIAlertController(title: "Error", message: "Failed to delete comment. Please try again later.", preferredStyle: .alert)
                
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                failureAlertController.addAction(UIAlertAction(title: "Retry", style: .destructive, handler: { _ in self.delete() }))
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.parentTableViewController?.navigationController?.navigationBar.tintColor = originalColor
                    
                    self.parentTableViewController?.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func handleUpvote(_ sender: UIButton) {
        var vote: Int {
            switch self.commentContents!.vote_state {
            case 0:
                return 1
                
            case 1:
                return 0
                
            default:
                return 1
            }
        }
        
        let success = APIRequest().voteOnComment(commentID: commentContents!.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            if let commentInFeed = self.commentInFeed {
                commentInFeed.wrappedValue.vote_state = vote
                commentInFeed.wrappedValue.score = success!.comment.score
                
                /*if let idx = (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                    $0.uuid == self.commentContents!.uuid
                }) {
                    (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].vote_state = success!.comment.vote_state
                    (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = success!.comment.score
                } else if let idx = (parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                    $0.uuid == self.commentContents!.uuid
                }) {
                    (parentTableViewController as? RantViewController)?.comments[idx].vote_state = success!.comment.vote_state
                    (parentTableViewController as? RantViewController)?.comments[idx].score = success!.comment.score
                }*/
            }
            
            if let idx = (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].vote_state = success!.comment.vote_state
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = success!.comment.score
            } else if let idx = (parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? RantViewController)?.comments[idx].vote_state = success!.comment.vote_state
                (parentTableViewController as? RantViewController)?.comments[idx].score = success!.comment.score
            }
            
            parentTableView?.reloadData()
        }
    }
    
    @IBAction func handleDownvote(_ sender: UIButton) {
        var vote: Int {
            switch self.commentContents!.vote_state {
            case 0:
                return -1
                
            case -1:
                return 0
                
            default:
                return -1
            }
        }
        
        let success = APIRequest().voteOnComment(commentID: self.commentContents!.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE DOWNVOTING")
        } else {
            if let commentInFeed = self.commentInFeed {
                commentInFeed.wrappedValue.vote_state = vote
                commentInFeed.wrappedValue.score = success!.comment.score
            }
            
            if let idx = (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].vote_state = success!.comment.vote_state
                (parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = success!.comment.score
                
                parentTableView?.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
            } else if let idx = (parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                $0.uuid == self.commentContents!.uuid
            }) {
                (parentTableViewController as? RantViewController)?.comments[idx].vote_state = success!.comment.vote_state
                (parentTableViewController as? RantViewController)?.comments[idx].score = success!.comment.score
                
                parentTableView?.reloadRows(at: [IndexPath(row: idx, section: 1)], with: .none)
            }
        }
    }
    
    @objc func handleImageTap(_ sender: UITapGestureRecognizer) {
        //guard parentTableViewController != nil || (parentTableViewController as? RantViewController) != nil else { return }
        
        let quickLookViewController = QLPreviewController()
        quickLookViewController.modalPresentationStyle = .overFullScreen
        quickLookViewController.dataSource = (parentTableViewController as! RantViewController)
        quickLookViewController.delegate = (parentTableViewController as! RantViewController)
        (parentTableViewController as! RantViewController).tappedComment = self
        
        //quickLookViewController.currentPreviewItemIndex = 1
        quickLookViewController.currentPreviewItemIndex = 0
        parentTableViewController?.present(quickLookViewController, animated: true)
    }
    
    @objc func handleUsernameTap(_ sender: UITapGestureRecognizer) {
        if let parentTableViewController = self.parentTableViewController {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: self.commentContents.user_id)
            })
            
            print(String(describing: type(of: parentTableViewController)))
            print(String(describing: type(of: self)))
            
            parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    /*func handleURLTap(result: TouchResult) {
        /*if let links = commentContents.links {
            for link in links {
                if link.start == nil && link.end == nil {
                    let range = (commentContents.body as NSString).range(of: link.title)
                    
                    if sender.didTapInsideWrappedTextInLabel(label: bodyLabel, range: range) {
                        if link.type == "url" {
                            UIApplication.shared.open(URL(string: link.url)!)
                        } else if link.type == "mention" {
                            if let parentTableViewController = self.parentTableViewController {
                                let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                                    return ProfileTableViewController(coder: coder, userID: Int(link.url)!)
                                })
                                
                                print(String(describing: type(of: parentTableViewController)))
                                print(String(describing: type(of: self)))
                                
                                parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
                            }
                        }
                    }
                } else {
                    let range = NSRange(location: link.start!, length: link.end! - link.start!)
                    
                    if sender.didTapInsideWrappedTextInLabel(label: bodyLabel, range: range) {
                        if link.type == "url" {
                            UIApplication.shared.open(URL(string: link.url)!)
                        } else if link.type == "mention" {
                            if let parentTableViewController = self.parentTableViewController {
                                let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                                    return ProfileTableViewController(coder: coder, userID: Int(link.url)!)
                                })
                                
                                print(String(describing: type(of: parentTableViewController)))
                                print(String(describing: type(of: self)))
                                
                                parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
                            }
                        }
                    }
                }
            }
        } else {
            debugPrint("Tapped on nothing")
        }*/
        
        if result.state == .ended {
            if let links = commentContents.links {
                for link in links {
                    if let linkResult = result.linkResult {
                        if linkResult.text == link.title {
                            if link.type == "url" {
                                UIApplication.shared.open(URL(string: link.url)!)
                            } else if link.type == "mention" {
                                if let parentTableViewController = self.parentTableViewController {
                                    let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                                        return ProfileTableViewController(coder: coder, userID: Int(link.url)!)
                                    })
                                    
                                    print(String(describing: type(of: parentTableViewController)))
                                    print(String(describing: type(of: self)))
                                    
                                    parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
                                    
                                    bodyLabel.attributedText = attributedBodyString
                                }
                            }
                        }
                    }
                }
            }
        }
    }*/
    
    @IBAction func reply(_ sender: Any) {
        let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
        
        (composeVC.viewControllers.first! as! ComposeViewController).content = "@\(commentContents.user_username) "
        (composeVC.viewControllers.first! as! ComposeViewController).rantID = commentContents.rant_id
        (composeVC.viewControllers.first! as! ComposeViewController).isComment = true
        (composeVC.viewControllers.first! as! ComposeViewController).isEdit = false
        (composeVC.viewControllers.first! as! ComposeViewController).viewControllerThatPresented = parentTableViewController
        
        composeVC.isModalInPresentation = true
        parentTableViewController?.present(composeVC, animated: true, completion: nil)
    }
    
    /*@objc func handleTap(_ sender: UITapGestureRecognizer) {
        if let parentTableViewController = self.parentTableViewController {
            let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(identifier: "RantViewController", creator: { coder in
                //let rant = try! APIRequest().getRantFromID(id: self.commentContents.rant_id)
                //var rantFile: File
                
                /*if let rantAttachedImage = rant!.rant.attached_image {
                    //DispatchQueue.global(qos: <#T##DispatchQoS.QoSClass#>)
                    rantFile = File.loadFile(image: rantAttachedImage, size: CGSize(width: rantAttachedImage.width!, height: rantAttachedImage.height!))
                }*/
                
                //let rantFile = File.loadFile(image: rant!.rant.attached_image, size: <#T##CGSize#>)
                
                return RantViewController(coder: coder, rantID: self.commentContents.rant_id, rantInFeed: nil, supplementalRantImage: nil, loadCompletionHandler: { tableViewController in
                    DispatchQueue.global(qos: .userInteractive).async {
                        /*for i in (tableViewController!.comments) {
                            print(i.id == self.commentContents.id)
                        }*/
                        
                        if let idx = tableViewController!.comments.firstIndex(where: {
                            $0.id == self.commentContents.id
                        }) {
                            DispatchQueue.main.async {
                                tableViewController!.tableView.scrollToRow(at: IndexPath(row: idx, section: 1), at: .middle, animated: true)
                            }
                        }
                        
                        /*if let indexPath = tableView!.indexPath(for: tableView!.getAllCells(at: 1).first(where: {
                            print(($0 as! CommentCell).commentContents.id)
                            print(self.commentContents.id)
                            
                            return ($0 as! CommentCell).commentContents.id == self.commentContents.id
                        })!) {
                            DispatchQueue.main.async {
                                tableView!.scrollToRow(at: indexPath, at: .middle, animated: true)
                            }
                        }*/
                    }
                })
            })
            
            parentTableViewController.navigationController?.pushViewController(rantVC, animated: true)
        }
    }*/
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
}
