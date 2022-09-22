//
//  FeedDelegate.swift
//  AltRant
//
//  Created by Omer Shamai on 04/04/2022.
//

import Foundation
import SwiftRant

protocol FeedDelegate: AnyObject {
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantInSubscribedFeedCell)
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: SecondaryRantInFeedCell)
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantCell)
    
    func didFavoriteRant(withID id: Int, cell: RantCell)
    func didUnfavoriteRant(withID id: Int, cell: RantCell)
    
    func didDeleteRant(withID id: Int)
    
    func didVoteOnComment(withID id: Int, vote: VoteState, cell: CommentCell)
    
    func didReportComment(withID id: Int, cell: CommentCell)
    
    func didDeleteComment(withID id: Int, cell: CommentCell)
}

extension FeedDelegate {
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantInSubscribedFeedCell) {}
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: SecondaryRantInFeedCell) {}
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantCell) {}
    
    func didFavoriteRant(withID id: Int, cell: RantCell) {}
    func didUnfavoriteRant(withID id: Int, cell: RantCell) {}
    
    func didDeleteRant(withID id: Int) {}
    
    func didVoteOnComment(withID id: Int, vote: VoteState, cell: CommentCell) {}
    
    func didReportComment(withID id: Int, cell: CommentCell) {}
    
    func didDeleteComment(withID id: Int, cell: CommentCell) {}
}
