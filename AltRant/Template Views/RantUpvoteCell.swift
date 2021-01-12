//
//  RantUpvoteCell.swift
//  AltRant
//
//  Created by Omer Shamai on 1/5/21.
//

import UIKit

class RantUpvoteCell: UITableViewCell {
    //override var reuseIdentifier: String? { return "RantUpvoteCell" }
    
    @IBOutlet weak var profileImageView: RoundedImageView!
    @IBOutlet weak var usernameUpvoteLabel: UILabel!
    @IBOutlet weak var upvoteBadge: RoundedImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
