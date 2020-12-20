//
//  RantCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import SwiftUI
import QuickLook

class RantCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    
    @IBOutlet weak var userProfileImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userScoreLabel: PaddingLabel!
    
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    
    var file: File?
    var savedPreviewImage: UIImage?
    var profile: Profile!
    var userImage: UIImage?
    var rantContents: RantModel!
    var rantInFeed: Binding<RantInFeed>!
    var parentTableViewController: RantViewController? = nil
    
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
    
    func configure(with model: RantModel, rantInFeed: Binding<RantInFeed>?, userImage: UIImage?, supplementalImage: File?, profile: Profile, parentTableViewController: RantViewController?) {
        self.rantContents = model
        self.rantInFeed = rantInFeed
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
        
        upvoteButton.tintColor = (model.vote_state == 1 ? UIColor(hex: model.user_avatar.b)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents!.score)
        downvoteButton.tintColor = (model.vote_state == -1 ? UIColor(hex: model.user_avatar.b)! : UIColor.systemGray)
        
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
        
        upvoteButton.isEnabled = rantContents!.vote_state != -2
        downvoteButton.isEnabled = rantContents!.vote_state != -2
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        tagList.addTags(rantContents!.tags)
        
        if rantContents!.user_avatar.i == nil {
            userProfileImageView.image = UIImage(color: UIColor(hex: rantContents!.user_avatar.b)!, size: CGSize(width: 45, height: 45))
        } else {
            let resourceURL = URL(string: "https://avatars.devrant.com/" + rantContents!.user_avatar.i!)!
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var imageData: Data? = nil
            
            URLSession.shared.dataTask(with: resourceURL) { data, response, error in
                imageData = data ?? nil
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            userProfileImageView.image = UIImage(data: imageData ?? Data()) ?? nil
        }
        
        usernameLabel.text = rantContents!.user_username
        
        if rantContents!.user_score < 0 {
            userScoreLabel.text = String(rantContents!.user_score)
        } else {
            userScoreLabel.text = "+\(rantContents!.user_score)"
        }
        
        userScoreLabel.backgroundColor = UIColor(hex: rantContents!.user_avatar.b)
        
        scoreLabel.text = String(rantContents!.score)
        
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
        let userGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleUserTap(_:)))
        
        supplementalImageView.addGestureRecognizer(imageGestureRecognizer)
        userStackView.addGestureRecognizer(userGestureRecognizer)
        
        //layoutSubviews()
    }
    
    /*override func layoutSubviews() {
        super.layoutSubviews()
        
        print("IMAGE FRAME Y:  \(supplementalImageView.frame.minY)")
        print("IMAGE BOUNDS Y: \(supplementalImageView.bounds.minY)")
    }*/
    
    @IBAction func upvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.vote_state {
            case 0:
                return 1
                
            case 1:
                return 0
                
            default:
                return 1
            }
        }
        
        let success = APIRequest().voteOnRant(rantID: self.rantContents!.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            rantInFeed!.wrappedValue.vote_state = vote
            rantInFeed!.wrappedValue.score = success!.rant.score
            //parentTableViewController?.rant!.vote_state = vote
            parentTableViewController?.rant!.vote_state = success!.rant.vote_state
            parentTableViewController?.rant!.score = success!.rant.score
            
            if let parentTableViewController = self.parentTableViewController {
                parentTableViewController.tableView.reloadData()
            }
        }
    }
    
    @IBAction func downvote(_ sender: UIButton) {
        var vote: Int {
            switch self.rantContents!.vote_state {
            case 0:
                return -1
                
            case -1:
                return 0
                
            default:
                return -1
            }
        }
        
        let success = APIRequest().voteOnRant(rantID: self.rantContents!.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            rantInFeed!.wrappedValue.vote_state = vote
            rantInFeed!.wrappedValue.score = success!.rant.score
            parentTableViewController?.rant!.vote_state = success!.rant.vote_state
            parentTableViewController?.rant!.score = success!.rant.score
            
            if let parentTableViewController = self.parentTableViewController {
                parentTableViewController.tableView.reloadData()
            }
        }
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
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
                return ProfileTableViewController(coder: coder, userID: self.rantContents.user_id)
            })
            
            parentTableViewController.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
}
