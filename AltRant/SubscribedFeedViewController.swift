//
//  SubscribedFeedViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 23/02/2022.
//

import UIKit
import SwiftRant

protocol SubscribedFeedViewControllerDelegate: AnyObject {
    func setVoteStateForRant(withID id: Int, voteState: Int)
    func setScoreForRant(withID id: Int, score: Int)
    
    func reloadData()
}

class SubscribedFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FeedDelegate, SubscribedFeedViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var subscribedFeed = [SubscribedFeed]()
    var didFinishLoading = false
    var supplementalImages = [Int:File]()
    var actionUserImages = [Int:UIImage]()
    
    var isLoadingMoreData = true
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFinishLoading {
            refreshButton.isEnabled = false
            var combinedRantInFeedCount = 0
            
            for feed in subscribedFeed {
                combinedRantInFeedCount += feed.rants.count
            }
            
            // We need to take the very first recommended users list cell into account as well (this isn't a rant in the response), so we are adding 1 if the amount of rants in all feeds is bigger than 0
            
            if combinedRantInFeedCount > 0 {
                combinedRantInFeedCount += 1
            }
            
            SwiftRant.shared.getSubscribedFeed(nil, lastEndCursor: nil) { error, feed in
                if feed != nil {
                    let (start, end) = (combinedRantInFeedCount, feed!.rants.count + combinedRantInFeedCount)
                    var indexPaths = (0..<(combinedRantInFeedCount > 0 ? feed!.rants.count : feed!.rants.count + 1)).map { return IndexPath(row: $0, section: 0) }
                    
                    //self.subscribedFeed.append(feed!)
                    
                    for (idx, rant) in feed!.rants.enumerated() {
                        if rant.attachedImage != nil {
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent).relativePath) {
                                self.supplementalImages[rant.id] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent), size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            } else {
                                self.supplementalImages[rant.id] = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            }
                        }
                        
                        for user in rant.relatedUserActions {
                            if feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage != nil {
                                let semaphore = DispatchSemaphore(value: 0)
                                
                                let url = URL(string: "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)")!
                                
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    if let data = data {
                                        //FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.lastPathComponent/*feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent*/).relativePath, contents: data, attributes: nil)
                                        self.actionUserImages[user.userID] = UIImage(data: data)
                                    }
                                    
                                    semaphore.signal()
                                }.resume()
                                
                                semaphore.wait()
                                
                                /*if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath) {
                                    //self.actionUserImages[user.userID] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent), size: CGSize(width: 150, height: 150))
                                    self.actionUserImages[user.userID] = UIImage(contentsOfFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath)
                                } else {
                                    /*let fakeAttachedImageJSON = """
{
    "url": "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)",
    "width": 150,
    "height": 150
}
"""*/
                                    //let fakeAttachedImage = try! JSONDecoder().decode(Rant.AttachedImage.self, from: fakeAttachedImageJSON.data(using: .utf8)!)
                                    
                                    let semaphore = DispatchSemaphore(value: 0)
                                    
                                    let url = URL(string: "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)")!
                                    
                                    URLSession.shared.dataTask(with: url) { data, _, _ in
                                        if let data = data {
                                            FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.lastPathComponent/*feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent*/).relativePath, contents: data, attributes: nil)
                                            self.actionUserImages[user.userID] = UIImage(data: data)
                                        }
                                        
                                        semaphore.signal()
                                    }.resume()
                                    
                                    semaphore.wait()
                                    //self.actionUserImages[user.userID] = File.loadFile(image: fakeAttachedImage, size: CGSize(width: 150, height: 150))*
                                }*/
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.didFinishLoading = true
                        self.isLoadingMoreData = false
                        self.refreshButton.isEnabled = true
                        
                        //indexPaths.append(IndexPath(item: end, section: 0))
                        self.subscribedFeed.append(feed!)
                        
                        CATransaction.begin()
                        CATransaction.setCompletionBlock({
                            self.tableView.reloadData()
                        })
                        self.tableView.beginUpdates()
                        let indexSet = IndexSet(integer: 0)
                        self.tableView.insertSections(indexSet, with: .automatic)
                        
                        //self.tableView.insertRows(at: indexPaths, with: .automatic)
                        self.tableView.endUpdates()
                        
                        CATransaction.commit()
                        //self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let recommendedUsersNib = UINib(nibName: "RecommendedUsersCell", bundle: nil)
        let loadingCellNib = UINib(nibName: "LoadingCell", bundle: nil)
        
        tableView.register(recommendedUsersNib, forCellReuseIdentifier: "RecommendedUsersCell")
        tableView.register(loadingCellNib, forCellReuseIdentifier: "LoadingCell")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // The amount of sections is the amount of feeds we retrieved from the server, plus 1 for the loading ring at the bottom of the scroll view.
        return subscribedFeed.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < subscribedFeed.count {
            return subscribedFeed[section].rants.count
        } else if section == subscribedFeed.count {
            guard !subscribedFeed.isEmpty else {
                return 1
            }
            
            
            if subscribedFeed[section - 1].pageInfo.hasNextPage {
                return 1
            } else {
                return 0
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /*if indexPath.section == 0 {
            if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedUsersCell") as! RecommendedUserCell
                
                cell.configure(subscribedFeed: &subscribedFeed[0], parentTableView: tableView)
                
                cell.internalRecommendedUserCollectionView.reloadData()
                
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
                
                let firstActionUserImage = actionUserImages[subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[0].userID]
                
                var secondActionUserImage: UIImage? = nil
                
                //let hasTwoActions = subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions.count == 2 ? 1 : 0
                
                //let secondActionUserID = subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[hasTwoActions].userID
                
                /*if rantContents!.relatedUserActions.count > 1 {
                    for (idx, userAction) in rantContents!.relatedUserActions[1..<rantContents!.relatedUserActions.count].enumerated() {
                        
                        if userAction.userID != leadingActionUserID {
                            trailingUserActionImageLeadingConstraint.constant = -6.5
                            trailingUserActionImageView.image = self.trailingUserActionImage
                        } else {
                            if idx == rantContents!.relatedUserActions.count - 1 {
                                trailingUserActionImageLeadingConstraint.constant = -26
                                trailingUserActionImageView.image = nil
                            }
                        }
                    }
                }*/
                
                // Set the leading image to the avatar of the first user in the list of actions.
                // If there are multiple actions on a rant, choose the image of a user in the list of actions that is not in the leading image.
                
                if subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions.count > 1 {
                    for (idx, userAction) in subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[1..<subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions.count].enumerated() {
                        if userAction.userID != firstActionUserID {
                            secondActionUserImage = actionUserImages[subscribedFeed[feedOffset].rants[rantOffset].relatedUserActions[idx + 1].userID]
                        }
                    }
                }
                
                cell.configure(feedOffset: feedOffset, rantOffset: rantOffset, image: supplementalImages[subscribedFeed[feedOffset].rants[rantOffset].id], leadingUserActionImage: firstActionUserImage, trailingUserActionImage: secondActionUserImage, parentTableViewController: self, parentTableView: tableView)
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell") as! LoadingCell
            cell.activityIndicator.startAnimating()
            
            return cell
        }*/
        
        if indexPath.section == 0 && indexPath.row == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedUsersCell") as! RecommendedUserCell
            
            cell.configure(subscribedFeed: &subscribedFeed[0], parentTableView: tableView)
            
            cell.internalRecommendedUserCollectionView.reloadData()
            
            return cell
        } else {
            if indexPath.section == numberOfSections(in: tableView) - 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell") as! LoadingCell
                cell.activityIndicator.startAnimating()
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RantInSubscribedFeedCell") as! RantInSubscribedFeedCell
                
                let idxPath = IndexPath(row: indexPath.row > 3 && indexPath.section == 0 ? indexPath.row - 1 : indexPath.row, section: indexPath.section)
                
                let firstActionUserID = subscribedFeed[idxPath.section].rants[idxPath.row].relatedUserActions[0].userID
                
                let firstActionUserImage = actionUserImages[subscribedFeed[idxPath.section].rants[idxPath.row].relatedUserActions[0].userID]
                
                var secondActionUserImage: UIImage? = nil
                
                // Set the leading image to the avatar of the first user in the list of actions.
                // If there are multiple actions on a rant, choose the image of a user in the list of actions that is not in the leading image.
                
                if subscribedFeed[idxPath.section].rants[idxPath.row].relatedUserActions.count > 1 {
                    for (idx, userAction) in subscribedFeed[idxPath.section].rants[idxPath.row].relatedUserActions[1..<subscribedFeed[idxPath.section].rants[idxPath.row].relatedUserActions.count].enumerated() {
                        if userAction.userID != firstActionUserID {
                            secondActionUserImage = actionUserImages[subscribedFeed[idxPath.section].rants[idxPath.row].relatedUserActions[idx + 1].userID]
                        }
                    }
                }
                
                cell.configure(feedOffset: idxPath.section, rantOffset: idxPath.row, image: supplementalImages[subscribedFeed[idxPath.section].rants[idxPath.row].id], leadingUserActionImage: firstActionUserImage, trailingUserActionImage: secondActionUserImage, parentTableViewController: self, parentTableView: tableView)
                
                cell.delegate = self
                
                return cell
            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        didFinishLoading = false
        isLoadingMoreData = true
        
        refreshButton.isEnabled = false
        
        UserDefaults.standard.set(nil, forKey: "DRLastEndCursor")
        
        (tableView(tableView, cellForRowAt: IndexPath(row: 3, section: 0)) as! RecommendedUserCell).closedUsers.removeAll()
        (tableView(tableView, cellForRowAt: IndexPath(row: 3, section: 0)) as! RecommendedUserCell).subscribedUsers.removeAll()
        (tableView(tableView, cellForRowAt: IndexPath(row: 3, section: 0)) as! RecommendedUserCell).subscribedFeed = nil
        (tableView(tableView, cellForRowAt: IndexPath(row: 3, section: 0)) as! RecommendedUserCell).dataSource = nil
        (tableView(tableView, cellForRowAt: IndexPath(row: 3, section: 0)) as! RecommendedUserCell).moreUsersButtonPressCounter = 1
        (tableView(tableView, cellForRowAt: IndexPath(row: 3, section: 0)) as! RecommendedUserCell).lastDataSourceItemIndexInSubscribedFeed = 2
        
        subscribedFeed.removeAll()
        
        tableView.reloadData()
        
        /*tableView.beginUpdates()
        tableView.deleteSections(IndexSet(integer: numberOfSections(in: tableView) - 2), with: .fade)
        tableView.endUpdates()*/
        
        supplementalImages.removeAll()
        actionUserImages.removeAll()
        
        var combinedRantInFeedCount = 0
        
        for feed in subscribedFeed {
            combinedRantInFeedCount += feed.rants.count
        }
        
        // We need to take the very first recommended users list cell into account as well (this isn't a rant in the response), so we are adding 1 if the amount of rants in all feeds is bigger than 0
        
        if combinedRantInFeedCount > 0 {
            combinedRantInFeedCount += 1
        }
        
        SwiftRant.shared.getSubscribedFeed(nil, lastEndCursor: nil) { error, feed in
            if feed != nil {
                let (start, end) = (combinedRantInFeedCount, feed!.rants.count + combinedRantInFeedCount)
                var indexPaths = (0..<(combinedRantInFeedCount > 0 ? feed!.rants.count : feed!.rants.count + 1)).map { return IndexPath(row: $0, section: 0) }
                
                //self.subscribedFeed.append(feed!)
                
                for (idx, rant) in feed!.rants.enumerated() {
                    if rant.attachedImage != nil {
                        if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent).relativePath) {
                            self.supplementalImages[rant.id] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent), size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                        } else {
                            self.supplementalImages[rant.id] = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                        }
                    }
                    
                    for user in rant.relatedUserActions {
                        if feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage != nil {
                            let semaphore = DispatchSemaphore(value: 0)
                            
                            let url = URL(string: "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)")!
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                if let data = data {
                                    //FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.lastPathComponent/*feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent*/).relativePath, contents: data, attributes: nil)
                                    self.actionUserImages[user.userID] = UIImage(data: data)
                                }
                                
                                semaphore.signal()
                            }.resume()
                            
                            semaphore.wait()
                            
                            /*if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath) {
                                //self.actionUserImages[user.userID] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent), size: CGSize(width: 150, height: 150))
                                self.actionUserImages[user.userID] = UIImage(contentsOfFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath)
                            } else {
                                /*let fakeAttachedImageJSON = """
{
"url": "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)",
"width": 150,
"height": 150
}
"""*/
                                //let fakeAttachedImage = try! JSONDecoder().decode(Rant.AttachedImage.self, from: fakeAttachedImageJSON.data(using: .utf8)!)
                                
                                let semaphore = DispatchSemaphore(value: 0)
                                
                                let url = URL(string: "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)")!
                                
                                URLSession.shared.dataTask(with: url) { data, _, _ in
                                    if let data = data {
                                        FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.lastPathComponent/*feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent*/).relativePath, contents: data, attributes: nil)
                                        self.actionUserImages[user.userID] = UIImage(data: data)
                                    }
                                    
                                    semaphore.signal()
                                }.resume()
                                
                                semaphore.wait()
                                //self.actionUserImages[user.userID] = File.loadFile(image: fakeAttachedImage, size: CGSize(width: 150, height: 150))*
                            }*/
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.isLoadingMoreData = false
                    self.refreshButton.isEnabled = true
                    
                    //indexPaths.append(IndexPath(item: end, section: 0))
                    self.subscribedFeed.append(feed!)
                    
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        self.tableView.reloadData()
                    })
                    self.tableView.beginUpdates()
                    let indexSet = IndexSet(integer: 0)
                    self.tableView.insertSections(indexSet, with: .automatic)
                    
                    //self.tableView.insertRows(at: indexPaths, with: .automatic)
                    self.tableView.endUpdates()
                    
                    CATransaction.commit()
                    
                    self.tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
                    //self.tableView.reloadData()
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if tableView.indexPathsForVisibleRows!.contains(IndexPath(row: 0, section: numberOfSections(in: tableView) - 1)) && !isLoadingMoreData && SwiftRant.shared.tokenFromKeychain != nil && subscribedFeed.last?.pageInfo.hasNextPage ?? true {
            isLoadingMoreData = true
            
            //var combinedRantInFeedCount =
            
            /*for feed in subscribedFeed {
                combinedRantInFeedCount += feed.rants.count
            }
            
            // We need to take the very first recommended users list cell into account as well (this isn't a rant in the response), so we are adding 1 if the amount of rants in all feeds is bigger than 0
            
            if combinedRantInFeedCount > 0 {
                combinedRantInFeedCount += 1
            }*/
            
            SwiftRant.shared.getSubscribedFeed(nil, lastEndCursor: nil) { error, feed in
                if feed != nil {
                    //let (start, end) = (combinedRantInFeedCount, feed!.rants.count + combinedRantInFeedCount)
                    let indexPaths = (0..<feed!.rants.count).map { return IndexPath(row: $0, section: self.numberOfSections(in: self.tableView) - 1) }
                    
                    self.subscribedFeed.append(feed!)
                    
                    for (idx, rant) in feed!.rants.enumerated() {
                        if rant.attachedImage != nil {
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent).relativePath) {
                                self.supplementalImages[rant.id] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent), size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            } else {
                                self.supplementalImages[rant.id] = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            }
                        }
                        
                        for user in rant.relatedUserActions {
                            if feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage != nil {
                                if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath) {
                                    DispatchQueue.main.async {
                                        self.actionUserImages[user.userID] = UIImage(contentsOfFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)!.lastPathComponent).relativePath)
                                    }
                                } else {
                                    let semaphore = DispatchSemaphore(value: 0)
                                    
                                    let url = URL(string: "https://avatars.devrant.com/\(feed!.usernameMap.users.first(where: { $0.userID == user.userID })!.avatar.avatarImage!)")!
                                    
                                    URLSession.shared.dataTask(with: url) { data, _, _ in
                                        if let data = data {
                                            FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(url.lastPathComponent).relativePath, contents: data, attributes: nil)
                                            self.actionUserImages[user.userID] = UIImage(data: data)
                                        }
                                        
                                        semaphore.signal()
                                    }.resume()
                                    
                                    semaphore.wait()
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.isLoadingMoreData = false
                        
                        self.tableView.beginUpdates()
                        let indexSet = IndexSet(integer: self.numberOfSections(in: self.tableView) - 2)
                        
                        self.tableView.insertSections(indexSet, with: .automatic)
                        self.tableView.insertRows(at: indexPaths, with: .automatic)
                        self.tableView.endUpdates()
                        
                        //self.tableView.beginUpdates()
                        //self.tableView.insertSections(indexSet, with: .automatic)
                        /*self.tableView.performBatchUpdates ({
                            self.tableView.insertSections(indexSet, with: .automatic)
                        }) { _ in
                            //self.tableView.endUpdates()
                        }*/
                        //self.tableView.insertRows(at: indexPaths, with: .automatic)
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RantInFeedCell", let rantViewController = segue.destination as? RantViewController {
            //rantViewController.rantID = rantFeed.rantFeed[tableView.indexPath(for: sender as! UITableViewCell)!.row].id
            
            rantViewController.rantID = (sender as! RantInSubscribedFeedCell).rantContents!.id
            tableView.deselectRow(at: tableView.indexPath(for: sender as! UITableViewCell)!, animated: true)
            
            /*withUnsafeMutablePointer(to: &(sender as! RantInFeedCell).rant, { pointer in
                rantViewController.rantInFeed = pointer
            })*/
            
            //rantViewController.rantInFeed = (sender as! RantInSubscribedFeedCell).rantContents
            
            rantViewController.supplementalRantImage = supplementalImages[(sender as! RantInSubscribedFeedCell).rantContents!.id]
            rantViewController.subscribedFeedDelegate = self
            rantViewController.loadCompletionHandler = nil
        }
    }
    
    private func indexOfRant(withID id: Int) -> IndexPath? {
        for (feedIdx, feed) in subscribedFeed.enumerated() {
            if let rantIdx = feed.rants.firstIndex(where: { $0.id == id }) {
                return IndexPath(row: rantIdx, section: feedIdx)
            }
        }
        
        return nil
    }
    
    // MARK: - Feed Delegate
    func didVoteOnRant(withID id: Int, vote: Int, cell: RantInSubscribedFeedCell) {
        guard (-1...1).contains(vote) else {
            return
        }
        
        let rantIndex = indexOfRant(withID: id)
        
        guard rantIndex != nil else {
            let alertController = UIAlertController(title: "Error", message: "Unable to find index of rant in feed. Please send a bug report because this isn't supposed to happen!", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            present(alertController, animated: true)
            
            return
        }
        
        SwiftRant.shared.voteOnRant(nil, rantID: id, vote: vote) { [weak self] error, updatedRant in
            if updatedRant != nil {
                //self?.rantContents!.voteState = updatedRant!.voteState
                //self?.rantContents!.score = updatedRant!.score
                
                self?.subscribedFeed[rantIndex!.section].rants[rantIndex!.row].voteState = updatedRant!.voteState
                self?.subscribedFeed[rantIndex!.section].rants[rantIndex!.row].score = updatedRant!.score
                
                /*if let parentTableView = self?.parentTableView {
                    DispatchQueue.main.async {
                        parentTableView.reloadData()
                    }
                }*/
                
                DispatchQueue.main.async {
                    if let isCellVisible = self?.tableView.visibleCells.contains(cell) {
                        if isCellVisible {
                            self?.tableView.reloadData()
                        }
                    }
                }
            } else {
                let alertController = UIAlertController(title: "Error", message: error ?? "An unknown error has occurred.", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    //self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
                    self?.present(alertController, animated: true)
                }
            }
        }
    }
    
    // MARK: - Subscribed Feed View Controller Delegate
    func setVoteStateForRant(withID id: Int, voteState: Int) {
        guard (-1...1).contains(voteState) else {
            return
        }
        
        if let rantIndex = indexOfRant(withID: id) {
            subscribedFeed[rantIndex.section].rants[rantIndex.row].voteState = voteState
        }
    }
    
    func setScoreForRant(withID id: Int, score: Int) {
        if let rantIndex = indexOfRant(withID: id) {
            subscribedFeed[rantIndex.section].rants[rantIndex.row].score = score
        }
    }
    
    func reloadData() {
        tableView.reloadData()
    }
}
