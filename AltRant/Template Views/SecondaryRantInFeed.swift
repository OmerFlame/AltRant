//
//  SecondaryRantInFeed.swift
//  AltRant
//
//  Created by Omer Shamai on 2/7/21.
//

import UIKit
import QuickLook
import SwiftRant
import SwiftHEXColors

class SecondaryRantInFeedCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UITextView!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    var rantContents: RantInFeed? = nil
    var parentTableViewController: UIViewController? = nil
    var parentTableView: UITableView? = nil
    
    var supplementalImage: File?
    
    var loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    var delegate: FeedDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }*/
    
    func configureLoading() {
        upvoteButton.isHidden = true
        scoreLabel.isHidden = true
        downvoteButton.isHidden = true
        textStackView.isHidden = true
        bodyLabel.isHidden = true
        supplementalImageView.isHidden = true
        tagList.isHidden = true
        
        contentView.addSubview(loadingIndicator)
        
        loadingIndicator.startAnimating()
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        //loadingIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        //loadingIndicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        
        loadingIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -40).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 40).isActive = true
        
        layoutIfNeeded()
        //loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 40).isActive = true
        
        //loadingIndicator.hidesWhenStopped = true
    }
    
    func configure(with model: RantInFeed?, image: File?, parentTableViewController: UIViewController?, parentTableView: UITableView?) {
        self.parentTableViewController = parentTableViewController
        self.parentTableView = parentTableView
        self.supplementalImage = image
        self.rantContents = model
        
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
        
        upvoteButton.tintColor = (rantContents!.voteState == 1 ? UIColor(hexString: rantContents!.userAvatar.backgroundColor)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents!.score)
        downvoteButton.tintColor = (rantContents!.voteState == -1 ? UIColor(hexString: rantContents!.userAvatar.backgroundColor)! : UIColor.systemGray)
        
        upvoteButton.isEnabled = rantContents!.voteState != -2
        downvoteButton.isEnabled = rantContents!.voteState != -2
        
        if image == nil {
            supplementalImageView.image = nil
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            /*let resizeMultiplier = supplementalImage!.size!.width / textStackView.frame.size.width
            
            let finalWidth = supplementalImage!.size!.width / resizeMultiplier
            let finalHeight = supplementalImage!.size!.height / resizeMultiplier
            
            print("FINAL WIDTH:  \(finalWidth)")
            print("FINAL HEIGHT: \(finalHeight)")
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
            UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()*/
            
            /*let resizeMultiplier = supplementalImage!.size!.width / textStackView.frame.size.width
            
            let finalWidth = supplementalImage!.size!.width / resizeMultiplier
            let finalHeight = supplementalImage!.size!.height / resizeMultiplier
            
            if finalHeight < 420 && UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.size.width > textStackView.frame.size.width {
                UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
                UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                supplementalImageView.image = newImage
            } else {
                supplementalImageView.image = UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!
            }*/
            
            //let resizeMultiplier = supplementalImage!.size!.width / textStackView.frame.size.width
            
            //let finalWidth = supplementalImage!.size!.width / resizeMultiplier
            //let finalHeight = supplementalImage!.size!.height / resizeMultiplier
            
            supplementalImageView.translatesAutoresizingMaskIntoConstraints = false
            
            supplementalImageView.image = UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!
            
            //imageViewHeightConstraint.constant = supplementalImageView.frame.size.width / supplementalImageView.image!.size.width * supplementalImageView.image!.size.height
            
            //supplementalImageView.frame.size = CGSize(width: finalWidth, height: finalHeight)
            
            //imageViewHeightConstraint.constant = finalHeight
            
            let resizeMultiplier = supplementalImageView.frame.size.width / supplementalImageView.image!.size.width
            
            let finalHeight = supplementalImageView.image!.size.height * resizeMultiplier
            
            imageViewHeightConstraint.constant = finalHeight
            
            print("IMAGE FRAME: \(supplementalImageView.frame.size)")
            
            NotificationCenter.default.addObserver(self, selector: #selector(windowResizeHandler), name: windowResizeNotification, object: nil)
            
            /*if UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.size.width > textStackView.frame.size.width {
                UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
                UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                supplementalImageView.image = newImage
            } else {
                supplementalImageView.image = UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!
            }*/
            
            //supplementalImageView.image = UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!
        }
        
        upvoteButton.isUserInteractionEnabled = rantContents!.voteState != -2
        downvoteButton.isUserInteractionEnabled = rantContents!.voteState != -2
        
        if rantContents!.text.count > 240 {
            bodyLabel.text = rantContents!.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents!.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        tagList.addTags(rantContents!.tags)
        
        layoutIfNeeded()
    }
    
    @IBAction func handleUpvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.voteState {
            case 0:
                return 1
                
            case 1:
                return 0
                
            default:
                return 1
            }
        }
        
        /*let success = APIRequest().voteOnRant(rantID: self.rantContents!.pointee.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            self.rantContents!.pointee.vote_state = success!.rant.vote_state
            self.rantContents!.pointee.score = success!.rant.score
            
            if let parentTableView = self.parentTableView {
                parentTableView.reloadData()
            }
        }*/
        
        delegate?.didVoteOnRant(withID: rantContents!.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents!.pointee.id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                self?.rantContents!.pointee.voteState = updatedRant!.voteState
                self?.rantContents!.pointee.score = updatedRant!.score
                
                if let parentTableView = self?.parentTableView {
                    parentTableView.reloadData()
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
            }
        }*/
    }
    
    @IBAction func handleDownvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.voteState {
            case 0:
                return -1
                
            case -1:
                return 0
                
            default:
                return -1
            }
        }
        
        delegate?.didVoteOnRant(withID: rantContents!.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents!.pointee.id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                self?.rantContents!.pointee.voteState = updatedRant!.voteState
                self?.rantContents!.pointee.score = updatedRant!.score
                
                if let parentTableView = self?.parentTableView {
                    parentTableView.reloadData()
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
            }
        }*/
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
