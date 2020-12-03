//
//  RantInFeed.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 9/25/20.
//

import Foundation

public struct RantInFeed: Codable, Identifiable {
    let uuid = UUID()
    
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
    
    let rt: Int?
    let rc: Int?
    
    let c_type: Int?
    let c_type_long: String?
    
    let user_id: Int
    let user_username: String
    let user_score: Int
    let user_avatar: UserAvatar
    let user_avatar_lg: UserAvatar
    let user_dpp: Int?
    
    enum CodingKeys: String, CodingKey {
        case id,
             text,
             score,
             created_time,
             attached_image,
             num_comments,
             tags,
             vote_state,
             edited,
             link,
             rt,
             rc,
             c_type,
             c_type_long,
             user_id,
             user_username,
             user_score,
             user_avatar,
             user_avatar_lg,
             user_dpp
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
        edited = try values.decode(Bool.self, forKey: .edited)
        link = try? values.decode(String.self, forKey: .link)
        rt = try? values.decode(Int.self, forKey: .rt)
        rc = try? values.decode(Int.self, forKey: .rc)
        c_type = try? values.decode(Int.self, forKey: .c_type)
        c_type_long = try? values.decode(String.self, forKey: .c_type_long)
        user_id = try values.decode(Int.self, forKey: .user_id)
        user_username = try values.decode(String.self, forKey: .user_username)
        user_score = try values.decode(Int.self, forKey: .user_score)
        user_avatar = try values.decode(UserAvatar.self, forKey: .user_avatar)
        user_avatar_lg = try values.decode(UserAvatar.self, forKey: .user_avatar_lg)
        user_dpp = try? values.decode(Int.self, forKey: .user_dpp)
    }
}
