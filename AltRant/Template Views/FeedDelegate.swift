//
//  FeedDelegate.swift
//  AltRant
//
//  Created by Omer Shamai on 04/04/2022.
//

import Foundation

protocol FeedDelegate: AnyObject {
    func didVoteOnRant(withID id: Int, vote: Int, cell: RantInSubscribedFeedCell)
    func didVoteOnRant(withID id: Int, vote: Int, cell: SecondaryRantInFeedCell)
    func didVoteOnRant(withID id: Int, vote: Int, cell: RantCell)
    
    func didFavoriteRant(withID id: Int, cell: RantCell)
    func didUnfavoriteRant(withID id: Int, cell: RantCell)
    
    func didDeleteRant(withID id: Int)
    
    func didVoteOnComment(withID id: Int, vote: Int, cell: CommentCell)
    
    func didReportComment(withID id: Int, cell: CommentCell)
    
    func didDeleteComment(withID id: Int, cell: CommentCell)
}

extension FeedDelegate {
    func didVoteOnRant(withID id: Int, vote: Int, cell: RantInSubscribedFeedCell) {}
    func didVoteOnRant(withID id: Int, vote: Int, cell: SecondaryRantInFeedCell) {}
    func didVoteOnRant(withID id: Int, vote: Int, cell: RantCell) {}
    
    func didFavoriteRant(withID id: Int, cell: RantCell) {}
    func didUnfavoriteRant(withID id: Int, cell: RantCell) {}
    
    func didDeleteRant(withID id: Int) {}
    
    func didVoteOnComment(withID id: Int, vote: Int, cell: CommentCell) {}
    
    func didReportComment(withID id: Int, cell: CommentCell) {}
    
    func didDeleteComment(withID id: Int, cell: CommentCell) {}
}
