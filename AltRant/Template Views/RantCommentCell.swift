//
//  RantCommentCell.swift
//  AltRant
//
//  Created by Omer Shamai on 1/12/21.
//

import UIKit

class RantCommentCell: UITableViewCell {
    @IBOutlet weak var profileImageView: RoundedImageView!
    @IBOutlet weak var usernameCommentLabel: UILabel!
    @IBOutlet private weak var commentBadgeImageView: RoundedImageView!
    
    var badgeBackgroundColor = UIColor.blue {
        didSet {
            commentBadgeImageView.backgroundColor = badgeBackgroundColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
