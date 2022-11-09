//
//  RantInFeedCell.swift
//  AltRant
//
//  Created by Omer Shamai on 2/7/21.
//

import UIKit
import QuickLook
import SwiftRant
import SwiftHEXColors
import SkeletonView

class RantInFeedCell: UITableViewCell {
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var downvoteButton: UIButton!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var textStackView: UIStackView!
    @IBOutlet weak var bodyLabel: UITextView!
    @IBOutlet weak var supplementalImageView: UIImageView!
    @IBOutlet weak var tagList: TagListView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentCountLabel: UIButton!
    
    var rantContents: RantInFeed!
    var parentTableViewController: UIViewController? = nil
    var parentTableView: UITableView? = nil
    
    var supplementalImage: File?
    
    var loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    var delegate: FeedDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        supplementalImageView.image = nil
        supplementalImageView.isHidden = true
        
        imageViewHeightConstraint.constant = 0
        
        supplementalImage = nil
        
        rantContents = nil
        
        scoreLabel.text = ""
        bodyLabel.text = ""
        tagList.removeAllTags()
        
        NotificationCenter.default.removeObserver(self, name: windowResizeNotification, object: nil)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layoutIfNeeded()
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
        commentCountLabel?.isHidden = rantContents.commentCount == 0
        
        upvoteButton.tintColor = (rantContents.voteState.rawValue == 1 ? UIColor(hexString: rantContents.userAvatar.backgroundColor)! : UIColor.systemGray)
        scoreLabel.text = String(rantContents.score)
        downvoteButton.tintColor = (rantContents.voteState.rawValue == -1 ? UIColor(hexString: rantContents.userAvatar.backgroundColor)! : UIColor.systemGray)
        
        upvoteButton.isEnabled = rantContents.voteState.rawValue != -2
        downvoteButton.isEnabled = rantContents.voteState.rawValue != -2
        
        if rantContents.attachedImage == nil {
            supplementalImageView.image = nil
            supplementalImageView.isHidden = true
        } else {
            supplementalImageView.isHidden = false
            
            supplementalImageView.translatesAutoresizingMaskIntoConstraints = false
            
            let resizeMultiplier = supplementalImageView.frame.size.width / (CGFloat(rantContents.attachedImage!.width) / UIScreen.main.scale)
            
            let finalHeight = (CGFloat(rantContents.attachedImage!.height) / UIScreen.main.scale) * resizeMultiplier
            
            debugPrint("FINAL IMAGE HEIGHT: \(finalHeight)")
            
            imageViewHeightConstraint.constant = finalHeight
            
            NotificationCenter.default.addObserver(self, selector: #selector(windowResizeHandler), name: windowResizeNotification, object: nil)
            
            //setNeedsLayout()
            //layoutIfNeeded()
            
            supplementalImageView.showAnimatedSkeleton()
            
            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rantContents.attachedImage!.url)!.lastPathComponent).relativePath) {
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rantContents.attachedImage!.url)!.lastPathComponent).relativePath
                
                debugPrint("IMAGE FOUND AT RELATIVE PATH \(path) FOR RANT ID \(rantContents.id)!")
                
                DispatchQueue.global().async {
                    let image = UIImage(contentsOfFile: path)
                    
                    DispatchQueue.main.async { [weak self] in
                        //self?.supplementalImageView.isHidden = false
                        
                        //self?.supplementalImageView.translatesAutoresizingMaskIntoConstraints = false
                        
                        self?.supplementalImageView.image = image
                        
                        //let resizeMultiplier = self?.supplementalImageView.frame.size.width ?? 0 / UIScreen.main.ad_pixelDimension * CGFloat(self?.rantContents.attachedImage!.width ?? 1)
                        
                        //let finalHeight = UIScreen.main.ad_pixelDimension * CGFloat(self?.rantContents.attachedImage!.height ?? 0) * resizeMultiplier
                        
                        //self?.imageViewHeightConstraint.constant = finalHeight
                        
                        //print("IMAGE FRAME: \(supplementalImageView.frame.size)")
                        
                        self?.supplementalImageView.hideSkeleton(transition: .crossDissolve(0.2))
                        
                        //self?.layoutSubviews()
                    }
                }
            } else {
                //let url = URL(string: rantContents.attachedImage!.url)!
                debugPrint("IMAGE \(URL(string: rantContents.attachedImage!.url)!.lastPathComponent) FOR RANT ID \(rantContents.id) NOT AVAILABLE ON DISK, FETCHING FROM WEB...")
                let session = URLSession(configuration: .default)
                let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rantContents.attachedImage!.url)!.lastPathComponent)
                
                session.dataTask(with: URL(string: rantContents.attachedImage!.url)!) { data, _, _ in
                    if let data = data {
                        try? data.write(to: fileURL, options: .atomic)
                        
                        DispatchQueue.main.async { [weak self] in
                            //self?.supplementalImageView.isHidden = false
                            
                            //self?.supplementalImageView.translatesAutoresizingMaskIntoConstraints = false
                            
                            self?.supplementalImageView.image = UIImage(data: data)
                            
                            //let resizeMultiplier = self?.supplementalImageView.frame.size.width ?? 0 / UIScreen.main.ad_pixelDimension * CGFloat(self?.rantContents.attachedImage!.width ?? 1)
                            
                            //let finalHeight = UIScreen.main.ad_pixelDimension * CGFloat(self?.rantContents.attachedImage!.height ?? 0) * resizeMultiplier
                            
                            //self?.imageViewHeightConstraint.constant = finalHeight
                            
                            //print("IMAGE FRAME: \(supplementalImageView.frame.size)")
                            
                            self?.supplementalImageView.hideSkeleton(transition: .crossDissolve(0.2))
                        }
                    }
                }.resume()
            }
        }
        
        upvoteButton.isUserInteractionEnabled = rantContents.voteState.rawValue != -2
        downvoteButton.isUserInteractionEnabled = rantContents.voteState.rawValue != -2
        
        if rantContents.text.count > 240 {
            bodyLabel.text = rantContents.text.prefix(240) + "... [read more]"
        } else {
            bodyLabel.text = rantContents.text
        }
        
        tagList.textFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        tagList.removeAllTags()
        tagList.addTags(rantContents.tags)
        
        layoutIfNeeded()
    }
    
    @IBAction func handleUpvote(_ sender: UIButton) {
        var vote: VoteState {
            switch self.rantContents.voteState {
            case .unvoted:
                return .upvoted
                
            case .upvoted:
                return .unvoted
                
            default:
                return .upvoted
            }
        }
        
        /*let success = APIRequest().voteOnRant(rantID: self.rantContents.pointee.id, vote: vote)
        
        if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            self.rantContents.pointee.vote_state = success!.rant.vote_state
            self.rantContents.pointee.score = success!.rant.score
            
            if let parentTableView = self.parentTableView {
                parentTableView.reloadData()
            }
        }*/
        
        // This cell is being used in 2 unique feeds, so we need to call the according functions for both types. Whichever runs depends on the type of delegate. If the type doesn't match, it will stop calling.
        (delegate as? HomeFeedTableViewControllerDelegate)?.changeRantVoteState(rantID: rantContents.id, voteState: vote)
        (delegate as? ProfileTableViewControllerDelegate)?.setVoteStateForRant(withID: rantContents.id, voteState: vote)
        
        (delegate as? HomeFeedTableViewControllerDelegate)?.changeRantScore(rantID: rantContents.id, score: rantContents.voteState == .upvoted ? rantContents.score - 1 : rantContents.score + vote.rawValue)
        (delegate as? ProfileTableViewControllerDelegate)?.setScoreForRant(withID: rantContents.id, score: rantContents.voteState == .upvoted ? rantContents.score - 1 : rantContents.score + vote.rawValue)
        
        DispatchQueue.main.async {
            (self.delegate as? HomeFeedTableViewControllerDelegate)?.reloadData()
            (self.delegate as? ProfileTableViewControllerDelegate)?.reloadData()
        }
        
        delegate?.didVoteOnRant(withID: rantContents.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents.pointee.id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                self?.rantContents.pointee.voteState = updatedRant!.voteState
                self?.rantContents.pointee.score = updatedRant!.score
                
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
        var vote: VoteState {
            switch self.rantContents.voteState {
            case .unvoted:
                return .downvoted
                
            case .downvoted:
                return .unvoted
                
            default:
                return .downvoted
            }
        }
        
        // This cell is being used in 2 unique feeds, so we need to call the according functions for both types. Whichever runs depends on the type of delegate. If the type doesn't match, it will stop calling.
        (delegate as? HomeFeedTableViewControllerDelegate)?.changeRantVoteState(rantID: rantContents.id, voteState: vote)
        (delegate as? ProfileTableViewControllerDelegate)?.setVoteStateForRant(withID: rantContents.id, voteState: vote)
        
        (delegate as? HomeFeedTableViewControllerDelegate)?.changeRantScore(rantID: rantContents.id, score: rantContents.voteState == .downvoted ? rantContents.score + 1 : rantContents.score + vote.rawValue)
        (delegate as? ProfileTableViewControllerDelegate)?.setScoreForRant(withID: rantContents.id, score: rantContents.voteState == .downvoted ? rantContents.score + 1 : rantContents.score + vote.rawValue)
        
        DispatchQueue.main.async {
            (self.delegate as? HomeFeedTableViewControllerDelegate)?.reloadData()
            (self.delegate as? ProfileTableViewControllerDelegate)?.reloadData()
        }
        
        delegate?.didVoteOnRant(withID: rantContents.id, vote: vote, cell: self)
        
        /*SwiftRant.shared.voteOnRant(nil, rantID: self.rantContents.pointee.id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                self?.rantContents.pointee.voteState = updatedRant!.voteState
                self?.rantContents.pointee.score = updatedRant!.score
                
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
        guard rantContents.attachedImage != nil else {
            return
        }
        
        let resizeMultiplier = supplementalImageView.frame.size.width / (CGFloat(rantContents.attachedImage!.width) / UIScreen.main.scale)
        
        let finalHeight = (CGFloat(rantContents.attachedImage!.height) / UIScreen.main.scale) * resizeMultiplier
        
        imageViewHeightConstraint.constant = finalHeight
        
        layoutIfNeeded()
    }
}
