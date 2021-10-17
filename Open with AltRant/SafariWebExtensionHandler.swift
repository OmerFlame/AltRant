//
//  SafariWebExtensionHandler.swift
//  Open with AltRant
//
//  Created by Omer Shamai on 03/10/2021.
//

import SafariServices
import os.log
import MobileCoreServices
import UIKit

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems[0] as! NSExtensionItem
        let message = item.userInfo![SFExtensionMessageKey]
        os_log(.error, "Received message from browser.runtime.sendNativeMessage: %@", message as! CVarArg)
        
        let regularExpressions = [
            try! NSRegularExpression(pattern: #"www\.devrant\.com"#),
            try! NSRegularExpression(pattern: #"([\S]+\.)devrant\.com"#),
            try! NSRegularExpression(pattern: #"devrant\.com"#),
            try! NSRegularExpression(pattern: #"www\.devrant\.io"#),
            try! NSRegularExpression(pattern: #"([\S]+\.)devrant\.io"#),
            try! NSRegularExpression(pattern: #"devrant\.io"#)
        ]
        
        if let message = (message as! Dictionary<String, String>)["message"] {
            if let url = URL(string: message) {
                for regularExpression in regularExpressions {
                    if let host = url.host {
                        if !regularExpression.matches(in: host, range: (host as NSString).range(of: host)).isEmpty {
                            os_log("PATH COMPONENTS:")
                            for component in url.pathComponents {
                                os_log(.default, "%@", component as CVarArg)
                            }
                            
                            if url.pathComponents.contains("users") && url.pathComponents.count == 3 {
                                let finalURL = URL(string: "altrant://\(url.lastPathComponent)")!
                                os_log(.default, "FINAL APPLINK URL: %@", finalURL.absoluteString as CVarArg)
                                
                                /*context.open(finalURL, completionHandler: { success in
                                    SFSafariApplication
                                    os_log(.default, "OPEN SUCCESS: \(success)")
                                })*/
                                
                                let response = NSExtensionItem()
                                response.userInfo = [ SFExtensionMessageKey: [ "Response to": finalURL.absoluteString ] ]
                                context.completeRequest(returningItems: [response], completionHandler: nil)
                                break
                            }
                        }
                    }
                }
            }
        }
        
        //context.open(<#T##URL: URL##URL#>, completionHandler: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)

        //let response = NSExtensionItem()
        //response.userInfo = [ SFExtensionMessageKey: "bruh" ]

        //context.completeRequest(returningItems: [response], completionHandler: nil)
        
        
    }

}
