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
    
    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}

