//
//  SubscribedFeedViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 23/02/2022.
//

import UIKit
import SwiftRant

class SubscribedFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var subscribedFeed = [SubscribedFeed]()
    var didFinishLoading = false
    var supplementalImages = [IndexPath:File]()
    var actionUserImages = [Int:File]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFinishLoading {
            var combinedRantInFeedCount = 0
            
            for feed in subscribedFeed {
                combinedRantInFeedCount += feed.rants.count
            }
            
            SwiftRant.shared.getSubscribedFeed(nil, lastEndCursor: nil) { error, feed in
                if feed != nil {
                    let (start, end) = (combinedRantInFeedCount, feed!.rants.count + combinedRantInFeedCount)
                    let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                    
                    self.subscribedFeed.append(feed!)
                    
                    for (idx, rant) in feed!.rants.enumerated() {
                        if rant.attachedImage != nil {
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent).relativePath) {
                                self.supplementalImages[indexPaths[idx]] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent), size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            } else {
                                self.supplementalImages[indexPaths[idx]] = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            }
                        }
                        
                        for user in rant.relatedUserActions {
                            if feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage != nil {
                                if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath) {
                                    self.actionUserImages[user.userID] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent), size: CGSize(width: 150, height: 150))
                                } else {
                                    let fakeAttachedImageJSON = """
{
    "url": "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)",
    "width": 150,
    "height": 150
}
"""
                                    let fakeAttachedImage = try! JSONDecoder().decode(Rant.AttachedImage.self, from: fakeAttachedImageJSON.data(using: .utf8)!)
                                    self.actionUserImages[user.userID] = File.loadFile(image: fakeAttachedImage, size: CGSize(width: 150, height: 150))
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.didFinishLoading = true
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        for feed in subscribedFeed {
            count += feed.rants.count
        }
        
        return count != 0 ? count + 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedUserCell") as! RecommendedUserCell
            
            cell.configure(subscribedFeed: &subscribedFeed[0])
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantInSubscribedFeedCell") as! RantInSubscribedFeedCell
            
            var counter = 0
            var feedOffset = 0
            var rantOffset = 0
            
            let idxPath = IndexPath(row: indexPath.row > 3 ? indexPath.row - 1 : indexPath.row, section: 0)
            
            for (idx, feed) in subscribedFeed.enumerated() {
                if counter + (feed.rants.count - 1) < idxPath.row {
                    counter += (feed.rants.count - 1)
                    feedOffset = idx
                    continue
                } else {
                    rantOffset = idxPath.row - counter
                }
            }
            
            let firstActionUserID = subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[0].userID
            
            let firstActionUserImage = UIImage(contentsOfFile: actionUserImages[subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[0].userID]!.previewItemURL.relativePath)
            
            let hasTwoActions = subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions.count == 2 ? 1 : 0
            
            let secondActionUserID = subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[hasTwoActions].userID
            
            
            cell.configure(feedOffset: feedOffset, rantOffset: rantOffset, image: supplementalImages[idxPath], leadingUserActionImage: firstActionUserImage, trailingUserActionImage: firstActionUserID != secondActionUserID ? UIImage(contentsOfFile: actionUserImages[subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[1].userID]!.previewItemURL.relativePath) : nil, parentTableViewController: self, parentTableView: tableView)
            
            return cell
        }
    }
}
