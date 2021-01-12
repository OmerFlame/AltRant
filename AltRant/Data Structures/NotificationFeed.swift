//
//  NotificationFeed.swift
//  AltRant
//
//  Created by Omer Shamai on 1/4/21.
//

import Foundation

struct NotificationFeed: Codable {
    let data: Notifications?
    let success: Bool
    
    private enum CodingKeys: String, CodingKey {
        case data, success
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            data = try values.decode(Notifications.self, forKey: .data)
        } catch {
            data = nil
        }
        
        success = try values.decode(Bool.self, forKey: .success)
    }
}

struct Notifications: Codable {
    let checkTime: Int
    let items: [Notification]
    let unread: NotificationsUnread
    let usernameMap: UsernameMapArray?
    
    private enum CodingKeys: String, CodingKey {
        case checkTime = "check_time",
             items,
             unread,
             usernameMap = "username_map"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        checkTime = try values.decode(Int.self, forKey: .checkTime)
        
        do {
            items = try values.decode([Notification].self, forKey: .items)
        } catch {
            items = []
        }
        
        unread = try values.decode(NotificationsUnread.self, forKey: .unread)
        
        usernameMap = try? values.decode(UsernameMapArray.self, forKey: .usernameMap)
    }
}

struct UsernameMapArray: Codable {
    var array: [UsernameMap]
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        var tempArray = [UsernameMap]()
        
        for key in container.allKeys {
            let decodedObject = try container.decodeIfPresent(UsernameMap.self, forKey: DynamicCodingKeys(stringValue: key.stringValue)!)!
            tempArray.append(decodedObject)
        }
        
        array = tempArray
    }
}

struct UsernameMap: Codable {
    let avatar: UserAvatar
    let name: String
    
    let uidForUsername: String
    
    private enum CodingKeys: CodingKey {
        case avatar,
             name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        avatar = try container.decode(UserAvatar.self, forKey: .avatar)
        name = try container.decode(String.self, forKey: .name)
        
        uidForUsername = container.codingPath[container.codingPath.endIndex - 1].stringValue
    }
}

struct NotificationsUnread: Codable {
    let all: Int
    let comments: Int
    let mentions: Int
    let subs: Int
    let total: Int
    let upvotes: Int
}

struct Notification: Codable, Equatable {
    let commentID: Int?
    let createdTime: Int
    let rantID: Int
    var read: Int
    let type: NotificationType
    let uid: Int
    
    private enum CodingKeys: String, CodingKey {
        case commentID = "comment_id",
             createdTime = "created_time",
             rantID = "rant_id",
             read,
             type,
             uid
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        commentID = try values.decodeIfPresent(Int.self, forKey: .commentID)
        createdTime = try values.decode(Int.self, forKey: .createdTime)
        rantID = try values.decode(Int.self, forKey: .rantID)
        read = try values.decode(Int.self, forKey: .read)
        type = try values.decode(NotificationType.self, forKey: .type)
        uid = try values.decode(Int.self, forKey: .uid)
    }
    
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return
            lhs.commentID == rhs.commentID &&
            lhs.createdTime == rhs.createdTime &&
            lhs.rantID == rhs.rantID &&
            lhs.read == rhs.read &&
            lhs.type == rhs.type &&
            lhs.uid == rhs.uid
    }
}

enum NotificationType: String, Codable {
    case rantUpvote = "content_vote"
    case commentUpvote = "comment_vote"
    
    case commentContent = "comment_content"
    case commentDiscuss = "comment_discuss"
    case commentMention = "comment_mention"
    
    case rantSub = "rant_sub"
}
