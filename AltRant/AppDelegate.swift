//
//  AppDelegate.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import UserNotifications
//import Sentry
//import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UserDefaults.standard.setValue(nil, forKey: "DRLastSet")
        UserDefaults.standard.setValue(nil, forKey: "DRLastEndCursor")
        
        /*SentrySDK.start { options in
            options.dsn = "https://ee4b01a7f1bd403f851eabbdd6ce52f8@o576704.ingest.sentry.io/5730641"
            options.debug = true
        }*/
        
        UIApplication.shared.registerForRemoteNotifications()
        
        
        
        return true
        
        
    }
    
    /*func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return false
        }
        
        if Int(incomingURL.lastPathComponent) == nil {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: nil)
            })
            
            profileVC.shouldLoadFromUsername = true
            profileVC.username = incomingURL.lastPathComponent
            
            DispatchQueue.main.async {
                if let navigationController = UIApplication.shared.windows.first!.rootViewController!.children.first(where: { String(describing: type(of: $0)) == "UINavigationController" }) {
                    if let controller = navigationController as? UINavigationController {
                        controller.pushViewController(profileVC, animated: true)
                    }
                }
            }
            
            return true
        }
        
        return false
    }*/
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return false
        }
        
        if Int(incomingURL.lastPathComponent) == nil {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: nil)
            })
            
            profileVC.shouldLoadFromUsername = true
            profileVC.username = incomingURL.lastPathComponent
            
            DispatchQueue.main.async {
                if let navigationController = UIApplication.shared.windows.first!.rootViewController!.children.first(where: { String(describing: type(of: $0)) == "UINavigationController" }) {
                    if let controller = navigationController as? UINavigationController {
                        controller.pushViewController(profileVC, animated: true)
                    }
                }
            }
            
            return true
        }
        
        return false
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                debugPrint("NOTIFICATIONS GRANTED!")
            } else {
                debugPrint("NOTIFICATIONS DENIED!")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        let show = UNNotificationAction(identifier: "show", title: "Show notifications", options: .foreground)
        let category = UNNotificationCategory(identifier: "notification", actions: [show], intentIdentifiers: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let customData = userInfo["aps"] as? [String:Any] {
            if let rantID = customData["rantID"] as? Int {
                debugPrint("Custom data received: \(customData)")
                
                let rantVC = UIStoryboard(name: "RantViewController", bundle: nil).instantiateViewController(withIdentifier: "RantViewController") as! RantViewController
                rantVC.rantID = rantID
                rantVC.rantInFeed = nil
                rantVC.supplementalRantImage = nil
                
                if let username = customData["username"] as? String,
                   let createdTime = customData["createdTime"] as? Int,
                   let commentID = customData["commentID"] as? Int {
                    rantVC.loadCompletionHandler = { tableViewController in
                        DispatchQueue.global(qos: .userInitiated).async {
                            if let idx = tableViewController!.comments.firstIndex(where: {
                                $0.createdTime == createdTime &&
                                $0.username == username ||
                                $0.id == commentID
                            }) {
                                DispatchQueue.main.async {
                                    tableViewController!.tableView.scrollToRow(at: IndexPath(row: idx, section: 1), at: .middle, animated: true)
                                }
                            }
                        }
                    }
                } else {
                    rantVC.loadCompletionHandler = nil
                }
                
                //(UIApplication.shared.windows.first!.rootViewController as! UITabBarController).selectedIndex = 2
                
                DispatchQueue.main.async {
                    if let navigationController = UIApplication.shared.windows.first!.rootViewController!.children.first(where: { String(describing: type(of: $0)) == "UINavigationController" }) {
                        if let controller = navigationController as? UINavigationController {
                            controller.pushViewController(rantVC, animated: true)
                        }
                    }
                }
            }
            
            completionHandler()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken: Data) {
        /*#if DEBUG
        //UserDefaults.standard.set(nil, forKey: "DRNotificationDeviceUUID")
        if UserDefaults.standard.string(forKey: "DRNotificationDeviceUUID") == nil {
            UserDefaults.standard.set(UUID().uuidString, forKey: "DRNotificationDeviceUUID")
            
            if UserDefaults.standard.integer(forKey: "DRUserID") != 0,
               UserDefaults.standard.integer(forKey: "DRTokenID") != 0,
               UserDefaults.standard.string(forKey: "DRTokenKey") != nil,
               UserDefaults.standard.integer(forKey: "DRTokenExpireTime") != 0 {
                let url = URL(string: "https://192.168.24.111:443/add_token_collection")!
                
                var request = URLRequest(url: url)
                
                var payload: [String:Any] = [
                    "device_uuid": UserDefaults.standard.string(forKey: "DRNotificationDeviceUUID")!,
                    "device_token": didRegisterForRemoteNotificationsWithDeviceToken.hexDescription,
                    "user_id": UserDefaults.standard.integer(forKey: "DRUserID"),
                    "token_id": UserDefaults.standard.integer(forKey: "DRTokenID"),
                    "token_key": UserDefaults.standard.string(forKey: "DRTokenKey")!,
                    "token_expire_time": UserDefaults.standard.integer(forKey: "DRTokenExpireTime")
                ]
                
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
                //request.httpBody = "device_uuid=\(UserDefaults.standard.string(forKey: "DRNotificationDeviceUUID")!)&device_token=\(didRegisterForRemoteNotificationsWithDeviceToken.hexDescription)&user_id=\(UserDefaults.standard.integer(forKey: "DRUserID"))&token_id=\(UserDefaults.standard.integer(forKey: "DRTokenID"))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&token_expire_time=\(UserDefaults.standard.integer(forKey: "DRTokenExpireTime"))".data(using: .utf8)
                
                let session = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
                
                session.dataTask(with: request) { data, response, error in
                    let result = try! JSONSerialization.jsonObject(with: data!, options: [])
                    
                    if let jObject = result as? [String:Any] {
                        if let success = jObject["success"] as? Bool {
                            if success {
                                print("UPLOAD SUCCESS!")
                            }
                        }
                    }
                }.resume()
            }
        }
        #endif*/
        print(didRegisterForRemoteNotificationsWithDeviceToken.hexDescription)
        
        //UserDefaults.standard.set(didRegisterForRemoteNotificationsWithDeviceToken.hexDescription, forKey: "DRDeviceToken")
        
        let payload: [String: String] = ["deviceToken": didRegisterForRemoteNotificationsWithDeviceToken.hexDescription]
        
        NotificationCenter.default.post(name: NSNotification.Name("NotificationDeviceToken"), object: nil, userInfo: payload)
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

public func encrypt(string: String, publicKey: String) -> String? {
    let keyString = publicKey.replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----\n", with: "").replacingOccurrences(of: "\n-----END PUBLIC KEY-----", with: "")
    
    guard let data = Data(base64Encoded: keyString, options: .ignoreUnknownCharacters) else { return nil }
    
    var attributes: CFDictionary {
        return [
            kSecAttrKeyType as String         : kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String        : kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String   : data.count * 8,
            kSecReturnPersistentRef as String : kCFBooleanTrue!
        ] as CFDictionary
    }
    
    var error: Unmanaged<CFError>? = nil
    guard let secKey = SecKeyCreateWithData(data as CFData, attributes, &error) else {
        print(error.debugDescription)
        return nil
    }
    
    return encrypt(string: string, publicKey: secKey)
}

public func encrypt(string: String, publicKey: SecKey) -> String? {
    let buffer = string.data(using: .ascii)!
    
    //var keySize = SecKeyGetBlockSize(publicKey)
    //var keyBuffer = [UInt8](repeating: 0, count: keySize)
    
    var error: Unmanaged<CFError>? = nil
    let encryptedData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA512, buffer as CFData, nil)
    
    guard encryptedData != nil else {
        return nil
    }
    
    let encryptedDataAsData = encryptedData! as Data
    
    return encryptedDataAsData.base64EncodedString()
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

class invalidCertificateDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.serverTrust == nil {
            completionHandler(.useCredential, nil)
        } else {
            let trust: SecTrust = challenge.protectionSpace.serverTrust!
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        }
    }
}
