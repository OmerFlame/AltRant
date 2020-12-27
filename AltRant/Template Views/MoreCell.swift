//
//  MoreCell.swift
//  AltRant
//
//  Created by Omer Shamai on 12/27/20.
//

import UIKit

@IBDesignable
class MoreCell: UITableViewCell {
    @IBInspectable lazy var contentImageView: UIImageView = {
        $0.contentMode = .center
        return $0
    }(UIImageView())
    
    @IBInspectable lazy var title: UILabel = {
        $0.font = .systemFont(ofSize: 17)
        $0.textColor = .label
        $0.numberOfLines = 1
        return $0
    }(UILabel())
    
    fileprivate func setup() {
        backgroundColor = .systemBackground
        contentView.addSubview(contentImageView)
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
