//
//  LoadingCell.swift
//  AltRant
//
//  Created by Omer Shamai on 17/01/2022.
//

import UIKit

class LoadingCell: UITableViewCell {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .clear
        activityIndicator.color = .white
    }
}
