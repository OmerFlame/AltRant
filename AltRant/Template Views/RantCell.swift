//
//  RantCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
//import SwiftUI
import QuickLook
import SwiftRant
import SwiftHEXColors

class RantCell: UITableViewCell, UITextViewDelegate, TagListViewDelegate {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    
    @IBOutlet weak var userProfileImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: PaddingLabel!
    
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UITextView!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    @IBOutlet weak var favoriteModifyButton: UIButton!
    
    var file: File?
    var savedPreviewImage: UIImage?
    var profile: Profile!
    var userImage: UIImage?
    var rantContents: Rant!
    //var rantInFeed: UnsafeMutablePointer<RantInFeed>!
    var parentTableViewController: RantViewController? = nil
    
    //var rantInFeed: RantInFeed?
    
    var delegate: RantViewControllerDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func testConfigure() {
        upvoteButton.tintColor = .systemGray
        downvoteButton.tintColor = .systemGray
        scoreLabel.text = "9999"
        
        bodyLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed in ligula vel mi cursus ultricies eu quis arcu. In hac habitasse platea dictumst. Nam ultricies sem congue pharetra gravida. Sed ut neque ut velit dapibus pharetra porttitor eget ipsum. In pellentesque sapien eu porta semper. Ut non justo condimentum sapien ultrices venenatis. Vivamus finibus lorem justo, feugiat tempor metus volutpat vitae."
        
        userProfileImageView.image = UIImage(named: "background_image")
        usernameLabel.text = "OmerFlame"
        userScoreLabel.text = "+9999"
        
        let resizeMultiplier = getImageResizeMultiplier(imageWidth: supplementalImageView.image!.size.width, imageHeight: supplementalImageView.image!.size.height, multiplier: 1)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: supplementalImageView.image!.size.width / resizeMultiplier, height: supplementalImageView.image!.size.height / resizeMultiplier), false, resizeMultiplier)
        supplementalImageView.image!.draw(in: CGRect(x: 0, y: 0, width: supplementalImageView.image!.size.width / resizeMultiplier, height: supplementalImageView.image!.size.height / resizeMultiplier))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        supplementalImageView.image = newImage
        //bodyLabel.text = "Lorem ipsum"
        
        //supplementalImageView.frame.size.width /= resizeMultiplier
        //supplementalImageView.frame.size.height /= resizeMultiplier
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        tagList.addTags(["This", "Is", "A", "Test"])
    }
    
    func configure(with model: Rant, userImage: UIImage?, supplementalImage: File?, profile: Profile, parentTableViewController: RantViewController?) {
        self.rantContents = model
        self.userImage = userImage
        self.profile = profile
        self.file = supplementalImage
        self.parentTableViewController = parentTableViewController
        
        /*if model.attached_image != nil {
            let resizeMultiplier = getImageResizeMultiplier(imageWidth: CGFloat(rantContents!.attached_image!.width!), imageHeight: CGFloat(rantContents!.attached_image!.height!), multiplier: 1)
            
            let finalWidth = CGFloat(rantContents!.attached_image!.width!) / resizeMultiplier
            let finalHeight = CGFloat(rantContents!.attached_image!.height!) / resizeMultiplier
            
            self.file = Optional(File.loadFile(image: rantContents!.attached_image!, size: CGSize(width: finalWidth, height: finalHeight)))
        }*/
        
        bodyLabel.text = rantContents!.text
        
        upvoteButton.tintColor = (model.voteState == .upvoted ? UIColor(hexString: model.userAvatar.backgroundColor)! : UIColor.systemGray)
        //scoreLabel.text = String(rantContents!.score)
        scoreLabel.text = formatNumber(rantContents!.score)
        downvoteButton.tintColor = (model.voteState == .downvoted ? UIColor(hexString: model.userAvatar.backgroundColor)! : UIColor.systemGray)
        
        if supplementalImage == nil {
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            if supplementalImageView.image == nil {
                print("Preview image is nil, generating!")
                
                print("TEXT STACK VIEW WIDTH: \(textStackView.frame.size.width)")
                
                let resizeMultiplier = supplementalImage!.size!.width / bodyLabel.frame.size.width
                
                let finalWidth = supplementalImage!.size!.width / resizeMultiplier
                let finalHeight = supplementalImage!.size!.height / resizeMultiplier
                
                print("FINAL WIDTH:  \(finalWidth)")
                print("FINAL HEIGHT: \(finalHeight)")
                
                UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
                UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                supplementalImageView.image = newImage
                
                supplementalImageView.frame.size.width = finalWidth
                supplementalImageView.frame.size.height = finalHeight
                
                /*var resizeMultiplier = getImageResizeMultiplier(imageWidth: supplementalImage!.size!.width, imageHeight: supplementalImage!.size!.height, multiplier: 1)
                
                //let previewImage = supplementalImage!.getThumbnail(size: CGSize(width: supplementalImage!.size!.width / resizeMultiplier, height: supplementalImage!.size!.height / resizeMultiplier))
                
                //supplementalImageView.image = previewImage
                
                if resizeMultiplier == 1 {
                    resizeMultiplier = supplementalImage!.size!.width / textStackView.frame.size.width
                    
                    let finalWidth = supplementalImage!.size!.width / resizeMultiplier
                    let finalHeight = supplementalImage!.size!.height / resizeMultiplier
                    
                    print("FINAL WIDTH:  \(finalWidth)")
                    print("FINAL HEIGHT: \(finalHeight)")
                    
                    UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, 1)
                    UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    supplementalImageView.image = newImage
                } else {
                    let imagePreview = supplementalImage!.getThumbnail(size: CGSize(width: supplementalImage!.size!.width / resizeMultiplier, height: supplementalImage!.size!.height / resizeMultiplier))
                    
                    
                    supplementalImageView.image = imagePreview
                }*/
            }
            //supplementalImageView.frame.size = supplementalImage!.size
        }
        
        upvoteButton.isEnabled = rantContents!.voteState != .unvotable
        downvoteButton.isEnabled = rantContents!.voteState != .unvotable
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        tagList.addTags(rantContents!.tags)
        tagList.delegate = self
        
        if rantContents!.userAvatar.avatarImage == nil {
            userProfileImageView.image = UIImage(color: UIColor(hexString: rantContents!.userAvatar.backgroundColor)!, size: CGSize(width: 45, height: 45))
        } else {
            let resourceURL = URL(string: "https://avatars.devrant.com/" + rantContents!.userAvatar.avatarImage!)!
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var imageData: Data? = nil
            
            URLSession.shared.dataTask(with: resourceURL) { data, response, error in
                imageData = data ?? nil
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            userProfileImageView.image = UIImage(data: imageData ?? Data()) ?? nil
        }
        
        usernameLabel.text = rantContents!.username
        
        if rantContents!.score < 0 {
            userScoreLabel.text = String(rantContents!.userScore)
        } else {
            userScoreLabel.text = "+\(rantContents!.userScore)"
        }
        
        userScoreLabel.backgroundColor = UIColor(hexString: rantContents!.userAvatar.backgroundColor)
        
        scoreLabel.text = String(rantContents!.score)
        
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        let userGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUserTap(_:)))
        
        if rantContents.userID == SwiftRant.shared.tokenFromKeychain!.authToken.userID {
            favoriteModifyButton.setTitle("Modify", for: .normal)
            
            let actionsMenu = UIMenu(title: "", children: [
                                        UIAction(title: "Edit", image: UIImage(systemName: "square.and.pencil")!) { action in
                                            if Double(Date().timeIntervalSince1970) - Double(self.rantContents.createdTime) >= 300 {
                                                let alert = UIAlertController(title: "Editing Disabled", message: "Rants and comments can only be edited for 5 mins (30 mins for devRant++ subscribers) after they are posted.", preferredStyle: .alert)
                                                
                                                alert.addAction(UIAlertAction(title: "Got it", style: .default, handler: nil))
                                                
                                                self.parentTableViewController?.present(alert, animated: true, completion: nil)
                                            } else {
                                                let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
                                                (composeVC.viewControllers.first as! ComposeViewController).rantID = self.rantContents.id
                                                (composeVC.viewControllers.first as! ComposeViewController).isComment = false
                                                (composeVC.viewControllers.first as! ComposeViewController).isEdit = true
                                                (composeVC.viewControllers.first as! ComposeViewController).content = self.rantContents.text
                                                //(composeVC.viewControllers.first as! ComposeViewController).inputImage = UIImage(contentsOfFile: self.file?.previewItemURL.relativePath ?? "")
                                                
                                                var sanitizedTagArray = self.rantContents.tags
                                                sanitizedTagArray.remove(at: sanitizedTagArray.firstIndex(where: {
                                                    $0 == "rant" || $0 == "joke/meme" || $0 == "question" || $0 == "collab" || $0 == "devrant" || $0 == "random"
                                                })!)
                                                
                                                (composeVC.viewControllers.first as! ComposeViewController).tags = sanitizedTagArray.joined(separator: ",")
                                                
                                                if self.rantContents.tags.contains("rant") {
                                                    (composeVC.viewControllers.first as! ComposeViewController).rantType = .rant
                                                } else if self.rantContents.tags.contains("joke/meme") {
                                                    (composeVC.viewControllers.first as! ComposeViewController).rantType = .meme
                                                } else if self.rantContents.tags.contains("question") {
                                                    (composeVC.viewControllers.first as! ComposeViewController).rantType = .question
                                                } else if self.rantContents.tags.contains("devrant") {
                                                    (composeVC.viewControllers.first as! ComposeViewController).rantType = .question
                                                } else {
                                                    (composeVC.viewControllers.first as! ComposeViewController).rantType = .random
                                                }
                                                
                                                (composeVC.viewControllers.first as! ComposeViewController).viewControllerThatPresented = self.parentTableViewController
                                                
                                                composeVC.isModalInPresentation = true
                                                
                                                self.parentTableViewController!.present(composeVC, animated: true, completion: nil)
                                            }
                                        },
                
                                        UIAction(title: "Delete", image: UIImage(systemName: "trash")!) { action in
                                            let alert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this rant?", preferredStyle: .alert)
                                            
                                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                                            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.delete() }))
                                            
                                            self.parentTableViewController?.present(alert, animated: true, completion: nil)
                                        }
            ])
            
            favoriteModifyButton.showsMenuAsPrimaryAction = true
            favoriteModifyButton.menu = actionsMenu
        } else {
            //favoriteModifyButton.setTitle("Favorite", for: .normal)
            if rantContents.isFavorite == nil {
                favoriteModifyButton.setTitle("Favorite", for: .normal)
                favoriteModifyButton.addTarget(self, action: #selector(handleFavorite), for: .touchUpInside)
            } else {
                favoriteModifyButton.setTitle("Unfavorite", for: .normal)
                favoriteModifyButton.addTarget(self, action: #selector(handleFavorite), for: .touchUpInside)
            }
        }
        
        if let links = rantContents.links {
            
            if let parentTableViewController = parentTableViewController {
                bodyLabel.attributedText = parentTableViewController.textsWithLinks[rantContents.id]
            }
            
            bodyLabel.isUserInteractionEnabled = true
            bodyLabel.delegate = self
        }
        
        supplementalImageView.addGestureRecognizer(imageGestureRecognizer)
        userStackView.addGestureRecognizer(userGestureRecognizer)
        
        if let gestureRecognizers = bodyLabel.gestureRecognizers {
            print("GESTURE RECOGNIZERS IN BODY LABEL FOUND! SEARCHING DOUBLE TAP...")
            
            for (idx, gestureRecognizer) in gestureRecognizers.enumerated() {
                if gestureRecognizer is UITapGestureRecognizer && (gestureRecognizer as! UITapGestureRecognizer).numberOfTapsRequired > 1 {
                    print("FOUND DOUBLE+ TAP! NUMBER OF TAPS REQUIRED: \((gestureRecognizer as! UITapGestureRecognizer).numberOfTapsRequired)")
                    //bodyLabel.removeGestureRecognizer(gestureRecognizer)
                    
                    let newDoubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
                    newDoubleTapGesture.numberOfTapsRequired = 2
                    bodyLabel.addGestureRecognizer(newDoubleTapGesture)
                    
                    
                    gestureRecognizer.removeTarget(nil, action: nil)
                    gestureRecognizer.require(toFail: newDoubleTapGesture)
                    
                    print(gestureRecognizer.debugDescription)
                    
                    print("---------------------------")
                }
            }
        }
        
        //layoutSubviews()
    }
    
    @objc func handleFavorite() {
        if rantContents.isFavorite == nil {
            //let success = APIRequest().favoriteRant(rantID: rantContents.id)
            
            /*SwiftRant.shared.favoriteRant(nil, rantID: rantContents.id) { [weak self] _, success in
                if success {
                    self?.parentTableViewController?.rant?.isFavorite = 1
                    
                    self?.parentTableViewController?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            }*/
            
            delegate?.didFavoriteRant(withID: rantContents.id, cell: self)
        } else {
            //let success = APIRequest().unfavoriteRant(rantID: rantContents.id)
            
            /*SwiftRant.shared.unfavoriteRant(nil, rantID: rantContents.id) { [weak self] _, success in
                if success {
                    self?.parentTableViewController?.rant?.isFavorite = nil
                    
                    self?.parentTableViewController?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            }*/
            
            delegate?.didUnfavoriteRant(withID: rantContents.id, cell: self)
        }
    }
    
    @objc func didDoubleTap() {
        guard rantContents.voteState != .upvoted && rantContents.voteState != .unvotable else {
            return
        }
        
        delegate?.changeRantVoteState(voteState: .upvoted)
        delegate?.changeRantScore(score: rantContents!.score + VoteState.upvoted.rawValue)
        
        DispatchQueue.main.async {
            self.delegate?.reloadData()
        }
        
        delegate?.didVoteOnRant(withID: rantContents.id, vote: .upvoted, cell: self)
    }
    
    func delete() {
        self.parentTableViewController?.navigationItem.leftBarButtonItem?.isEnabled = false
        self.parentTableViewController?.navigationItem.rightBarButtonItem?.isEnabled = false
        
        self.parentTableViewController?.navigationItem.rightBarButtonItems![0].isEnabled = false
        self.parentTableViewController?.navigationItem.rightBarButtonItems![1].isEnabled = false
        
        let originalTitle = self.parentTableViewController?.title
        
        self.parentTableViewController?.title = "Deleting..."
        
        delegate?.didDeleteRant(withID: rantContents.id)
        
        /*SwiftRant.shared.deleteRant(nil, rantID: rantContents.id) { error, success in
            if success {
                let successAlertController = UIAlertController(title: "Success", message: "Rant successfully deleted!", preferredStyle: .alert)
                
                successAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    let navigationController = self.parentTableViewController?.navigationController
                    
                    self.parentTableViewController?.navigationController?.popViewController(animated: true) {
                        
                        navigationController?.topViewController?.present(successAlertController, animated: true, completion: nil)
                    }
                }
            } else {
                let failureAlertController = UIAlertController(title: "Error", message: error ?? "An unknown error occurred while deleting the rant.", preferredStyle: .alert)
                
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                failureAlertController.addAction(UIAlertAction(title: "Retry", style: .destructive, handler: { _ in self.delete() }))
                
                DispatchQueue.main.async {
                    self.parentTableViewController?.title = originalTitle
                    self.parentTableViewController?.navigationItem.leftBarButtonItem?.isEnabled = true
                    self.parentTableViewController?.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    self.parentTableViewController?.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }*/
    }
    
    /*override func layoutSubviews() {
        super.layoutSubviews()
        
        print("IMAGE FRAME Y:  \(supplementalImageView.frame.minY)")
        print("IMAGE BOUNDS Y: \(supplementalImageView.bounds.minY)")
    }*/
    
    @IBAction func upvote(_ sender: UIButton) {
        var vote: VoteState {
            switch self.rantContents!.voteState {
            case .unvoted:
                return .upvoted
                
            case .upvoted:
                return .unvoted
                
            default:
                return .upvoted
            }
        }
        
        //let success = APIRequest().voteOnRant(rantID: self.rantContents!.id, vote: vote)
        
        delegate?.changeRantVoteState(voteState: vote)
        delegate?.changeRantScore(score: rantContents!.voteState == .upvoted ? rantContents!.score - 1 : rantContents!.score + vote.rawValue)
        
        DispatchQueue.main.async {
            self.delegate?.reloadData()
        }
        
        delegate?.didVoteOnRant(withID: rantContents.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: rantContents.id, vote: vote) { [weak self] error, updatedRant in
            if let updatedRant = updatedRant {
                if let rantInFeed = self?.rantInFeed {
                    rantInFeed.pointee.voteState = vote
                    rantInFeed.pointee.score = updatedRant.score
                }
                
                if let parentTableViewController = self?.parentTableViewController {
                    parentTableViewController.rant?.voteState = updatedRant.voteState
                    parentTableViewController.rant?.score = updatedRant.score
                    
                    DispatchQueue.main.async {
                        parentTableViewController.tableView.reloadData()
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error occurred while voting on the rant.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }*/
        
        /*if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            if rantInFeed != nil {
                rantInFeed!.pointee.voteState = vote
                rantInFeed!.pointee.score = success!.rant.score
            }
            //parentTableViewController?.rant!.voteState = vote
            
            if parentTableViewController != nil {
                parentTableViewController?.rant!.voteState = success!.rant.voteState
                parentTableViewController?.rant!.score = success!.rant.score
            }
            
            if let parentTableViewController = self.parentTableViewController {
                parentTableViewController.tableView.reloadData()
            }
        }*/
    }
    
    @IBAction func downvote(_ sender: UIButton) {
        var vote: VoteState {
            switch self.rantContents!.voteState {
            case .unvoted:
                return .downvoted
                
            case .downvoted:
                return .unvoted
                
            default:
                return .downvoted
            }
        }
        
        delegate?.changeRantVoteState(voteState: vote)
        delegate?.changeRantScore(score: rantContents!.voteState == .upvoted ? rantContents!.score - 1 : rantContents!.score + vote.rawValue)
        
        DispatchQueue.main.async {
            self.delegate?.reloadData()
        }
        
        delegate?.didVoteOnRant(withID: rantContents.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: rantContents.id, vote: vote) { [weak self] error, updatedRant in
            if let updatedRant = updatedRant {
                if let rantInFeed = self?.rantInFeed {
                    rantInFeed.pointee.voteState = vote
                    rantInFeed.pointee.score = updatedRant.score
                }
                
                if let parentTableViewController = self?.parentTableViewController {
                    parentTableViewController.rant?.voteState = updatedRant.voteState
                    parentTableViewController.rant?.score = updatedRant.score
                    
                    DispatchQueue.main.async {
                        parentTableViewController.tableView.reloadData()
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error occurred while voting on the rant.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }*/
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
    
    @objc func handleImageTap(_ sender: UITapGestureRecognizer) {
        guard parentTableViewController != nil else { return }
        
        let quickLookViewController = QLPreviewController()
        quickLookViewController.modalPresentationStyle = .overFullScreen
        quickLookViewController.dataSource = parentTableViewController
        quickLookViewController.delegate = parentTableViewController
        parentTableViewController!.tappedRant = self
        
        quickLookViewController.currentPreviewItemIndex = 0
        parentTableViewController?.present(quickLookViewController, animated: true)
    }
    
    @objc func handleUserTap(_ sender: UITapGestureRecognizer) {
        if let parentTableViewController = self.parentTableViewController {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: self.rantContents.userID)
            })
            
            parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        guard let weekly = rantContents.weekly, title == "wk\(weekly.week)" else {
            return
        }
        
        let vc: WeeklyRantFeedViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "WeeklyRantFeedViewController", creator: { coder in
            return WeeklyRantFeedViewController(coder: coder)
        })
        
        vc.week = weekly.week
        
        parentTableViewController?.navigationController?.pushViewController(vc, animated: true)
    }
}
