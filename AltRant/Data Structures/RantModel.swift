//
//  RantStructure.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 9/13/20.
//

import Foundation

public struct RantModel: Codable, Identifiable {
    public let uuid = UUID()
    
    let weekly: Weekly?
    
    public let id: Int
    let text: String
    var score: Int
    
    let created_time: Int
    
    let attached_image: AttachedImage?
    
    let num_comments: Int
    
    let tags: [String]
    
    var vote_state: Int
    
    let edited: Bool
    
    let link: String?
    
    let rt: Int
    let rc: Int
    
    let links: [Link]?
    
    let special: Int?
    
    let c_type_long: String?
    let c_description: String?
    let c_tech_stack: String?
    let c_team_size: String?
    let c_url: String?
    
    let user_id: Int
    var user_username: String
    let user_score: Int
    
    let user_avatar: UserAvatar
    let user_avatar_lg: UserAvatar
    
    let user_dpp: Int?
    
    let comments: [CommentModel]?
    
    enum CodingKeys: String, CodingKey {
        case id,
             text,
             score,
             created_time,
             attached_image,
             num_comments,
             tags,
             vote_state,
             weekly,
             edited,
             link,
             rt,
             rc,
             links,
             special,
             c_type_long,
             c_description,
             c_tech_stack,
             c_team_size,
             c_url,
             user_id,
             user_username,
             user_score,
             user_avatar,
             user_avatar_lg,
             user_dpp,
             comments
    }
    
    init(id: Int,
         text: String,
         score: Int,
         created_time: Int,
         attached_image: AttachedImage?,
         num_comments: Int,
         tags: [String],
         vote_state: Int,
         weekly: Weekly?,
         edited: Bool,
         link: String?,
         rt: Int,
         rc: Int,
         links: [Link]?,
         special: Int?,
         c_type_long: String?,
         c_description: String?,
         c_tech_stack: String?,
         c_team_size: String?,
         c_url: String?,
         user_id: Int,
         user_username: String,
         user_score: Int,
         user_avatar: UserAvatar,
         user_avatar_lg: UserAvatar,
         user_dpp: Int?,
         comments: [CommentModel]?) {
        
        self.id = id
        self.text = text
        self.score = score
        self.created_time = created_time
        self.attached_image = attached_image
        self.num_comments = num_comments
        self.tags = tags
        self.vote_state = vote_state
        self.weekly = weekly
        self.edited = edited
        self.link = link
        self.rt = rt
        self.rc = rc
        self.links = links
        self.special = special
        self.c_type_long = c_type_long
        self.c_description = c_description
        self.c_tech_stack = c_tech_stack
        self.c_team_size = c_team_size
        self.c_url = c_url
        self.user_id = user_id
        self.user_username = user_username
        self.user_score = user_score
        self.user_avatar = user_avatar
        self.user_avatar_lg = user_avatar_lg
        self.user_dpp = user_dpp
        self.comments = comments
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        text = try values.decode(String.self, forKey: .text)
        score = try values.decode(Int.self, forKey: .score)
        created_time = try values.decode(Int.self, forKey: .created_time)
        
        do {
            attached_image = try values.decode(AttachedImage.self, forKey: .attached_image)
        } catch {
            attached_image = nil
        }
        
        num_comments = try values.decode(Int.self, forKey: .num_comments)
        tags = try values.decode([String].self, forKey: .tags)
        vote_state = try values.decode(Int.self, forKey: .vote_state)
        weekly = try? values.decode(Weekly.self, forKey: .weekly)
        edited = try values.decode(Bool.self, forKey: .edited)
        link = try? values.decode(String.self, forKey: .link)
        rt = try values.decode(Int.self, forKey: .rt)
        rc = try values.decode(Int.self, forKey: .rc)
        links = try? values.decode([Link].self, forKey: .links)
        special = try? values.decode(Int.self, forKey: .special)
        c_type_long = try? values.decode(String.self, forKey: .c_type_long)
        c_description = try? values.decode(String.self, forKey: .c_description)
        c_tech_stack = try? values.decode(String.self, forKey: .c_tech_stack)
        c_team_size = try? values.decode(String.self, forKey: .c_team_size)
        c_url = try? values.decode(String.self, forKey: .c_url)
        user_id = try values.decode(Int.self, forKey: .user_id)
        user_username = try values.decode(String.self, forKey: .user_username)
        user_score = try values.decode(Int.self, forKey: .user_score)
        user_avatar = try values.decodeIfPresent(UserAvatar.self, forKey: .user_avatar)!
        user_avatar_lg = try values.decode(UserAvatar.self, forKey: .user_avatar_lg)
        user_dpp = try? values.decode(Int.self, forKey: .user_dpp)
        comments = try? values.decode([CommentModel].self, forKey: .comments)
    }
}

enum Polytype: Codable {
    case string(String)
    case attachedImage(AttachedImage)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(AttachedImage.self) {
            self = .attachedImage(x)
            return
        }
        throw DecodingError.typeMismatch(Polytype.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Polytype"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
            
        case .attachedImage(let x):
            try container.encode(x)
        }
    }
}

struct AttachedImage: Codable {
    //let attached_image: String?
    
    let url: String?
    let width: Int?
    let height: Int?
}

struct UserAvatar: Codable {
    let b: String
    let i: String?
}

public struct Link: Codable {
    let type: String
    let url: String
    let short_url: String
    let title: String
    let start: Int
    let end: Int
    let special: Int
}

public struct Weekly: Codable {
    let date: String
    let height: Int
    let topic: String
    let week: Int
}

public struct RantPOSTResponse: Codable {
    let success: Bool
    let rantID: Int?
    
    enum CodingKeys: String, CodingKey {
        case success,
             rantID = "rant_id"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try container.decode(Bool.self, forKey: .success)
        
        do {
            rantID = try container.decode(Int.self, forKey: .rantID)
        } catch {
            rantID = -1
        }
    }
}
