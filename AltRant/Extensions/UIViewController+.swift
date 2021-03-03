//
//  UIViewController+.swift
//  AltRant
//
//  Created by Omer Shamai on 2/21/21.
//

import Foundation
import UIKit

extension UIViewController {

    var hasSafeArea: Bool {
        guard
            #available(iOS 11.0, tvOS 11.0, *)
            else {
                return false
            }
        return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
    }

}
