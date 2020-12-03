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
    
    func configure(with model: Binding<RantInFeed>, image: UIImage?) {
        upvoteButton.tintColor = (model.wrappedValue.vote_state == 1 ? UIColor(hex: model.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        scoreLabel.text = String(model.wrappedValue.score)
        downvoteButton.tintColor = (model.wrappedValue.vote_state == -1 ? UIColor(hex: model.wrappedValue.user_avatar.b)! : UIColor.systemGray)
        
        upvoteButton.isUserInteractionEnabled = model.wrappedValue.vote_state != -2
        downvoteButton.isUserInteractionEnabled = model.wrappedValue.vote_state != -2
        
        //bodyLabel.text = model.wrappedValue.text
        
        if model.wrappedValue.text.count > 240 {
            bodyLabel.text = model.wrappedValue.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = model.wrappedValue.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        tagList.addTags(model.wrappedValue.tags)
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
}
