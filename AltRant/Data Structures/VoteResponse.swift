//
//  VoteResponse.swift
//  AltRant
//
//  Created by Omer Shamai on 12/7/20.
//

import Foundation

struct VoteResponse: Codable {
    let success: Bool
    let rant: RantModel
}
