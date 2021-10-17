//
//  SceneDelegate.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let urlContext = connectionOptions.urlContexts.first {
            let incomingURL = urlContext.url
            
            if Int(incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: "")) == nil {
                var profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                    var vc = ProfileTableViewController(coder: coder, userID: nil)!
                    vc.shouldLoadFromUsername = true
                    vc.username = incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: "")
                    return vc
                }) as! ProfileTableViewController
                
                profileVC.shouldLoadFromUsername = true
                profileVC.username = incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: "")
                
                DispatchQueue.main.async {
                    if let tabBarController = UIApplication.shared.windows.first!.rootViewController! as? UITabBarController {
                        if let controller = tabBarController.selectedViewController as? UINavigationController {
                            controller.pushViewController(profileVC, animated: true)
                        }
                    }
                }
                
                return
            } else {
                let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(withIdentifier: "RantViewController") as! RantViewController
                rantVC.rantID = Int(incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: ""))!
                rantVC.rantInFeed = nil
                rantVC.supplementalRantImage = nil
                
                DispatchQueue.main.async {
                    if let tabBarController = UIApplication.shared.windows.first!.rootViewController! as? UITabBarController {
                        if let controller = tabBarController.selectedViewController as? UINavigationController {
                            controller.pushViewController(rantVC, animated: true)
                        }
                    }
                }
            }
            
            return
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return
        }
        
        if Int(incomingURL.lastPathComponent) == nil {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: nil)
            })
            
            profileVC.shouldLoadFromUsername = true
            profileVC.username = incomingURL.lastPathComponent
            
            DispatchQueue.main.async {
                if let tabBarController = UIApplication.shared.windows.first!.rootViewController! as? UITabBarController {
                    if let controller = tabBarController.selectedViewController as? UINavigationController {
                        controller.pushViewController(profileVC, animated: true)
                    }
                }
            }
            
            return
        }
        
        return
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let incomingURL = URLContexts.first?.url else {
            return
        }
        
        if Int(incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: "")) == nil {
            var profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                var vc = ProfileTableViewController(coder: coder, userID: nil)!
                vc.shouldLoadFromUsername = true
                vc.username = incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: "")
                return vc
            }) as! ProfileTableViewController
            
            profileVC.shouldLoadFromUsername = true
            profileVC.username = incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: "")
            
            DispatchQueue.main.async {
                if let tabBarController = UIApplication.shared.windows.first!.rootViewController! as? UITabBarController {
                    if let controller = tabBarController.selectedViewController as? UINavigationController {
                        controller.pushViewController(profileVC, animated: true)
                    }
                }
            }
            
            return
        } else {
            let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(withIdentifier: "RantViewController") as! RantViewController
            rantVC.rantID = Int(incomingURL.absoluteString.replacingOccurrences(of: "altrant://", with: ""))!
            rantVC.rantInFeed = nil
            rantVC.supplementalRantImage = nil
            
            DispatchQueue.main.async {
                if let tabBarController = UIApplication.shared.windows.first!.rootViewController! as? UITabBarController {
                    if let controller = tabBarController.selectedViewController as? UINavigationController {
                        controller.pushViewController(rantVC, animated: true)
                    }
                }
            }
        }
        
        return
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        print("SCENE ACTIVE")
        
        //NotificationCenter.default.post(name: "FixNavigationBar", object: nil)
        //NotificationCenter.default.post(name: NSNotification.Name("FixNavigationBar"), object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
        print("SCENE INACTIVE")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        print("SCENE IS IN FOREGROUND")
        NotificationCenter.default.post(name: NSNotification.Name("FixNavigationBar"), object: nil)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        print("SCENE IS IN BACKGROUND")
    }
    
    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        NotificationCenter.default.post(name: NSNotification.Name("WindowDidResize"), object: nil)
    }
}

