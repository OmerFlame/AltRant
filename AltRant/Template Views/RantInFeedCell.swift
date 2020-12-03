//
//  RantInFeedCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import SwiftUI

class RantInFeedCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var tagList: TagListView!
    
    var rantContents: Binding<RantInFeed>!
    var parentTableView: UITableView? = nil
    
    func configure(with model: Binding<RantInFeed>, image: UIImage?, parentTableView: UITableView?) {
        self.parentTableView = parentTableView
        self.rantContents = model
        
        upvoteButton.tintColor = (rantContents!.wrappedValue.vote_state == 1 ? UIColor(hex: rantContents!.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents!.wrappedValue.score + rantContents!.wrappedValue.vote_state)
        downvoteButton.tintColor = (rantContents!.wrappedValue.vote_state == -1 ? UIColor(hex: rantContents!.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        
        upvoteButton.isUserInteractionEnabled = rantContents!.wrappedValue.vote_state != -2
        downvoteButton.isUserInteractionEnabled = rantContents!.wrappedValue.vote_state != -2
        
        //bodyLabel.text = model.wrappedValue.text
        
        if rantContents!.wrappedValue.text.count > 240 {
            bodyLabel.text = rantContents!.wrappedValue.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents!.wrappedValue.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
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
        
        if !success {
            print("ERROR WHILE UPVOTING")
        } else {
            self.rantContents!.wrappedValue.vote_state = vote
            
            if let parentTableView = self.parentTableView {
                parentTableView.reloadData()
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
        
        if !success {
            print("ERROR WHILE DOWNVOTING")
        } else {
            self.rantContents!.wrappedValue.vote_state = vote
            
            if let parentTableView = self.parentTableView {
                parentTableView.reloadData()
            }
        }
    }
}
