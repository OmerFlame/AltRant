//
//  WeeklyRantHeaderLarge.swift
//  AltRant
//
//  Created by Omer Shamai on 06/09/2022.
//

import UIKit

protocol WeeklyRantHeaderDelegate {
    func didCloseWeeklyRantHeader(_ weeklyRantHeader: WeeklyRantHeaderLarge)
}

class WeeklyRantHeaderLarge: UIView {
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    public var delegate: WeeklyRantHeaderDelegate?
    
    @IBAction func close(_ sender: Any) {
        delegate?.didCloseWeeklyRantHeader(self)
    }
}
