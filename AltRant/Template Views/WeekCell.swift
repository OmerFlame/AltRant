//
//  WeekCell.swift
//  AltRant
//
//  Created by Omer Shamai on 18/09/2022.
//

import UIKit

class WeekCell: UITableViewCell {
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    @IBOutlet weak var rantCountLabel: UIButton!
    
    override func prepareForReuse() {
        subjectLabel.text = ""
        weekLabel.text = ""
        rantCountLabel.titleLabel?.text = ""
    }
}
