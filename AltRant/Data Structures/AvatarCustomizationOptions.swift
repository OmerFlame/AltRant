//
//  AvatarCustomizationOptions.swift
//  AltRant
//
//  Created by Omer Shamai on 1/17/21.
//

import Foundation

class AvatarCustomizationImage: Decodable {
    let backgroundColor: String
    //var fullImage: UIImage
    //var midCompleteImage: UIImage
    
    let fullImageName: String
    let midImageName: String
    
    enum CodingKeys: String, CodingKey {
        case backgroundColor = "b",
			 fullImage = "full",
             midCompleteImage = "mid"
    }
    
	required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        backgroundColor = try values.decode(String.self, forKey: .backgroundColor)
        
        midImageName = try values.decode(String.self, forKey: .midCompleteImage)
        
        //var temporaryImage = UIImage()
        
        let midURL = URL(string: "https://avatars.devrant.com/\(try values.decode(String.self, forKey: .midCompleteImage))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        var request = URLRequest(url: midURL)
        
        request.httpMethod = "GET"
        
        //let completionSemaphore = DispatchSemaphore(value: 0)
        
        //let session = URLSession(configuration: .default)
		
		//midCompleteImage = UIImage()
		
		fullImageName = try values.decode(String.self, forKey: .fullImage)
        
        /*session.dataTask(with: request) { data, _, _ in
			self.midCompleteImage = UIImage(data: data!)!
            
            //completionSemaphore.signal()
        }.resume()*/
        
        //completionSemaphore.wait()
        
        //midCompleteImage = temporaryImage
		
        /*
        
        let fullImageURL = URL(string: "https://avatars.devrant.com/\(try values.decode(String.self, forKey: .fullImage))".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        
        request = URLRequest(url: fullImageURL)
        
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { data, _, _ in
            temporaryImage = UIImage(data: data!)!
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        
        fullImage = temporaryImage*/
    }
	
	func getFullImage(completion: ((UIImage) -> (Void))?) {
		if let cachedFile = FileManager.default.contents(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fullImageName).relativePath) {
			completion?(UIImage(data: cachedFile)!)
		} else {
			let url = URL(string: "https://avatars.devrant.com/\(fullImageName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			
			URLSession.shared.dataTask(with: request) { data, _, _ in
				FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(self.fullImageName).relativePath, contents: data!, attributes: nil)
				
				completion?(UIImage(data: data!)!)
			}.resume()
		}
	}
	
	func getMidCompleteImage(completion: ((UIImage) -> (Void))?) {
		if let cachedFile = FileManager.default.contents(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(midImageName).relativePath) {
			completion?(UIImage(data: cachedFile)!)
		} else {
			let session = URLSession(configuration: .default)
			
			let url = URL(string: "https://avatars.devrant.com/\(midImageName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			var request = URLRequest(url: url)
			request.httpMethod = "GET"
			
			session.dataTask(with: request) { data, _, _ in
				FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(self.midImageName).relativePath, contents: data!, attributes: nil)
				
				completion?(UIImage(data: data!)!)
			}.resume()
		}
	}
}

struct AvatarCustomizationCurrentUserInfo: Decodable {
    var score: Int
}

struct AvatarCustomizationOption: Decodable {
    let forGender: String?
    let id: String
    let label: String
    let subType: Int?
    
    enum CodingKeys: String, CodingKey {
        case id,
             label,
             subType = "sub_type",
             forGender = "for_gender"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            id = try values.decode(String.self, forKey: .id)
        } catch {
            id = try String(values.decode(Int.self, forKey: .id))
        }
        
        label = try values.decode(String.self, forKey: .label)
        subType = try values.decodeIfPresent(Int.self, forKey: .subType)
        forGender = try values.decodeIfPresent(String.self, forKey: .forGender)
    }
}

struct AvatarCustomizationResult: Decodable {
    let backgroundColor: String?
    let id: String?
    let image: AvatarCustomizationImage
    let requiredPoints: Int?
    let isSelected: Bool?
    
    enum CodingKeys: String, CodingKey {
        case backgroundColor = "bg",
             id,
             image = "img",
             requiredPoints = "points",
             isSelected = "selected"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        backgroundColor = try values.decodeIfPresent(String.self, forKey: .backgroundColor)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        image = try values.decode(AvatarCustomizationImage.self, forKey: .image)
        //requiredPoints = try values.decodeIfPresent(Int.self, forKey: .requiredPoints)
		requiredPoints = try? values.decode(Int.self, forKey: .requiredPoints)
        isSelected = try values.decodeIfPresent(Bool.self, forKey: .isSelected)
    }
}

struct AvatarCustomizationResults: Decodable {
    let avatars: [AvatarCustomizationResult]
    let userInfo: AvatarCustomizationCurrentUserInfo
    let options: [AvatarCustomizationOption]?
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case avatars,
             userInfo = "me",
             options,
             success
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let decodedAvatars = try? values.decode([AvatarCustomizationResult].self, forKey: .avatars) {
            avatars = decodedAvatars
        } else {
            avatars = []
        }
        
        userInfo = try values.decode(AvatarCustomizationCurrentUserInfo.self, forKey: .userInfo)
        options = try values.decodeIfPresent([AvatarCustomizationOption].self, forKey: .options)
        success = try values.decode(Bool.self, forKey: .success)
    }
}
