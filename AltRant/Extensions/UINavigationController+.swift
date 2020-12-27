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
