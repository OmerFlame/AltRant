//
//  AvatarCustomizationOptions.swift
//  AltRant
//
//  Created by Omer Shamai on 1/17/21.
//

import Foundation

struct AvatarCustomizationImage: Decodable {
    let backgroundColor: String
    let fullImage: String
    let midCompleteImage: String
    
    enum CodingKeys: String, CodingKey {
        case backgroundColor = "b",
             fullImage = "full",
             midCompleteImage = "mid"
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
             requiredPoints = "required",
             isSelected = "selected"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        backgroundColor = try values.decodeIfPresent(String.self, forKey: .backgroundColor)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        image = try values.decode(AvatarCustomizationImage.self, forKey: .image)
        requiredPoints = try values.decodeIfPresent(Int.self, forKey: .requiredPoints)
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
