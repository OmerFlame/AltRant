//
//  APIRequest.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 9/13/20.
//

import Foundation
/*import UIKit
//import Sentry

enum APIError: Error {
    case responseError
    case decodingError
    case badCredentialsError
    case otherError
}

enum RantType: Int {
    case rant = 1
    case collab = 2
    case meme = 3
    case question = 4
    case devRant = 5
    case random = 6
    case undefined = 7
}

enum NotificationContentCategory: String {
    case all
    case upvotes
    case mentions
    case comments
    case subs
}

class APIRequest {
    var resourceURL: URL!
    var request: URLRequest!
    
    //@Binding var success: Bool?
    //@Binding var authTokenID: Int
    //@Binding var authTokenKey: String?
    //@Binding var authTokenExpireTime: Int?
    //@Binding var authTokenUserID: Int
    
    let userIDUserDefaultsIdentifier: String!
    let tokenIDUserDefaultsIdentifier: String!
    let tokenKeyUserDefaultsIdentifier: String!
    
    init() {
        //self._success = success
        //self._authTokenID = authTokenID
        //self._authTokenKey = authTokenKey
        //self._authTokenExpireTime = authTokenExpireTime
        //self._authTokenUserID = authTokenUserID
        
        self.userIDUserDefaultsIdentifier = "DRUserID"
        self.tokenIDUserDefaultsIdentifier = "DRTokenID"
        self.tokenKeyUserDefaultsIdentifier = "DRTokenKey"
    }
    
    func logIn(username: String, password: String) {
        self.resourceURL = URL(string: "https://devrant.com/api/users/auth-token?app=3")!
        //self.resourceURL = URL(string: "https://proxy.devrant.app/api/users/auth-token?app=3")!
        self.request = URLRequest(url: self.resourceURL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "app=3&username=\(username)&password=\(password.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)".data(using: .utf8)
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var receivedRawJSON = String()
        
        
        let task = URLSession.shared.dataTask(with: self.request) { data, response, error in
            if let response = response {
                print(response)
                
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    receivedRawJSON = body
                    //print(body)
                    completionSemaphore.signal()
                }
            }
        }
        
        defer {
            completionSemaphore.wait()
            var extractedCredentials: UserCredentials!
            let dataFromString = receivedRawJSON.data(using: .utf8)
            
            let decoder = JSONDecoder()
            
            do {
                extractedCredentials = try decoder.decode(UserCredentials.self, from: dataFromString!)
            } catch let error {
                //self.authTokenID = 0
                //self.authTokenKey = nil
                //self.authTokenUserID = 0
                
                UserDefaults.standard.set(0, forKey: self.userIDUserDefaultsIdentifier)
                UserDefaults.standard.set(nil, forKey: self.tokenKeyUserDefaultsIdentifier)
                UserDefaults.standard.setValue(0, forKey: self.tokenIDUserDefaultsIdentifier)
                print(error.localizedDescription)
                //return
                
            }
            
            if extractedCredentials != nil && extractedCredentials.auth_token != nil {
                DispatchQueue.main.async {
                    //self.success = extractedCredentials.success!
                    //self.authTokenID = extractedCredentials.auth_token!.id
                    //self.authTokenKey = extractedCredentials.auth_token!.key
                    //self.authTokenExpireTime = extractedCredentials.auth_token!.expire_time
                    //self.authTokenUserID = extractedCredentials.auth_token!.user_id
                    
                    UserDefaults.standard.set(extractedCredentials.auth_token!.id, forKey: self.tokenIDUserDefaultsIdentifier)
                    UserDefaults.standard.set(extractedCredentials.auth_token!.key, forKey: self.tokenKeyUserDefaultsIdentifier)
                    UserDefaults.standard.set(extractedCredentials.auth_token!.user_id, forKey: self.userIDUserDefaultsIdentifier)
                    UserDefaults.standard.set(extractedCredentials.auth_token!.expire_time, forKey: "DRTokenExpireTime")
                    
                    UserDefaults.standard.set(username, forKey: "DRUsername")
                    UserDefaults.standard.set(password, forKey: "DRPassword")
                }
            }
        }
        
        task.resume()
    }
    
    func getRantFeed(skip: Int) -> RantFeed {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        var extractedData: RantFeed?
        
        //var resourceURL = URL(string: "https://devrant.com/api/devrant/rants?app=3&token_id=\(String(UserDefaults.standard.integer(forKey: "TokenID")))&token_key=\(UserDefaults.standard.string(forKey: "TokenKey")?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&user_id=\(String(UserDefaults.standard.integer(forKey: "UserID")))&range=week&limit=20")!
        //self.resourceURL = URL(string: "https://proxy.devrant.app/api/devrant/rants?app=3&sort=recent&token_id=\(String(UserDefaults.standard.integer(forKey: "TokenID")))&token_key=\(UserDefaults.standard.string(forKey: "TokenKey")!)&user_id=\(String(UserDefaults.standard.integer(forKey: "UserID")))&range=null&limit=20&skip=\(String(skip))")
        
        //print("LAST SET:  \(String(UserDefaults.standard.string(forKey: "DRLastSet")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
        //print("USER ID:   \(String(UserDefaults.standard.integer(forKey: "DRUserID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
        //print("TOKEN ID:  \(String(UserDefaults.standard.integer(forKey: "DRTokenID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
        //print("TOKEN KEY: \(String(UserDefaults.standard.string(forKey: "DRTokenKey")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
        
        var resourceURL: URL {
            if UserDefaults.standard.string(forKey: "DRLastSet") != nil {
                return URL(string: "https://devrant.com/api/devrant/rants?limit=20&skip=\(String(skip).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&sort=algo&prev_set=\(String(UserDefaults.standard.string(forKey: "DRLastSet")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&app=3&plat=1&nari=1&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_key=\(String(UserDefaults.standard.string(forKey: "DRTokenKey")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
            } else {
                return URL(string: "https://devrant.com/api/devrant/rants?limit=20&skip=\(String(skip).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&sort=algo&app=3&plat=1&nari=1&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_key=\(String(UserDefaults.standard.string(forKey: "DRTokenKey")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
            }
        }
        
        /*var resourceURL: URL {
            if UserDefaults.standard.string(forKey: "DRLastSet") != nil {
                return URL(string: "https://devrant.com/api/devrant/rants?app=3&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&sort=top&range=week&limit=20&skip=\(skip)&prev_set=\(UserDefaults.standard.string(forKey: "DRLastSet")!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            } else {
                return URL(string: "https://devrant.com/api/devrant/rants?app=3&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&sort=top&range=week&limit=20&skip=\(skip)")!
            }
        }*/
        
        //var resourceURL = URL(string: "https://devrant.com/api/devrant/rants?limit=20&skip=\(String(skip).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&sort=algo&app=3&plat=1&nari=1&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_key=\(String(UserDefaults.standard.string(forKey: "DRTokenKey")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        
        var request = URLRequest(url: resourceURL)
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        //request.httpBody = "app=3&token_id=\(String(tokenID))&token_key=\(tokenKey)&user_id=\(String(userID))&range=week&limit=20".data(using: .utf8)
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var receivedRawJSON = String()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let response = response {
                DispatchQueue.global(qos: .background).async {
                    //print(response)
                    
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        receivedRawJSON = body
                        //print(body)
                        
                        let dataFromString = receivedRawJSON.data(using: .utf8)
                        
                        let decoder = JSONDecoder()
                        
                        extractedData = try! decoder.decode(RantFeed.self, from: dataFromString!)
                        completionSemaphore.signal()
                    }
                }
            }
        }
        
        task.resume()
        
        completionSemaphore.wait()
        UserDefaults.standard.setValue(extractedData!.set, forKey: "DRLastSet")
        return extractedData!
    }
    
    func getNotificationFeed(shouldGetNewNotifs: Bool, category: NotificationContentCategory, completionHandler: @escaping (NotificationFeed?) -> Void) {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        var resourceURL: URL!
        
        if category == .all {
            resourceURL = URL(string: "https://devrant.com/api/users/me/notif-feed?last_time=\(String(shouldGetNewNotifs ? UserDefaults.standard.integer(forKey: "DRLastNotifCheckTime") : 0))&ext_prof=1&app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        } else {
            resourceURL = URL(string: "https://devrant.com/api/users/me/notif-feed/\(category.rawValue)?last_time=\(String(shouldGetNewNotifs ? UserDefaults.standard.integer(forKey: "DRLastNotifCheckTime") : 0))&ext_prof=1&app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        }
        
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        /*let completionSemaphore = DispatchSemaphore(value: 0)
        var content: NotificationFeed? = nil
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            UserDefaults.standard.setValue(Int(Date().timeIntervalSince1970), forKey: "DRLastNotifCheckTime")
            let body = String(data: data!, encoding: .utf8)!
            
            debugPrint(body)
            
            let decoder = JSONDecoder()
            content = try! decoder.decode(NotificationFeed.self, from: body.data(using: .utf8)!)
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return content!*/
        
        let session = URLSession(configuration: .default)
        
        session.dataTask(with: request) { data, response, error in
            UserDefaults.standard.setValue(Int(Date().timeIntervalSince1970), forKey: "DRLastNotifCheckTime")
            
            if let data = data, let body = String(data: data, encoding: .utf8) {
                //debugPrint(body)
                
                let decoder = JSONDecoder()
                let content = try? decoder.decode(NotificationFeed.self, from: body.data(using: .utf8)!)
                
                completionHandler(content)
            }
        }.resume()
    }
    
    func getRantFromID(id: Int, lastCommentID: Int?) throws -> RantResponse? {
        let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(id))?app=3&ver=1.17.0.4&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(String(UserDefaults.standard.string(forKey: "DRTokenKey")!))\(lastCommentID != nil ? "&last_comment_id=\(String(lastCommentID!))" : "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        //self.resourceURL = URL(string: "https://proxy.devrant.app/api/devrant/rants/\(String(id))?app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "UserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "TokenID")))&token_key=\(String(UserDefaults.standard.string(forKey: "TokenKey")!))")
        var request = URLRequest(url: resourceURL)
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var receivedRawJSON = String()
        
        var extractedData: RantResponse?
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if response != nil {
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    //print(response!)
                    
                    receivedRawJSON = body
                    
                    //debugPrint(body)
                    
                    completionSemaphore.signal()
                }
            }
        }
        
        task.resume()
        
        completionSemaphore.wait()
        
        let decoder = JSONDecoder()
        let dataFromString = receivedRawJSON.data(using: .utf8)
        
        do {
            extractedData = try decoder.decode(RantResponse.self, from: dataFromString!)
            
            return extractedData!
        } catch let error {
            print(error.localizedDescription)
            
            throw APIError.decodingError
        }
    }
    
    func getCommentFromID(_ id: Int) -> CommentResponse? {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/comments/\(String(id))?app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var request = URLRequest(url: resourceURL)
        request.httpMethod = "GET"
        request.addValue("application/x-form-www-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var result: CommentResponse?
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let decoder = JSONDecoder()
            result = try? decoder.decode(CommentResponse.self, from: data!)
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return result
    }
    
    func voteOnRant(rantID: Int, vote: Int) -> RantVoteResponse? {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)/vote?cb=\(String(Int(Date().timeIntervalSince1970)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        
        //self.resourceURL = URL(string: "https://proxy.devrant.app/api/devrant/rants/\(String(rantID))/vote")!
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(String(UserDefaults.standard.string(forKey: "DRTokenKey")!))&vote=\(String(vote))".data(using: .utf8)
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var voteResponse: RantVoteResponse? = nil
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let body = String(data: data!, encoding: .utf8)!
            
            //print(body)
            
            let decoder = JSONDecoder()
            voteResponse = try? decoder.decode(RantVoteResponse.self, from: data!)
            
            /*if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                success = true
            } else {
                success = false
            }*/
            
            completionSemaphore.signal()
        }
        
        task.resume()
        
        completionSemaphore.wait()
        return voteResponse
    }
    
    func voteOnComment(commentID: Int, vote: Int) -> CommentVoteResponse? {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/comments/\(String(commentID).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)/vote?cb=\(String(Int(Date().timeIntervalSince1970)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
        
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_key=\(String(UserDefaults.standard.string(forKey: "DRTokenKey")!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&vote=\(String(vote).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)".data(using: .utf8)
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var voteResponse: CommentVoteResponse? = nil
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            //let body = String(data: data!, encoding: .utf8)!
            
            //print(body)
            
            /*if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                success = true
            } else {
                success = false
            }*/
            
            let decoder = JSONDecoder()
            voteResponse = try? decoder.decode(CommentVoteResponse.self, from: data!)
            
            completionSemaphore.signal()
        }
        
        task.resume()
        
        completionSemaphore.wait()
        return voteResponse
    }
    
    /*func getProfileFromID(_ profileID: Int, userContentType: ProfileContentTypes, skip: Int) throws -> ProfileResponse? {
        let userID = UserDefaults.standard.integer(forKey: "DRUserID")
        let tokenID = UserDefaults.standard.integer(forKey: "DRTokenID")
        let tokenKey = UserDefaults.standard.string(forKey: "DRTokenKey")
        
        let resourceURL = URL(string: "https://devrant.com/api/users/\(String(profileID).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)?app=3&skip=\(String(skip).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&content=\(String(userContentType.rawValue).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&user_id=\(String(userID).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_id=\(String(tokenID).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&token_key=\(String(tokenKey!).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")
        
        //let resourceURL = URL(string: "https://proxy.devrant.app/api/users/\(String(profileID))?app=3&skip=\(String(skip))&content=\(String(userContentType.rawValue))&user_id=\(String(userID))&token_id=\(String(tokenID))&token_key=\(String(tokenKey!))")
        self.request = URLRequest(url: resourceURL!)
        self.request.httpMethod = "GET"
        self.request.addValue("application/x-www-form/urlencoded", forHTTPHeaderField: "Content-Type")
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var receivedRawJSON = String()
        
        var extractedData: ProfileResponse?
        
        let task = URLSession.shared.dataTask(with: self.request) { data, response, error in
            if response != nil {
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    receivedRawJSON = body
                    
                    print(body)
                    
                    completionSemaphore.signal()
                }
            }
        }
        
        task.resume()
        
        completionSemaphore.wait()
        
        let decoder = JSONDecoder()
        let dataFromString = receivedRawJSON.data(using: .utf8)
        
        do {
            extractedData = try decoder.decode(ProfileResponse.self, from: dataFromString!)
            
            return extractedData!
        } catch DecodingError.dataCorrupted(let context) {
            print(context)
            
            throw APIError.decodingError
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key: '\(key)' not found: ", context.debugDescription)
            
            throw APIError.decodingError
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value: '\(value)' not found: ", context.debugDescription)
            
            throw APIError.decodingError
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type '\(type)' mismatch: ", context.debugDescription)
            print("codingPath: ", context.codingPath)
            
            throw APIError.decodingError
        } catch let error {
            print(error.localizedDescription)
            
            throw APIError.decodingError
        }
        
        //return nil
    }*/
    
    func getProfileFromID(_ profileID: Int, userContentType: ProfileContentTypes, skip: Int, completionHandler: @escaping (ProfileResponse?) -> Void) {
        let userID = UserDefaults.standard.integer(forKey: "DRUserID")
        let tokenID = UserDefaults.standard.integer(forKey: "DRTokenID")
        let tokenKey = UserDefaults.standard.string(forKey: "DRTokenKey")
        
        let resourceURL = URL(string: "https://devrant.com/api/users/\(String(profileID))?app=3&skip=\(String(skip))&content=\(String(userContentType.rawValue))&user_id=\(String(userID))&token_id=\(String(tokenID))&token_key=\(String(tokenKey!))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "GET"
        request.addValue("application/x-www-form/urlencoded", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            if response != nil {
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    let decoder = JSONDecoder()
                    
                    let extractedData = try? decoder.decode(ProfileResponse.self, from: body.data(using: .utf8)!)
                    
                    completionHandler(extractedData)
                } else {
                    completionHandler(nil)
                }
            } else {
                completionHandler(nil)
            }
        }
        
        task.resume()
    }
    
    func postRant(postType: RantType, content: String, tags: String?, image: UIImage?) -> Int {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        if image != nil {
            let url = URL(string: "https://devrant.com/api/devrant/rants?cb=\(String(Int(Date().timeIntervalSince1970)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
            
            var request = URLRequest(url: url)
            
            let boundary = UUID().uuidString
            
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            let paramList: [String: String] = [
                "app": "3",
                "rant": content,
                "tags": (tags != nil ? tags! : ""),
                "token_id": String(UserDefaults.standard.integer(forKey: "DRTokenID")),
                "token_key": UserDefaults.standard.string(forKey: "DRTokenKey")!,
                "user_id": String(UserDefaults.standard.integer(forKey: "DRUserID")),
                "type": String(postType.rawValue),
                //"plat": "1",
                //"nari": "-1",
            ]
            
            request.httpBody = createBody(parameters: paramList, boundary: boundary, data: image?.jpegData(compressionQuality: 1.0))
            
            print("REQUEST BODY:")
            //print(String(data: request.httpBody!, encoding: .utf8))
            print(String(decoding: request.httpBody!, as: UTF8.self))
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            
            var postID = 0
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                //print("RESPONSE BODY: ")
                //print(body)
                
                //receivedRawJSON = body
                
                let decoder = JSONDecoder()
                let result = try! decoder.decode(RantPOSTResponse.self, from: data!)
                
                postID = result.rantID!
                
                completionSemaphore.signal()
            }
            
            task.resume()
            
            completionSemaphore.wait()
            return postID
        } else {
            let url = URL(string: "https://devrant.com/api/devrant/rants?cb=\(String(Int(Date().timeIntervalSince1970)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&rant=\(content)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&tags=\(tags ?? "")&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&type=\(String(postType.rawValue))&app=3".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!.data(using: .utf8)
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var postID = 0
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                //print("RESPONSE BODY:")
                //print(body)
                
                let decoder = JSONDecoder()
                let result = try? decoder.decode(RantPOSTResponse.self, from: data!)
                
                postID = result?.rantID ?? -1
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            return postID
        }
    }
    
    func deleteRant(rantID: Int) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))?app=3&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "DELETE"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var success = false
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                success = true
            } else {
                success = false
            }
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return success
    }
    
    func favoriteRant(rantID: Int) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))/favorite".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var request = URLRequest(url: resourceURL)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = "app=3&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!.data(using: .utf8)
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var success = false
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                success = true
            } else {
                success = false
            }
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return success
    }
    
    func unfavoriteRant(rantID: Int) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))/unfavorite".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var request = URLRequest(url: resourceURL)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = "app=3&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!.data(using: .utf8)
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var success = false
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                success = true
            } else {
                success = false
            }
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return success
    }
    
    func editRant(rantID: Int, postType: RantType, content: String, tags: String?, image: UIImage?) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        if image != nil {
            let url = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))?cb=\(String(Int(Date().timeIntervalSince1970)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
            
            var request = URLRequest(url: url)
            
            let boundary = UUID().uuidString
            
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            request.httpMethod = "POST"
            
            let paramList: [String: String] = [
                "app": "3",
                "rant": content,
                "tags": (tags != nil ? tags! : ""),
                "token_id": String(UserDefaults.standard.integer(forKey: "DRTokenID")),
                "token_key": UserDefaults.standard.string(forKey: "DRTokenKey")!,
                "user_id": String(UserDefaults.standard.integer(forKey: "DRUserID")),
                "type": String(postType.rawValue),
                //"plat": "1",
                //"nari": "-1",
            ]
            
            request.httpBody = createBody(parameters: paramList, boundary: boundary, data: image?.jpegData(compressionQuality: 1.0))
            
            print("REQUEST BODY:")
            //print(String(data: request.httpBody!, encoding: .utf8))
            print(String(decoding: request.httpBody!, as: UTF8.self))
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            
            var success = false
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }
            
            task.resume()
            
            completionSemaphore.wait()
            return success
        } else {
            let url = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))?cb=\(String(Int(Date().timeIntervalSince1970)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&rant=\(content)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&tags=\(tags ?? "")&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&type=\(String(postType.rawValue))&app=3".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!.data(using: .utf8)
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var success = false
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            return success
        }
    }
    
    func postComment(rantID: Int, content: String, image: UIImage?) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        if image != nil {
            let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))/comments?cb=\(String(Int(Date().timeIntervalSince1970)))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            
            var request = URLRequest(url: resourceURL)
            request.httpMethod = "POST"
            
            let boundary = UUID().uuidString
            
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let paramList: [String: String] = [
                "app": "3",
                "comment": content,
                "token_id": String(UserDefaults.standard.integer(forKey: "DRTokenID")),
                "token_key": UserDefaults.standard.string(forKey: "DRTokenKey")!,
                "user_id": String(UserDefaults.standard.integer(forKey: "DRUserID"))
            ]
            
            let body = createBody(parameters: paramList, boundary: boundary, data: image?.jpegData(compressionQuality: 1))
            
            request.httpBody = body
            
            //print(String(decoding: image!.pngData()!, as: UTF8.self))
            //print(String(decoding: request.httpBody!, as: UTF8.self))
            
            //print(String(data: request.httpBody!, encoding: .utf8)!)
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            
            var success = false
            
            /*let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                print(body)
                
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }*/
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                print(body)
                
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            return success
        } else {
            let resourceURL = URL(string: "https://devrant.com/api/devrant/rants/\(String(rantID))/comments?cb=\(String(Int(Date().timeIntervalSince1970)))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            
            var request = URLRequest(url: resourceURL)
            request.httpMethod = "POST"
            
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            request.httpBody = "comment=\(content)&app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))".data(using: .utf8)
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var success = false
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                print(body)
                
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            return success
        }
    }
    
    func editComment(commentID: Int, content: String, image: UIImage?) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        if image != nil {
            let resourceURL = URL(string: "https://devrant.com/api/comments/\(String(commentID))?cb=\(String(Int(Date().timeIntervalSince1970)))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            
            var request = URLRequest(url: resourceURL)
            request.httpMethod = "POST"
            
            let boundary = UUID().uuidString
            
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let paramList: [String: String] = [
                "app": "3",
                "comment": content,
                "token_id": String(UserDefaults.standard.integer(forKey: "DRTokenID")),
                "token_key": UserDefaults.standard.string(forKey: "DRTokenKey")!,
                "user_id": String(UserDefaults.standard.integer(forKey: "DRUserID"))
            ]
            
            let body = createBody(parameters: paramList, boundary: boundary, data: image?.jpegData(compressionQuality: 1))
            
            request.httpBody = body
            
            //print(String(decoding: image!.pngData()!, as: UTF8.self))
            //print(String(decoding: request.httpBody!, as: UTF8.self))
            
            //print(String(data: request.httpBody!, encoding: .utf8)!)
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            
            var success = false
            
            /*let task = URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                print(body)
                
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }*/
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                let body = String(data: data!, encoding: .utf8)!
                
                print(body)
                
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            return success
        } else {
            let resourceURL = URL(string: "https://devrant.com/api/comments/\(String(commentID))?cb=\(String(Int(Date().timeIntervalSince1970)))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
            
            var request = URLRequest(url: resourceURL)
            request.httpMethod = "POST"
            
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = "comment=\(content)&app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!.data(using: .utf8)
            
            let completionSemaphore = DispatchSemaphore(value: 0)
            var success = false
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                    success = true
                } else {
                    success = false
                }
                
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            return success
        }
    }
    
    func deleteComment(commentID: Int) -> Bool {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/comments/\(String(commentID))?app=3&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "DELETE"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let completionSemaphore = DispatchSemaphore(value: 0)
        var success = false
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if (200..<300).contains((response as? HTTPURLResponse)!.statusCode) {
                success = true
            } else {
                success = false
            }
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return success
    }
    
    func getAvatarCustomizationOptions(option: String, subOption: Int?, currentImageURL: String, shouldGetPossibleOptions: Bool, completionHandler: ((AvatarCustomizationResults?) -> Void)?) {
        if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
            logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
        }
        
        let resourceURL = URL(string: "https://devrant.com/api/devrant/avatars/build?app=3&option=\(option)&image_id=\(currentImageURL)&features=\(shouldGetPossibleOptions ? String(1) : String(0))\(subOption != nil ? "&sub_option=\(String(subOption!))" : "")&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "GET"
        request.addValue("x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var results: AvatarCustomizationResults? = nil
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            let decoder = JSONDecoder()
            
            results = try? decoder.decode(AvatarCustomizationResults.self, from: data!)
            
            completionHandler?(results)
        }.resume()
    }
	
	func confirmAvatarCustomization(fullImageURL: String, completionHandler: ((Bool, String?) -> Void)?) {
		if Double(UserDefaults.standard.integer(forKey: "DRTokenExpireTime")) - Double(Date().timeIntervalSince1970) <= 0 {
			logIn(username: UserDefaults.standard.string(forKey: "DRUsername")!, password: UserDefaults.standard.string(forKey: "DRPassword")!)
		}
		
		let resourceURL = URL(string: "https://devrant.com/api/users/me/avatar")!
		var request = URLRequest(url: resourceURL)
		
		request.httpMethod = "POST"
		request.httpBody = "token_id=\(String(UserDefaults.standard.integer(forKey: "DRTokenID")))&app=3&image_id=\(fullImageURL)&user_id=\(String(UserDefaults.standard.integer(forKey: "DRUserID")))&token_key=\(UserDefaults.standard.string(forKey: "DRTokenKey")!)".data(using: .utf8)
		
		request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		
		URLSession.shared.dataTask(with: request) { data, response, error in
			enum CodingKeys: String, CodingKey {
				case success
			}
			
			let jsonObject = try! JSONSerialization.jsonObject(with: data!, options: [])
			
			if let jObject = jsonObject as? [String: Any] {
				if let success = jObject["success"] as? Bool {
					if success {
						completionHandler?(success, nil)
					} else {
						completionHandler?(success, jObject["error"] as! String)
					}
				}
			} else {
				//SentrySDK.capture(message: "Response decode error")
				completionHandler?(false, "Response decode error.")
			}
		}.resume()
	}
    
    public func getUserID(username: String, completionHandler: @escaping ((Int?) -> Void)) {
        let resourceURL = URL(string: "https://devrant.com/api/get-user-id?app=3&username=\(username)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var request = URLRequest(url: resourceURL)
        
        request.httpMethod = "GET"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: .default)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let jsonObject = try! JSONSerialization.jsonObject(with: data, options: [])
                
                if let jObject = jsonObject as? [String:Any] {
                    if let success = jObject["success"] as? Bool {
                        if success {
                            completionHandler(jObject["user_id"] as? Int)
                            return
                        }
                    }
                }
            } else {
                completionHandler(nil)
            }
        }.resume()
    }
    
    private func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data?) -> Data {
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        if data != nil {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpeg\"\r\n")
            body.appendString("Content-Type: image/jpeg\r\n\r\n")
            body.append(data!)
            body.appendString("\r\n")
        }
        
        body.appendString("--".appending(boundary.appending("--")))
        
        return body
    }
}*/

extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: .utf8, allowLossyConversion: false)
        append(data!)
    }
}
