//
//  RantInFeedCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import QuickLook
import SwiftUI

class RantInFeedCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    
    var rantContents: Binding<RantInFeed>? = nil
    var parentTableViewController: UITableViewController? = nil
    
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
    
    func configure(with model: Binding<RantInFeed>?, image: UIImage?, parentTableViewController: UITableViewController?) {
        self.parentTableViewController = parentTableViewController
        self.rantContents = model
        
        upvoteButton.tintColor = (rantContents!.wrappedValue.vote_state == 1 ? UIColor(hex: rantContents!.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents!.wrappedValue.score)
        downvoteButton.tintColor = (rantContents!.wrappedValue.vote_state == -1 ? UIColor(hex: rantContents!.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        textStackView.addGestureRecognizer(gestureRecognizer)
        
        if image == nil {
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            let resizeMultiplier = getImageResizeMultiplier(imageWidth: image!.size.width, imageHeight: image!.size.height, multiplier: 1)
            
            //UIGraphicsBeginImageContextWithOptions(CGSize(width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier), false, CGFloat(1 / resizeMultiplier))
            //image!.draw(in: CGRect(x: 0, y: 0, width: image!.size.width / resizeMultiplier, height: image!.size.height / resizeMultiplier))
            //let newImage = UIGraphicsGetImageFromCurrentImageContext()
            //UIGraphicsEndImageContext()
            
            supplementalImageView.image = image
        }
        
        upvoteButton.isUserInteractionEnabled = rantContents!.wrappedValue.vote_state != -2
        downvoteButton.isUserInteractionEnabled = rantContents!.wrappedValue.vote_state != -2
        
        //bodyLabel.text = model.wrappedValue.text
        
        if rantContents!.wrappedValue.text.count > 240 {
            bodyLabel.text = rantContents!.wrappedValue.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents!.wrappedValue.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        tagList.addTags(rantContents!.wrappedValue.tags)
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
            switch self.rantContents!.wrappedValue.vote_state {
            case 0:
                return 1
                
            case 1:
                return 0
                
            default:
                return 1
            }
        }
        
        let success = APIRequest().voteOnRant(rantID: self.rantContents!.wrappedValue.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            self.rantContents!.wrappedValue.vote_state = success!.rant.vote_state
            self.rantContents!.wrappedValue.score = success!.rant.score
            
            if let parentTableViewController = self.parentTableViewController {
                parentTableViewController.tableView.reloadData()
            }
        }
    }
    
    @IBAction func handleDownvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.wrappedValue.vote_state {
            case 0:
                return -1
                
            case -1:
                return 0
                
            default:
                return -1
            }
        }
        
        let success = APIRequest().voteOnRant(rantID: self.rantContents!.wrappedValue.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE DOWNVOTING")
        } else {
            self.rantContents!.wrappedValue.vote_state = success!.rant.vote_state
            self.rantContents!.wrappedValue.score = success!.rant.score
            
            if let parentTableViewController = self.parentTableViewController {
                parentTableViewController.tableView.reloadData()
            }
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if let parentTableViewController = self.parentTableViewController {
            let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(identifier: "RantViewController", creator: { coder in
                return RantViewController(coder: coder, rantID: self.rantContents!.wrappedValue.id, rantInFeed: self.rantContents!, supplementalRantImage: self.supplementalImageView.image)
            })
            //rantVC.rantID = rantContents!.wrappedValue.id
            //rantVC.rantInFeed = rantContents!.projectedValue
            //rantVC.supplementalRantImage = supplementalImageView.image
            
            parentTableViewController.navigationController?.pushViewController(rantVC, animated: true)
        }
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
}
