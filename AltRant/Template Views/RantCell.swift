//
//  RantCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit

class RantCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    
    @IBOutlet weak var userProfileImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: PaddingLabel!
    
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    
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
    
    @IBAction func upvote(_ sender: UIButton) {
        print("Upvote pressed")
    }
    
    @IBAction func downvote(_ sender: UIButton) {
        print("Downvote pressed")
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
}
