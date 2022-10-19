//
//  RantInSubscribedFeedCell.swift
//  AltRant
//
//  Created by Omer Shamai on 23/02/2022.
//

import UIKit
import SwiftRant
import SwiftHEXColors

class RantInSubscribedFeedCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UITextView!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingUserActionImageView: RoundedImageView!
    @IBOutlet weak var trailingUserActionImageView: RoundedImageView!
    @IBOutlet weak var userActionDescriptionLabel: UILabel!
    @IBOutlet weak var trailingUserActionImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentCountLabel: UIButton!
    
    var rantContents: RantInSubscribedFeed? = nil
    //var subscribedFeed: UnsafeMutablePointer<SubscribedFeed>? = nil
    var parentTableViewController: UIViewController? = nil
    var parentTableView: UITableView? = nil
    var leadingUserActionImage: UIImage?
    var trailingUserActionImage: UIImage?
    
    var delegate: FeedDelegate?
    
    var supplementalImage: File?
    
    var loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    //var userAvatarData: Rant.UserAvatar? = nil
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        leadingUserActionImage = nil
        trailingUserActionImage = nil
        leadingUserActionImageView.image = nil
        trailingUserActionImageView.image = nil
        userActionDescriptionLabel.text = nil
        supplementalImageView.image = nil
        supplementalImage = nil
        bodyLabel.text = nil
        commentCountLabel.isHidden = true
    }
    
    func configure(feedOffset: Int, rantOffset: Int, image: File?, leadingUserActionImage: UIImage?, trailingUserActionImage: UIImage?, parentTableViewController: UIViewController?, parentTableView: UITableView?) {
        self.parentTableViewController = parentTableViewController
        self.parentTableView = parentTableView
        self.supplementalImage = image
        self.leadingUserActionImage = leadingUserActionImage
        self.trailingUserActionImage = trailingUserActionImage
        //self.rantContents = model
        //self.subscribedFeed = subscribedFeed
        //self.userAvatarData = userAvatarData
        
        //var subscribedFeed: UnsafeMutablePointer<SubscribedFeed>? = nil
        
        let subscribedFeed = (parentTableViewController as! SubscribedFeedViewController).subscribedFeed[feedOffset]
        
        self.rantContents = (parentTableViewController as! SubscribedFeedViewController).subscribedFeed[feedOffset].rants[rantOffset]
        
        /*withUnsafeMutablePointer(to: &(parentTableViewController as! SubscribedFeedViewController).subscribedFeed[feedOffset]) { ptr in
            subscribedFeed = ptr
        }*/
        
        if loadingIndicator.isDescendant(of: contentView) {
            loadingIndicator.removeFromSuperview()
        }
        
        upvoteButton.isHidden = false
        scoreLabel.isHidden = false
        downvoteButton.isHidden = false
        textStackView.isHidden = false
        bodyLabel.isHidden = false
        supplementalImageView.isHidden = false
        tagList.isHidden = false
        leadingUserActionImageView.isHidden = false
        trailingUserActionImageView.isHidden = false
        userActionDescriptionLabel.isHidden = false
        commentCountLabel.isHidden = rantContents!.commentCount == 0
        
        upvoteButton.tintColor = (rantContents!.voteState == .upvoted ? UIColor(hexString: "c65a64")! : UIColor.systemGray)
        scoreLabel.text = String(rantContents!.score)
        downvoteButton.tintColor = (rantContents!.voteState == .downvoted ? UIColor(hexString: "c65a64")! : UIColor.systemGray)
        
        upvoteButton.isEnabled = rantContents!.voteState != .unvotable
        downvoteButton.isEnabled = rantContents!.voteState != .unvotable
        
        upvoteButton.isUserInteractionEnabled = rantContents!.voteState != .unvotable
        downvoteButton.isUserInteractionEnabled = rantContents!.voteState != .unvotable
        
        if image == nil {
            supplementalImageView.image = nil
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            
            supplementalImageView.translatesAutoresizingMaskIntoConstraints = false
            
            supplementalImageView.image = UIImage(contentsOfFile: image!.previewItemURL.relativePath)!
            
            let resizeMultiplier = supplementalImageView.frame.size.width / supplementalImageView.image!.size.width
            
            let finalHeight = supplementalImageView.image!.size.height * resizeMultiplier
            
            imageViewHeightConstraint.constant = finalHeight
            
            NotificationCenter.default.addObserver(self, selector: #selector(windowResizeHandler), name: windowResizeNotification, object: nil)
        }
        
        if rantContents!.text.count > 240 {
            bodyLabel.text = rantContents!.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents!.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        
        print("TAGS: \(rantContents!.tags)")
        print("---------------------------------------------")
        
        tagList.addTags(rantContents!.tags)
        
        leadingUserActionImageView.image = self.leadingUserActionImage
        
        //var leadingActionUserID = rantContents!.relatedUserActions[0].userID
        
        /*if rantContents!.relatedUserActions.count == 2 {
            trailingUserActionImageLeadingConstraint.constant = -6.5
            trailingUserActionImageView.image = self.trailingUserActionImage
        } else {
            trailingUserActionImageLeadingConstraint.constant = -26
            trailingUserActionImageView.image = nil
        }*/
        
        if self.trailingUserActionImage == nil {
            trailingUserActionImageLeadingConstraint.constant = -26
            trailingUserActionImageView.image = nil
        } else {
            trailingUserActionImageLeadingConstraint.constant = -6.5
            trailingUserActionImageView.image = self.trailingUserActionImage
        }
        
        let caption2FontSize = UIFont.preferredFont(forTextStyle: .caption2).pointSize
        
        var usernamePortionString = ""
        
        /*usernamePortionString += self.subscribedFeed!.pointee.usernameMap.users.first(where: { $0.userID == self.rantContents!.pointee.relatedUserActions[0].userID })!.username
        
        if self.rantContents!.pointee.relatedUserActions.count == 2 {
            if self.rantContents!.pointee.relatedUserActions[1].userID != self.rantContents!.pointee.relatedUserActions[0].userID {
                usernamePortionString += " & \(self.subscribedFeed!.pointee.usernameMap.users.first(where: { $0.userID == self.rantContents!.pointee.relatedUserActions[1].userID })!.username)"
            }
        }*/
        
        for (idx, action) in self.rantContents!.relatedUserActions.enumerated() {
            if idx == 0 {
                usernamePortionString += subscribedFeed.usernameMap.users.first(where: { $0.userID == action.userID })!.username
            } else {
                if usernamePortionString.contains(subscribedFeed.usernameMap.users.first(where: { $0.userID == action.userID })!.username) {
                    continue
                } else {
                    usernamePortionString += " & \(subscribedFeed.usernameMap.users.first(where: { $0.userID == action.userID })!.username)"
                }
            }
        }
        
        var actionPortionString = ""
        
        for (idx, action) in self.rantContents!.relatedUserActions.enumerated() {
            if idx == 0 {
                switch action.action {
                case .posted:
                    actionPortionString += "posted"
                    break
                case .commentedOn:
                    actionPortionString += "commented on"
                    break
                case .liked:
                    actionPortionString += "liked"
                    break
                }
            } else {
                switch action.action {
                case .posted:
                    if !actionPortionString.contains("posted") {
                        actionPortionString += " & posted"
                    }
                    break
                    
                case .commentedOn:
                    if !actionPortionString.contains("commented on") {
                        actionPortionString += " & commented on"
                    }
                    break
                
                case .liked:
                    if !actionPortionString.contains("liked") {
                        actionPortionString += " & liked"
                    }
                    break
                }
            }
        }
        
        actionPortionString += " this rant"
        
        let combinedDescriptionString = "\(usernamePortionString) \(actionPortionString)"
        
        var attributedDescriptionString = NSMutableAttributedString(string: combinedDescriptionString)
        
        attributedDescriptionString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: caption2FontSize, weight: .semibold), range: (combinedDescriptionString as NSString).range(of: usernamePortionString))
        
        userActionDescriptionLabel.attributedText = attributedDescriptionString
        
        layoutIfNeeded()
    }
    
    @IBAction func handleUpvote(_ sender: Any) {
        var vote: VoteState {
            switch self.rantContents!.voteState {
            case .unvoted:
                return.upvoted
                
            case .upvoted:
                return .unvoted
                
            default:
                return .upvoted
            }
        }
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents!.id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                self?.rantContents!.voteState = updatedRant!.voteState
                self?.rantContents!.score = updatedRant!.score
                
                if let parentTableView = self?.parentTableView {
                    DispatchQueue.main.async {
                        parentTableView.reloadData()
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }*/
        
        delegate?.didVoteOnRant(withID: rantContents!.id, vote: vote, cell: self)
    }
    
    @IBAction func handleDownvote(_ sender: Any) {
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
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents!.id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                self?.rantContents!.voteState = updatedRant!.voteState
                self?.rantContents!.score = updatedRant!.score
                
                if let parentTableView = self?.parentTableView {
                    DispatchQueue.main.async {
                        parentTableView.reloadData()
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
                }
            }
        }*/
        
        delegate?.didVoteOnRant(withID: rantContents!.id, vote: vote, cell: self)
    }
    
    @objc func windowResizeHandler() {
        guard supplementalImageView.image != nil else {
            return
        }
        
        let resizeMultiplier = supplementalImageView.frame.size.width / supplementalImageView.image!.size.width
        
        let finalHeight = supplementalImageView.image!.size.height * resizeMultiplier
        
        imageViewHeightConstraint.constant = finalHeight
        
        layoutIfNeeded()
    }
}
