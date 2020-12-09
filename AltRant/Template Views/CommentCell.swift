//
//  CommentCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/7/20.
//

import UIKit

class CommentCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    
    @IBOutlet weak var userProfileImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: PaddingLabel!
    
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var supplementalImageView: UIImageView!
    
    var file: File?
    var commentContents: CommentModel!
    var parentTableViewController: RantViewController? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(with model: CommentModel, supplementalImage: UIImage?, parentTableViewController: RantViewController?) {
        self.commentContents = model
        self.file = nil
        self.parentTableViewController = parentTableViewController
        
        if model.attached_image != nil {
            let resizeMultiplier = getImageResizeMultiplier(imageWidth: CGFloat(commentContents!.attached_image!.width!), imageHeight: CGFloat(commentContents!.attached_image!.height!), multiplier: 1)
            
            let finalWidth = CGFloat(commentContents!.attached_image!.width!) / resizeMultiplier
            let finalHeight = CGFloat(commentContents!.attached_image!.height!) / resizeMultiplier
            
            self.file = Optional(File.loadFile(image: commentContents!.attached_image!, size: CGSize(width: finalWidth, height: finalHeight)))
        }
        
        upvoteButton.tintColor = (model.vote_state == 1 ? UIColor(hex: model.user_avatar.b)! : UIColor.systemGray)
        scoreLabel.text = String(commentContents!.score)
        downvoteButton.tintColor = (model.vote_state == -1 ? UIColor(hex: model.user_avatar.b)! : UIColor.systemGray)
        
        if supplementalImage == nil {
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            supplementalImageView.image = supplementalImage
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
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
}
