//
//  RoundedImageView.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit

@IBDesignable public class RoundedImageView: UIImageView {

    override public func layoutSubviews() {
        super.layoutSubviews()

        //hard-coded this since it's always round
        layer.cornerRadius = 0.5 * bounds.size.width
    }
}
