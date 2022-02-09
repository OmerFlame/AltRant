//
//  RantInFeedCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import QuickLook
import SwiftRant
//import SwiftUI

class RantInFeedCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    
    //var rantContents: Binding<RantInFeed>? = nil
    var rantContents: UnsafeMutablePointer<RantInFeed>? = nil
    var parentTableViewController: UIViewController? = nil
    var parentTableView: UITableView? = nil
    
    var supplementalImage: File?
    
    /*init?(coder: NSCoder, rantContents: Binding<RantInFeed>, image: UIImage?, parentTableViewController: UITableViewController?) {
        self.parentTableViewController = parentTableViewController
        self.rantContents = rantContents
        
        super.init(coder: coder)
        
        upvoteButton.tintColor = (rantContents.wrappedValue.vote_state == 1 ? UIColor(hex: rantContents.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents.wrappedValue.score + rantContents.wrappedValue.vote_state)
        downvoteButton.tintColor = (rantContents.wrappedValue.vote_state == -1 ? UIColor(hex: rantContents.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        
        if image == nil {
            supplementalImageView.isHidden = true
        } else {
            //let resizeMultiplier = getImageResizeMultiplier(imageWidth: image!.size.width, imageHeight: image!.size.height, multiplier: 1)
            
            //UIGraphicsBeginImageContextWithOptions(CGSize(width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier), false, CGFloat(1 / resizeMultiplier))
            //image!.draw(in: CGRect(x: 0, y: 0, width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier))
            //let newImage = UIGraphicsGetImageFromCurrentImageContext()
            //UIGraphicsEndImageContext()
            
            supplementalImageView.image = image
        }
        
        upvoteButton.isUserInteractionEnabled = rantContents.wrappedValue.vote_state != -2
        downvoteButton.isUserInteractionEnabled = rantContents.wrappedValue.vote_state != -2
        
        //bodyLabel.text = model.wrappedValue.text
        
        if rantContents.wrappedValue.text.count > 240 {
            bodyLabel.text = rantContents.wrappedValue.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents.wrappedValue.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        tagList.addTags(rantContents.wrappedValue.tags)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }*/
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(with model: UnsafeMutablePointer<RantInFeed>?, image: File?, parentTableViewController: UIViewController?, parentTableView: UITableView?) {
        self.parentTableViewController = parentTableViewController
        self.parentTableView = parentTableView
        self.supplementalImage = image
        self.rantContents = model
        
        upvoteButton.tintColor = (rantContents!.pointee.voteState == 1 ? UIColor(hex: rantContents!.pointee.userAvatar.backgroundColor)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents!.pointee.score)
        downvoteButton.tintColor = (rantContents!.pointee.voteState == -1 ? UIColor(hex: rantContents!.pointee.userAvatar.backgroundColor)! : UIColor.systemGray)
        
        upvoteButton.isEnabled = rantContents!.pointee.voteState != -2
        downvoteButton.isEnabled = rantContents!.pointee.voteState != -2
        
        //let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        //textStackView.addGestureRecognizer(gestureRecognizer)
        
        if image == nil {
            supplementalImageView.image = nil
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            supplementalImageView.image = nil
            
            let resizeMultiplier = supplementalImage!.size!.width / textStackView.frame.size.width
            
            let finalWidth = supplementalImage!.size!.width / resizeMultiplier
            let finalHeight = supplementalImage!.size!.height / resizeMultiplier
            
            print("FINAL WIDTH:  \(finalWidth)")
            print("FINAL HEIGHT: \(finalHeight)")
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, resizeMultiplier)
            UIImage(contentsOfFile: supplementalImage!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            supplementalImageView.image = newImage
            
            //var resizeMultiplier = getImageResizeMultiplier(imageWidth: image!.size!.width, imageHeight: image!.size!.height, multiplier: 1)
            
            /*if resizeMultiplier == 1 {
                resizeMultiplier = image!.size!.width / textStackView.frame.size.width
                
                let finalWidth = image!.size!.width / resizeMultiplier
                let finalHeight = image!.size!.height / resizeMultiplier
                
                print("FINAL WIDTH:  \(finalWidth)")
                print("FINAL HEIGHT: \(finalHeight)")
                
                UIGraphicsBeginImageContextWithOptions(CGSize(width: finalWidth, height: finalHeight), false, 1)
                UIImage(contentsOfFile: image!.previewItemURL.relativePath)!.draw(in: CGRect(origin: .zero, size: CGSize(width: finalWidth, height: finalHeight)))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                supplementalImageView.image = newImage
            } else {
                let imagePreview = image!.getThumbnail(size: CGSize(width: image!.size!.width / resizeMultiplier, height: image!.size!.height / resizeMultiplier))
                
                
                supplementalImageView.image = imagePreview
            }*/
            
            //UIGraphicsBeginImageContextWithOptions(CGSize(width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier), false, CGFloat(1 / resizeMultiplier))
            //image!.draw(in: CGRect(x: 0, y: 0, width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier))
            //let newImage = UIGraphicsGetImageFromCurrentImageContext()
            //UIGraphicsEndImageContext()
            
            /*if supplementalImageView.image == nil || __CGSizeEqualToSize(supplementalImageView.image!.size, .zero) {
                print("Preview image is nil, generating!")
                
                let resizeMultiplier = getImageResizeMultiplier(imageWidth: image!.size!.width, imageHeight: image!.size!.height, multiplier: 1)
                
                //UIGraphicsBeginImageContextWithOptions(CGSize(width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier), false, CGFloat(1 / resizeMultiplier))
                //image!.draw(in: CGRect(x: 0, y: 0, width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier))
                //let newImage = UIGraphicsGetImageFromCurrentImageContext()
                //UIGraphicsEndImageContext()
                
                let imagePreview = image!.getThumbnail(size: CGSize(width: image!.size!.width / resizeMultiplier, height: image!.size!.height / resizeMultiplier))
                
                
                supplementalImageView.image = imagePreview
            }*/
        }
        
        upvoteButton.isUserInteractionEnabled = rantContents!.pointee.voteState != -2
        downvoteButton.isUserInteractionEnabled = rantContents!.pointee.voteState != -2
        
        //bodyLabel.text = model.wrappedValue.text
        
        if rantContents!.pointee.text.count > 240 {
            bodyLabel.text = rantContents!.pointee.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents!.pointee.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        tagList.addTags(rantContents!.pointee.tags)
    }
    
    func testConfigure() {
        upvoteButton.tintColor = .systemGray
        downvoteButton.tintColor = .systemGray
        scoreLabel.text = "9999"
        
        //bodyLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed in ligula vel mi cursus ultricies eu quis arcu. In hac habitasse platea dictumst. Nam ultricies sem congue pharetra gravida. Sed ut neque ut velit dapibus pharetra porttitor eget ipsum. In pellentesque sapien eu porta semper. Ut non justo condimentum sapien ultrices venenatis. Vivamus finibus lorem justo, feugiat tempor metus volutpat vitae."
        bodyLabel.text = "Lorem ipsum"
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        tagList.addTags(["This", "Is", "A", "Test"])
    }
    
    @IBAction func handleUpvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.pointee.voteState {
            case 0:
                return 1
                
            case 1:
                return 0
                
            default:
                return 1
            }
        }
        
        //let success = APIRequest().voteOnRant(rantID: self.rantContents!.pointee.id, vote: vote)
        
        /*if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            self.rantContents!.pointee.vote_state = success!.rant.vote_state
            self.rantContents!.pointee.score = success!.rant.score
            
            if let parentTableView = self.parentTableView {
                parentTableView.reloadData()
            }
        }*/
        
        SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents!.pointee.id, vote: vote) { [weak self] error, updatedRant in
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
        }
    }
    
    @IBAction func handleDownvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.pointee.voteState {
            case 0:
                return -1
                
            case -1:
                return 0
                
            default:
                return -1
            }
        }
        
        /*let success = APIRequest().voteOnRant(rantID: self.rantContents!.pointee.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE DOWNVOTING")
        } else {
            self.rantContents!.pointee.vote_state = success!.rant.vote_state
            self.rantContents!.pointee.score = success!.rant.score
            
            if let parentTableView = self.parentTableView {
                parentTableView.reloadData()
            }
        }*/
        
        SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents!.pointee.id, vote: vote) { [weak self] error, updatedRant in
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
        }
    }
    
    /*@objc func handleTap(_ sender: UITapGestureRecognizer) {
        if let parentTableViewController = self.parentTableViewController {
            let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(identifier: "RantViewController", creator: { coder in
                return RantViewController(coder: coder, rantID: self.rantContents!.wrappedValue.id, rantInFeed: self.rantContents!, supplementalRantImage: self.supplementalImage, loadCompletionHandler: nil)
            })
            //rantVC.rantID = rantContents!.wrappedValue.id
            //rantVC.rantInFeed = rantContents!.projectedValue
            //rantVC.supplementalRantImage = supplementalImageView.image
            
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
