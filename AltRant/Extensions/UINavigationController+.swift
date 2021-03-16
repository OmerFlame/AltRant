//
//  UINavigationController+.swift
//  AltRant
//
//  Created by Omer Shamai on 12/27/20.
//

import Foundation

extension UINavigationController {
    func popViewController(animated: Bool, completion: (() -> Void)?) {
        popViewController(animated: animated)
        
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion?() }
            return
        }
        
        coordinator.animate(alongsideTransition: nil, completion: { _ in completion?() })
    }
}

extension UINavigationBar {
    var visualEffectView: UIVisualEffectView? {
        if let barBackground = subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" }) {
            if let effectView = barBackground.subviews.first(where: { String(describing: type(of: $0)) == "UIVisualEffectView" }) {
                return effectView as? UIVisualEffectView
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    var backgroundView: UIView? {
        get {
            if let barBackground = subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" }) {
                return barBackground
            }
            
            return nil
        }
    }
}
