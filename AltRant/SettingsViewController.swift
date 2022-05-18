//
//  SettingsViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 07/11/2021.
//

import Foundation
import UIKit
import SwiftRant

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var toggleNotificationServer: UISwitch!
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var serverTableViewCell: UITableViewCell!
    @IBOutlet weak var portTableViewCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //connectButton.superview!.translatesAutoresizingMaskIntoConstraints = false
        connectButton.isEnabled = false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !toggleNotificationServer.isOn {
            if indexPath.section == 0 {
                if indexPath.row != 0 {
                    return 0
                }
            } else {
                return 0
            }
        }
        
        return tableView.rowHeight
    }
    
    @IBAction func didToggle(_ sender: Any) {
        if toggleNotificationServer.isOn {
            connectButton.isHidden = false
            serverTableViewCell.isHidden = false
            portTableViewCell.isHidden = false
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
        } else {
            //tableView.reloadData()
            tableView.beginUpdates()
            tableView.endUpdates()
            
            //connectButton.isHidden = true
            //serverTableViewCell.isHidden = true
            //portTableViewCell.isHidden = true
        }
    }
    
    
    @IBAction func textFieldValueChanged(_ sender: Any) {
        connectButton.isEnabled = (serverTextField.text != "" && portTextField.text != "") ? true : false
    }
    
    @IBAction func connect(_ sender: UIButton) {
        connectButton.isEnabled = false
        let activityIndicator = UIActivityIndicatorView()
        
        connectButton.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: connectButton.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: connectButton.centerYAnchor).isActive = true
        
        let uuid = UUID().uuidString
        let url = URL(string: "http://\(serverTextField.text!):\(portTextField.text!)/register")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String:Any] = [
            "device_uuid": uuid
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        
        let session = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
        
        let server = serverTextField.text!
        let port = portTextField.text!
        
        print("Registering device with server...")
        session.dataTask(with: request) { data, response, error in
            //var dataToString = String(data: data!, encoding: .utf8)
            
            //dataToString = self.string(byRemovingControlCharacters: dataToString!)
            
            //let ndata = dataToString!.data(using: .utf8)
            
            //let result = try! JSONSerialization.jsonObject(with: ndata!, options: [])
            
            if let result = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []), let jsonObject = result as? [String:Any] {
                if let success = jsonObject["success"] as? Bool, success {
                    print("Success! Creating SecKey public key...")
                    let keyString = (jsonObject["key"] as! String).replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "").replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
                    
                    let data = Data(base64Encoded: keyString, options: .ignoreUnknownCharacters)!
                    
                    var attributes: [String: Any] = [
                        kSecAttrKeyType as String        : kSecAttrKeyTypeRSA,
                        kSecAttrKeyClass as String       : kSecAttrKeyClassPublic,
                        kSecAttrKeySizeInBits as String  : data.count * 8,
                        kSecReturnPersistentRef as String: kCFBooleanTrue!
                    ]
                    
                    var error: Unmanaged<CFError>? = nil
                    guard let secKey = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
                        print("Failed to generate SecKey public key!\nError: \(error.debugDescription)")
                        print("Unregistering now.")
                        
                        let cancelURL = URL(string: "http://\(server):\(port)/unregister")!
                        
                        var deleteRequest = URLRequest(url: cancelURL)
                        deleteRequest.httpMethod = "DELETE"
                        deleteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        
                        let deletePayload: [String: Any] = [
                            "device_uuid": uuid
                        ]
                        
                        deleteRequest.httpBody = try! JSONSerialization.data(withJSONObject: deletePayload, options: .prettyPrinted)
                        
                        let deleteSession = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
                        
                        deleteSession.dataTask(with: deleteRequest) { data, response, error in
                            
                        }.resume()
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Error", message: "Failed to store the server encryption key in the keychain. Notification registration failed.", preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    let delquery: [String: Any] = [
                        kSecClass as String             : kSecClassKey,
                        kSecAttrApplicationTag as String: "com.cracksoftware.keys.notification-server-pubkey",
                        kSecAttrKeyType as String       : kSecAttrKeyTypeRSA,
                        kSecReturnRef as String         : true
                    ]
                    
                    let delStatus = SecItemDelete(delquery as CFDictionary)
                    
                    print("Success! Saving SecKey to keychain...")
                    
                    let tag = "com.cracksoftware.keys.notification"
                    let addquery: [String: Any] = [
                        kSecClass as String: kSecClassKey,
                        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                        kSecAttrApplicationTag as String: tag,
                        kSecAttrApplicationLabel as String: "com.cracksoftware.keys.notification-server-pubkey",
                        kSecValueRef as String: secKey
                    ]
                    
                    let status = SecItemAdd(addquery as CFDictionary, nil)
                    
                    guard status == errSecSuccess else {
                        print("Failed to save SecKey to keychain! Unregistering now.")
                        
                        let cancelURL = URL(string: "http://\(server):\(port)/unregister")!
                        
                        var deleteRequest = URLRequest(url: cancelURL)
                        deleteRequest.httpMethod = "DELETE"
                        deleteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        
                        let deletePayload: [String: Any] = [
                            "device_uuid": uuid
                        ]
                        
                        deleteRequest.httpBody = try! JSONSerialization.data(withJSONObject: deletePayload, options: .prettyPrinted)
                        
                        let deleteSession = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
                        
                        deleteSession.dataTask(with: deleteRequest) { data, response, error in
                            
                        }.resume()
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Error", message: "Failed to store the server encryption key in the keychain. Notification registration failed.", preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    print("Success! Now establishing token collection message to server...")
                    
                    UserDefaults.standard.set(uuid, forKey: "DRNotificationDeviceUUID")
                    
                    NotificationCenter.default.addObserver(self, selector: #selector(self.gotNotificationToken(_:)), name: NSNotification.Name(rawValue: "NotificationDeviceToken"), object: nil)
                    
                    UserDefaults.standard.set("http://\(server):\(port)", forKey: "DRNotificationServer")
                    
                    print("Obtaining device notification token...")
                    
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            //print("Failed to register device with server!")
        }.resume()
    }
    
    @IBAction func testEncryptDecrypt(_ sender: UIButton) {
        connectButton.isEnabled = false
        
        let url = URL(string: "http://\(serverTextField.text!):\(portTextField.text!)/register")!
        
        var pubkeyRequest = URLRequest(url: url)
        pubkeyRequest.httpMethod = "POST"
        pubkeyRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var pubkeyPayload: [String:Any] = [
            "device_uuid": "C6CE2003-914C-4969-9A8C-020D66BE57BE"
        ]
        
        pubkeyRequest.httpBody = try! JSONSerialization.data(withJSONObject: pubkeyPayload, options: .prettyPrinted)
        
        let session = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
        
        let server = serverTextField.text!
        let port = portTextField.text!
        
        session.dataTask(with: pubkeyRequest) { data, response, error in
            var dataToString = String(data: data!, encoding: .utf8)
            
            dataToString = self.string(byRemovingControlCharacters: dataToString!)
            
            let ndata = dataToString!.data(using: .utf8)
            
            let result = try! JSONSerialization.jsonObject(with: ndata!, options: [])
            
            if let jsonObject = result as? [String:Any] {
                if let success = jsonObject["success"] as? Bool, success {
                    /*let keyString = (jsonObject["key"] as! String).replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "").replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
                    
                    let keyAsData = Data(base64Encoded: keyString, options: .ignoreUnknownCharacters)!
                    
                    let delquery: [String: Any] = [
                        kSecClass as String             : kSecClassKey,
                        kSecAttrApplicationTag as String: "com.cracksoftware.keys.notification-server-pubkey".data(using: .utf8)!,
                        kSecAttrKeyType as String       : kSecAttrKeyTypeRSA,
                        kSecReturnRef as String         : true
                    ]
                    
                    let delStatus = SecItemDelete(delquery as CFDictionary)
                    
                    let attributes: [String: Any] = [
                        kSecAttrKeyType as String         : kSecAttrKeyTypeRSA,
                        kSecAttrKeyClass as String        : kSecAttrKeyClassPublic,
                        kSecAttrKeySizeInBits as String   : keyAsData.count * 8,
                        kSecReturnPersistentRef as String : kCFBooleanTrue!
                    ]
                    
                    let pubkey = SecKeyCreateWithData(keyAsData as CFData, attributes as CFDictionary, nil)
                    
                    let addquery: [String: Any] = [
                        kSecClass as String             : kSecClassKey,
                        kSecAttrApplicationTag as String: "com.cracksoftware.keys.notification-server-pubkey".data(using: .utf8)!,
                        kSecValueRef as String          : pubkey!
                    ]
                    
                    SecItemAdd(addquery as CFDictionary, nil)*/
                    
                    let query: [String: Any] = [
                        kSecAttrLabel as String         : "com.cracksoftware.keys.notification-server-pubkey" as CFString,
                        kSecClass as String             : kSecClassKey,
                        kSecAttrApplicationTag as String: "com.cracksoftware.keys.notification-server-pubkey".data(using: .utf8)!,
                        kSecAttrKeyType as String       : kSecAttrKeyTypeRSA,
                        kSecReturnRef as String         : true
                    ]
                    
                    var item: CFTypeRef?
                    let status = SecItemCopyMatching(query as CFDictionary, &item)
                    
                    let pubkeyFromKeychain = item as! SecKey
                    
                    let keyInsidePubKey = (SecKeyCopyExternalRepresentation(pubkeyFromKeychain, nil)! as Data).base64EncodedString()
                    
                    print(keyInsidePubKey)
                    
                    let url = URL(string: "http://\(server):\(port)/test")!
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let payload: [String:String] = [
                        "str": encrypt(string: "Hello, world!", publicKey: pubkeyFromKeychain)!
                    ]
                    
                    request.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
                    
                    let encryptionSession = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
                    
                    encryptionSession.dataTask(with: request) { _, _, _ in DispatchQueue.main.async { self.connectButton.isEnabled = true } }.resume()
                }
            }
        }.resume()
        
        let query: [String: Any] = [
            kSecClass as String             : kSecClassKey,
            kSecAttrApplicationTag as String: "com.cracksoftware.keys.notification-server-pubkey".data(using: .utf8)!,
            kSecAttrKeyType as String       : kSecAttrKeyTypeRSA,
            kSecReturnRef as String         : true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        let pubkey = item as! SecKey
        
        /*let payload: [String:Any] = [
            "str": "LGD3W7T9QAgSwI/owUyBnmbukSaorfKSoJIHvtJWLN7WcxtjN0X+lyU2vtUcojm84swGLqKRimxfbfPT2AE0oss3V+aXns1baN7HRfutixwrRM70YrO/5SSyD5LAtb1IYiPp4aiUm7tayLy0m5KzvfvDMsbuzYgIJwVPoj+FiijYER6L77NNNOAOuXp8ZnNIUuJjz6EGP7euAaBRW7HAscanyo3PQZznZQoDhEMjq82OK7u9vlGP48dOQqPhprA19ZjoAbREnl9k/QqwY0YDZa+XRkWO+OBKljAdrolOlSPoBcDDgf5gQhvwVrFRHnES27Jm74/oG/eHWkqSSevALg==" //encrypt(string: "Hello, world!", publicKey: pubkey)
        ]*/
        
        //let semaphore = DispatchSemaphore(value: 0)
        
        /*session.dataTask(with: request, completionHandler: { _, _, _ in self.connectButton.isEnabled = true }).resume()*/
        
        //semaphore.wait()
        
        //connectButton.isEnabled = true
    }
    
    @objc func gotNotificationToken(_ notification: NSNotification) {
        let deviceToken: String = notification.userInfo!["deviceToken"]! as! String
        
        let url = URL(string: "\(UserDefaults.standard.string(forKey: "DRNotificationServer")!)/add_token_collection")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Success! Now retrieving SecKey public key from keychain...")
        
        let query: [String: Any] = [
            kSecClass as String             : kSecClassKey,
            kSecAttrApplicationTag as String: "com.cracksoftware.keys.notification-server-pubkey".data(using: .utf8)!,
            kSecAttrKeyType as String       : kSecAttrKeyTypeRSA,
            kSecReturnRef as String         : true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            print("SecKey retrieval failed! Unregistering now.")
            
            let cancelURL = URL(string: "http://\(UserDefaults.standard.string(forKey: "DRNotificationServer")!)/unregister")!
            
            var deleteRequest = URLRequest(url: cancelURL)
            deleteRequest.httpMethod = "DELETE"
            deleteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let deletePayload: [String: Any] = [
                "device_uuid": UserDefaults.standard.string(forKey: "DRNotificationDeviceUUID")!
            ]
            
            deleteRequest.httpBody = try! JSONSerialization.data(withJSONObject: deletePayload, options: .prettyPrinted)
            
            let deleteSession = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
            
            deleteSession.dataTask(with: deleteRequest) { data, response, error in
                
            }.resume()
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: "Failed to retrieve the notification server encryption key in the keychain. Notification registration failed.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
            
            return
        }
        
        let pubkey = item as! SecKey
        
        let keyInsidePubKey = (SecKeyCopyExternalRepresentation(pubkey, nil)! as Data).base64EncodedString()
        
        print(keyInsidePubKey)
        
        print("Success! Encrypting token collection...")
        
        let encryptedDeviceToken = encrypt(string: deviceToken, publicKey: pubkey)
        let encryptedUserID = encrypt(string: String(SwiftRant.shared.tokenFromKeychain!.authToken.userID), publicKey: pubkey)
        let encryptedTokenID = encrypt(string: String(SwiftRant.shared.tokenFromKeychain!.authToken.tokenID), publicKey: pubkey)
        let encryptedTokenKey = encrypt(string: SwiftRant.shared.tokenFromKeychain!.authToken.tokenKey, publicKey: pubkey)
        let encryptedExpireTime = encrypt(string: String(SwiftRant.shared.tokenFromKeychain!.authToken.expireTime), publicKey: pubkey)
        
        print("Success! Sending encrypted token collection to server...")
        
        let payload: [String: String] = [
            "device_uuid": UserDefaults.standard.string(forKey: "DRNotificationDeviceUUID")!,
            "device_token": encryptedDeviceToken!,
            "user_id": encryptedUserID!,
            "token_id": encryptedTokenID!,
            "token_key": encryptedTokenKey!,
            "token_expire_time": encryptedExpireTime!
        ]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        
        let session = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
        
        session.dataTask(with: request) { data, response, error in
            let result = try! JSONSerialization.jsonObject(with: data!, options: [])
            
            if let jsonObject = result as? [String: Any] {
                if let success = jsonObject["success"] as? Bool, success {
                    print("REGISTRATION SUCCESS!")
                } else {
                    print("Failed to register encrypted token collection! Unregistering now.")
                    
                    let cancelURL = URL(string: "http://\(UserDefaults.standard.string(forKey: "DRNotificationServer")!)/unregister")!
                    
                    var deleteRequest = URLRequest(url: cancelURL)
                    deleteRequest.httpMethod = "DELETE"
                    deleteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let deletePayload: [String: Any] = [
                        "device_uuid": UserDefaults.standard.string(forKey: "DRNotificationDeviceUUID")!
                    ]
                    
                    deleteRequest.httpBody = try! JSONSerialization.data(withJSONObject: deletePayload, options: .prettyPrinted)
                    
                    let deleteSession = URLSession(configuration: .default, delegate: invalidCertificateDelegate(), delegateQueue: OperationQueue.main)
                    
                    deleteSession.dataTask(with: deleteRequest) { data, response, error in
                        
                    }.resume()
                    
                    DispatchQueue.main.async {
                        let error = jsonObject["error"] as? String
                        let alert = UIAlertController(title: "Error", message: "\(error != nil ? "Server: \(error!)" : "Failed to add token collection to the server. Notification registration failed.")", preferredStyle: .alert)
                        
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }.resume()
        
        connectButton.subviews.first(where: { String(describing: type(of: $0)) == "UIActivityIndicator" })
    }
    
    func string(byRemovingControlCharacters inputString: String) -> String {
        let controlChars = CharacterSet.controlCharacters
        var range = (inputString as NSString).rangeOfCharacter(from: controlChars)
        if range.location != NSNotFound {
            var mutable = inputString
            while range.location != NSNotFound {
                if let subRange = Range<String.Index>(range, in: mutable) { mutable.removeSubrange(subRange) }
                range = (mutable as NSString).rangeOfCharacter(from: controlChars)
            }
            return mutable
        }
        return inputString
    }
}
