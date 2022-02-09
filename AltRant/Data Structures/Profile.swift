//
//  Profile.swift
//  devRantAvatarEditor
//
//  Created by Omer Shamai on 9/25/20.
//

/*import Foundation

struct Profile: Codable {
    let username: String
    let score: Int
    let about: String
    let location: String
    let created_time: Int
    let skills: String
    let github: String
    let website: String?
    var content: OuterUserContent
    let avatar: UserAvatar
    let avatar_sm: UserAvatar
    let dpp: Int?
}

struct OuterUserContent: Codable {
    let content: InnerUserContent
    let counts: UserCounts
}

struct InnerUserContent: Codable {
    var rants: [RantInFeed]
    var upvoted: [RantInFeed]
    var comments: [CommentModel]
    var favorites: [RantInFeed]?
    var viewed: [RantInFeed]?
    
    enum CodingKeys: String, CodingKey {
        case rants,
             upvoted,
             comments,
             favorites,
             viewed
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rants = try values.decode([RantInFeed].self, forKey: .rants)
        upvoted = try values.decode([RantInFeed].self, forKey: .upvoted)
        comments = try values.decode([CommentModel].self, forKey: .comments)
        
        do {
            favorites = try values.decode([RantInFeed].self, forKey: .favorites)
        } catch {
            favorites = nil
        }
        
        do {
            viewed = try values.decode([RantInFeed].self, forKey: .viewed)
        } catch {
            viewed = nil
        }
    }
}

struct UserCounts: Codable {
    let rants: Int
    let upvoted: Int
    let comments: Int
    let favorites: Int
    let collabs: Int
    
    enum CodingKeys: String, CodingKey {
        case rants,
             upvoted,
             comments,
             favorites,
             collabs
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rants = try values.decode(Int.self, forKey: .rants)
        upvoted = try values.decode(Int.self, forKey: .upvoted)
        comments = try values.decode(Int.self, forKey: .comments)
        favorites = try values.decode(Int.self, forKey: .favorites)
        collabs = try values.decode(Int.self, forKey: .collabs)
    }
}

enum ProfileContentTypes: String {
    case all = "all"
    case rants = "rants"
    case upvoted = "upvoted"
    case comments = "comments"
    case favorite = "favorites"
    case viewed = "viewed"
}

struct ProfileResponse: Codable {
    let success: Bool
    let profile: Profile
    
    enum CodingKeys: String, CodingKey {
        case success,
             profile
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        success = try values.decode(Bool.self, forKey: .success)
        profile = try values.decode(Profile.self, forKey: .profile)
    }
}
*/
