//
//  Comment.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 9/14/20.
//

import Foundation

struct CommentModel: Codable, Identifiable {
    var uuid = UUID()
    
    let id: Int
    let rant_id: Int
    let body: String
    let score: Int
    let created_time: Int
    var vote_state: Int
    let links: [Link]?
    let user_id: Int
    let user_username: String
    let user_score: Int
    let user_avatar: UserAvatar
    let user_dpp: Int?
    let attached_image: AttachedImage?
    
    private enum CodingKeys: String, CodingKey {
        case id,
             rant_id,
             body,
             score,
             created_time,
             vote_state,
             links,
             user_id,
             user_username,
             user_score,
             user_avatar,
             user_dpp,
             attached_image
    }
    
    init(id: Int,
         rant_id: Int,
         body: String,
         score: Int,
         created_time: Int,
         vote_state: Int,
         links: [Link]?,
         user_id: Int,
         user_username: String,
         user_score: Int,
         user_avatar: UserAvatar,
         user_dpp: Int?,
         attached_image: AttachedImage?) {
        
        self.id = id
        self.rant_id = rant_id
        self.body = body
        self.score = score
        self.created_time = created_time
        self.vote_state = vote_state
        self.links = links
        self.user_id = user_id
        self.user_username = user_username
        self.user_score = user_score
        self.user_avatar = user_avatar
        self.user_dpp = user_dpp
        self.attached_image = attached_image
    }
    
    public init(decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        rant_id = try values.decode(Int.self, forKey: .rant_id)
        body = try values.decode(String.self, forKey: .body)
        score = try values.decode(Int.self, forKey: .score)
        created_time = try values.decode(Int.self, forKey: .created_time)
        vote_state = try values.decode(Int.self, forKey: .vote_state)
        links = try? values.decode([Link].self, forKey: .links)
        user_id = try values.decode(Int.self, forKey: .user_id)
        user_username = try values.decode(String.self, forKey: .user_username)
        user_score = try values.decode(Int.self, forKey: .user_score)
        user_avatar = try values.decode(UserAvatar.self, forKey: .user_avatar)
        user_dpp = try? values.decode(Int.self, forKey: .user_dpp)
        attached_image = try? values.decode(AttachedImage.self, forKey: .attached_image)
    }
}
