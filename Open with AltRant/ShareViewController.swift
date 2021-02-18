//
//  ShareViewController.swift
//  Open with AltRant
//
//  Created by Omer Shamai on 2/18/21.
//

import UIKit
import MobileCoreServices
import CoreData

enum DROpenErrors: Error {
    case invalidURL
}

@objc(ShareExtensionViewController)
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attachment = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = kUTTypeURL as String
        
        if attachment.count == 1 {
            if attachment[0].hasItemConformingToTypeIdentifier(contentType) {
                attachment[0].loadItem(forTypeIdentifier: contentType, options: nil) { [unowned self] (data, error) in
                    guard error == nil else { extensionContext?.cancelRequest(withError: error!); return }
                    
                    let regularExpressions = [
                        try! NSRegularExpression(pattern: #"www\.devrant\.com"#),
                        try! NSRegularExpression(pattern: #"([\S]+\.)devrant\.com"#),
                        try! NSRegularExpression(pattern: #"devrant\.com"#),
                        try! NSRegularExpression(pattern: #"www\.devrant\.io"#),
                        try! NSRegularExpression(pattern: #"([\S]+\.)devrant\.io"#),
                        try! NSRegularExpression(pattern: #"devrant\.io"#)
                    ]
                    
                    if let url = data as? URL {
                        for regex in regularExpressions {
                            if let host = url.host {
                                if !regex.matches(in: host, range: (host as NSString).range(of: host)).isEmpty {
                                    for component in url.pathComponents {
                                        if let rantID = Int(component) {
                                            //extensionContext?.open(URL(string: "devrant:\(rantID)")!, completionHandler: nil)
                                            
                                            UserDefaults.group.set(URL(string: "altrant://\(rantID)")!, forKey: "ARSharedLink")
                                            
                                             _ = openURL(URL(string: "altrant://\(rantID)")!)
                                            
                                            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                                        }
                                    }
                                }
                            }
                        }
                        
                        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    } else if let url = URL(string: String(data: data as? Data ?? Data(), encoding: .utf8)!) {
                        for regex in regularExpressions {
                            if let host = url.host {
                                if !regex.matches(in: host, range: (host as NSString).range(of: host)).isEmpty {
                                    for component in url.pathComponents {
                                        if let rantID = Int(component) {
                                            //extensionContext?.open(URL(string: "devrant:\(rantID)")!, completionHandler: nil)
                                            
                                            UserDefaults.group.set(URL(string: "altrant://\(rantID)")!, forKey: "ARSharedLink")
                                            
                                             _ = openURL(URL(string: "altrant://\(rantID)")!)
                                            
                                            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            
            responder = responder?.next
        }
        
        return false
    }
}
