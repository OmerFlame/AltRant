//
//  AppDelegate.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("APPLICATION ACTIVE")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("APPLICATION INACTIVE")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("APPLICATION IN BACKGROUND")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("APPLICATION IN FOREGROUND")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.setValue(nil, forKey: "DRLastSet")
        let tmpDirectory = try! FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
        tmpDirectory.forEach { file in
            let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
            try! FileManager.default.removeItem(atPath: path)
        }
    }
}

extension UIView {
    static func loadFromXIB<T>(withOwner: Any? = nil, options: [UINib.OptionsKey : Any]? = nil) -> T where T: UIView
        {
            let bundle = Bundle(for: self)
            let nib = UINib(nibName: "\(self)", bundle: bundle)

            guard let view = nib.instantiate(withOwner: withOwner, options: options).first as? T else {
                fatalError("Could not load view from nib file.")
            }
            return view
        }
}
