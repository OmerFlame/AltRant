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

extension UIView {
    func copyView<T: UIView>() -> T? {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data ?? Data()) as? T
    }
}

