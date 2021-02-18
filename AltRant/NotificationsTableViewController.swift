//
//  NotificationsTableViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 1/4/21.
//

import UIKit
import ADNavigationBarExtension

class NotificationsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var barExtension: UIView!
    
    var currentNotificationType: NotificationContentCategory = .all
    
    var notifications = [Notification]()
    var unreadNotificationCounters: NotificationsUnread?
    var usernameMap: UsernameMapArray?
    var userImages = [Int:UIImage]()
    var didSuccessfullyFetchNotifications = false
    
    
    var didFinishLoading = false
    
    var originalNavbarMaxY: CGFloat!
    
    var notifRefreshTimer: Timer!
    
    // MARK: - View Controller Lifecycle Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let containerView = UIToolbar()
        
        segmentedControl = UISegmentedControl(frame: CGRect(x: 20, y: 0, width: 0, height: 43))
        segmentedControl.apportionsSegmentWidthsByContent = true
        
        segmentedControl.insertSegment(withTitle: "All", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "++'s", at: 1, animated: false)
        segmentedControl.insertSegment(withTitle: "Mentions", at: 2, animated: false)
        segmentedControl.insertSegment(withTitle: "Comments", at: 3, animated: false)
        segmentedControl.insertSegment(withTitle: "Subscriptions", at: 4, animated: false)
        
        containerView.addSubview(segmentedControl)
        (navigationController as! ExtensibleNavigationBarNavigationController).setNavigationBarExtensionView(containerView, forHeight: 43)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        segmentedControl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20).isActive = true
        segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        segmentedControl.heightAnchor.constraint(equalTo: containerView.heightAnchor, constant: -10).isActive = true
        
        segmentedControl.selectedSegmentIndex = 0
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.shadowColor = .clear
        
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.clipsToBounds = true
        
        segmentedControl.addTarget(self, action: #selector(handleChange(_:)), for: .valueChanged)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        
        originalNavbarMaxY = navigationController!.navigationBar.frame.maxY
        
        if !didFinishLoading {
            tableView.isHidden = true
        }
    }
    
    func scheduleNotificationFetches() {
        self.notifRefreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            debugPrint("Notification Refresh Timer Fired!")
            
            self.getAllData(notificationType: self.currentNotificationType, shouldGetNewData: true, completion: nil)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFinishLoading {
            loadingIndicator.startAnimating()
            
            getAllData(notificationType: currentNotificationType, shouldGetNewData: false, completion: {
                if self.didSuccessfullyFetchNotifications {
                    self.scheduleNotificationFetches()
                }
            })
        } else {
            self.scheduleNotificationFetches()
        }
    }
    
    @objc func didPullToRefresh(_ sender: UIRefreshControl) {
        unreadNotificationCounters = nil
        
        tableView.reloadData()
        
        getAllData(notificationType: currentNotificationType, shouldGetNewData: true, completion: { sender.endRefreshing() })
    }

    // MARK: - Table View Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if notifications[indexPath.row].type == .rantUpvote {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantUpvoteCell", for: indexPath) as! RantUpvoteCell
            
            let userMapping = usernameMap!.array.first(where: {
                $0.uidForUsername == String(notifications[indexPath.row].uid)
            })!
            
            cell.profileImageView.image = userImages[notifications[indexPath.row].uid]
            cell.usernameUpvoteLabel.text = "\(userMapping.name) ++'d your rant!"
            
            cell.usernameUpvoteLabel.font = notifications[indexPath.row].read == 0 ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
            
            cell.usernameUpvoteLabel.isEnabled = notifications[indexPath.row].read == 0 ? true : false
            
            cell.upvoteBadge.tintColor = UIColor(hex: userMapping.avatar.b)!
            
            return cell
        } else if notifications[indexPath.row].type == .commentContent {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantCommentCell", for: indexPath) as! RantCommentCell
            
            let userMapping = usernameMap!.array.first(where: {
                $0.uidForUsername == String(notifications[indexPath.row].uid)
            })!
            
            cell.profileImageView.image = userImages[notifications[indexPath.row].uid]
            cell.usernameCommentLabel.text = "\(userMapping.name) commented on your rant!"
            
            cell.usernameCommentLabel.font = notifications[indexPath.row].read == 0 ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
            
            cell.usernameCommentLabel.isEnabled = notifications[indexPath.row].read == 0 ? true : false
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.b)!
            
            return cell
        } else if notifications[indexPath.row].type == .commentDiscuss {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantCommentDiscussCell", for: indexPath) as! RantCommentCell
            
            let userMapping = usernameMap!.array.first(where: {
                $0.uidForUsername == String(notifications[indexPath.row].uid)
            })!
            
            cell.profileImageView.image = userImages[notifications[indexPath.row].uid]
            cell.usernameCommentLabel.text = "\(userMapping.name) commented on a rant you commented on!"
            
            cell.usernameCommentLabel.font = notifications[indexPath.row].read == 0 ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
            
            cell.usernameCommentLabel.isEnabled = notifications[indexPath.row].read == 0 ? true : false
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.b)!
            
            return cell
        } else if notifications[indexPath.row].type == .commentMention {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantCommentMentionCell", for: indexPath) as! RantCommentCell
            
            let userMapping = usernameMap!.array.first(where: {
                $0.uidForUsername == String(notifications[indexPath.row].uid)
            })!
            
            cell.profileImageView.image = userImages[notifications[indexPath.row].uid]
            
            cell.usernameCommentLabel.text = "\(userMapping.name) mentioned you in a comment!"
            
            cell.usernameCommentLabel.font = notifications[indexPath.row].read == 0 ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
            
            cell.usernameCommentLabel.isEnabled = notifications[indexPath.row].read == 0 ? true : false
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.b)!
            
            return cell
        } else if notifications[indexPath.row].type == .commentUpvote {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantCommentUpvoteCell", for: indexPath) as! RantUpvoteCell
            
            let userMapping = usernameMap!.array.first(where: {
                $0.uidForUsername == String(notifications[indexPath.row].uid)
            })!
            
            cell.profileImageView.image = userImages[notifications[indexPath.row].uid]
            cell.usernameUpvoteLabel.text = "\(userMapping.name) ++'d your comment!"
            
            cell.usernameUpvoteLabel.font = notifications[indexPath.row].read == 0 ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
            
            cell.usernameUpvoteLabel.isEnabled = notifications[indexPath.row].read == 0 ? true : false
            
            cell.upvoteBadge.tintColor = UIColor(hex: userMapping.avatar.b)!
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantSubCell", for: indexPath) as! RantCommentCell
            
            let userMapping = usernameMap!.array.first(where: {
                $0.uidForUsername == String(notifications[indexPath.row].uid)
            })!
            
            cell.profileImageView.image = userImages[notifications[indexPath.row].uid]
            cell.usernameCommentLabel.text = "\(userMapping.name) posted a new rant!"
            
            cell.usernameCommentLabel.font = notifications[indexPath.row].read == 0 ? .systemFont(ofSize: 17, weight: .semibold) : .systemFont(ofSize: 17)
            
            cell.usernameCommentLabel.isEnabled = notifications[indexPath.row].read == 0 ? true : false
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.b)!
            
            return cell
        }
    }
    
    // MARK: - Private Utilities
    fileprivate func showAlertWithError(_ error: String, retryHandler: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        if retryHandler != nil {
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in retryHandler!() }))
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func getAllData(notificationType: NotificationContentCategory, shouldGetNewData: Bool, completion: (() -> ())?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let notificationResult = APIRequest().getNotificationFeed(shouldGetNewNotifs: shouldGetNewData, category: notificationType)
            
            if let notificationsData = notificationResult.data {
                let completionSemaphore = DispatchSemaphore(value: 0)
                
                for item in (!shouldGetNewData ? notificationsData.items[0...99] : notificationsData.items[..<notificationsData.items.count]) {
                    if let avatarLink = notificationsData.usernameMap!.array.first(where: {
                        $0.uidForUsername == String(item.uid)
                    })!.avatar.i {
                        if let cachedFile = FileManager.default.contents(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(avatarLink).relativePath) {
                            self.userImages[item.uid] = UIImage(data: cachedFile)
                        } else {
                            URLSession.shared.dataTask(with: URL(string: "https://avatars.devrant.com/\(avatarLink)")!) { data, _, _ in
                                
                                self.userImages[item.uid] = UIImage(data: data!)
                                
                                FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(avatarLink).relativePath, contents: data, attributes: nil)
                                
                                completionSemaphore.signal()
                            }.resume()
                            
                            completionSemaphore.wait()
                            continue
                        }
                    } else {
                        let avatarColor = notificationsData.usernameMap!.array.first(where: {
                            $0.uidForUsername == String(item.uid)
                        })!.avatar.b
                        
                        self.userImages[item.uid] = UIImage(color: UIColor(hex: avatarColor)!, size: CGSize(width: 45, height: 45))
                        
                        continue
                    }
                }
                
                let indexPaths = !shouldGetNewData ? (0..<100).map { IndexPath(row: $0, section: 0) } : (0..<notificationsData.items.count).map { IndexPath(row: $0, section: 0) }
                self.notifications.insert(contentsOf: notificationsData.items[!shouldGetNewData ? 0..<100 : 0..<notificationsData.items.count], at: 0)
                
                self.unreadNotificationCounters = notificationsData.unread
                
                if self.usernameMap != nil {
                    if notificationsData.usernameMap != nil {
                        self.usernameMap!.array.append(contentsOf: notificationsData.usernameMap!.array)
                    }
                } else {
                    self.usernameMap = notificationsData.usernameMap!
                }
                
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.didSuccessfullyFetchNotifications = true
                    self.loadingIndicator.stopAnimating()
                    self.tableView.isHidden = false
                    
                    self.tableView.dataSource = self
                    self.tableView.delegate = self
                    
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                    self.tableView.endUpdates()
                    
                    self.navigationController!.tabBarItem.badgeValue = self.unreadNotificationCounters!.all != 0 ? String(self.unreadNotificationCounters!.all) : nil
                    
                    completion?()
                }
            } else {
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.loadingIndicator.stopAnimating()
                    
                    self.showAlertWithError("An error occurred while requesting notifications.", retryHandler: nil)
                    
                    completion?()
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
        tableView.deselectRow(at: indexPath, animated: true)
        
        if segue.identifier! == "rantUpvote", let rantViewController = segue.destination as? RantViewController {
            let notificationsToModify = notifications.filter({
                $0.read == 0 && $0.rantID == notifications[indexPath.row].rantID
            })
            
            for i in notificationsToModify {
                if let j = notifications.firstIndex(where: { $0 == i }) {
                    
                    notifications[j].read = 1
                    
                    if tableView.indexPathsForVisibleRows!.contains(IndexPath(row: j, section: 0)) {
                        tableView.reloadRows(at: [IndexPath(row: j, section: 0)], with: .none)
                    }
                }
            }
            
            if let currentTabBarBadgeNumber = Int(navigationController!.tabBarItem.badgeValue ?? "") {
                if currentTabBarBadgeNumber - notificationsToModify.count == 0 {
                    navigationController!.tabBarItem.badgeValue = nil
                } else {
                    navigationController!.tabBarItem.badgeValue = String(currentTabBarBadgeNumber - notificationsToModify.count)
                }
            }
            
            rantViewController.rantID = notifications[indexPath.row].rantID
            
            notifRefreshTimer.invalidate()
            notifRefreshTimer = nil
        } else if segue.identifier == "previewRantUpvote", let rantViewController = segue.destination as? RantViewController {
            rantViewController.rantID = notifications[indexPath.row].rantID
        } else if segue.identifier == "rantComment" || segue.identifier == "rantCommentDiscuss" || segue.identifier == "rantCommentMention" || segue.identifier == "rantCommentUpvote", let rantViewController = segue.destination as? RantViewController {
            let notificationsToModify = notifications.filter({
                $0.read == 0 && $0.rantID == notifications[indexPath.row].rantID
            })
            
            for i in notificationsToModify {
                if let j = notifications.firstIndex(where: { $0 == i }) {
                    notifications[j].read = 1
                    
                    if tableView.indexPathsForVisibleRows!.contains(IndexPath(row: j, section: 0)) {
                        tableView.reloadRows(at: [IndexPath(row: j, section: 0)], with: .none)
                    }
                }
            }
            
            if let currentTabBarBadgeNumber = Int(navigationController!.tabBarItem.badgeValue ?? "") {
                if currentTabBarBadgeNumber - notificationsToModify.count == 0 {
                    navigationController!.tabBarItem.badgeValue = nil
                } else {
                    navigationController!.tabBarItem.badgeValue = String(currentTabBarBadgeNumber - notificationsToModify.count)
                }
            }
            
            rantViewController.rantID = notifications[indexPath.row].rantID
            rantViewController.loadCompletionHandler = { tableViewController in
                DispatchQueue.global(qos: .userInitiated).async {
                    if let idx = tableViewController!.comments.firstIndex(where: {
                        $0.created_time == self.notifications[indexPath.row].createdTime && $0.user_username == self.usernameMap!.array.first(where: {
                            $0.uidForUsername == String(self.notifications[indexPath.row].uid)
                        })!.name || $0.id == self.notifications[indexPath.row].commentID
                    }) {
                        DispatchQueue.main.async {
                            tableViewController!.tableView.scrollToRow(at: IndexPath(row: idx, section: 1), at: .middle, animated: true)
                        }
                    }
                }
            }
            
            notifRefreshTimer.invalidate()
            notifRefreshTimer = nil
        } else if segue.identifier == "previewRantComment" || segue.identifier == "previewRantCommentDiscuss" || segue.identifier == "previewRantCommentMention" || segue.identifier == "previewRantCommentUpvote", let rantViewController = segue.destination as? RantViewController {
            rantViewController.rantID = notifications[indexPath.row].rantID
            rantViewController.loadCompletionHandler = { tableViewController in
                DispatchQueue.global(qos: .userInitiated).async {
                    if let idx = tableViewController!.comments.firstIndex(where: {
                        $0.created_time == self.notifications[indexPath.row].createdTime && $0.user_username == self.usernameMap!.array.first(where: {
                            $0.uidForUsername == String(self.notifications[indexPath.row].uid)
                        })!.name || $0.id == self.notifications[indexPath.row].commentID
                    }) {
                        DispatchQueue.main.async {
                            tableViewController!.tableView.scrollToRow(at: IndexPath(row: idx, section: 1), at: .middle, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleChange(_ sender: UISegmentedControl) {
        notifRefreshTimer.invalidate()
        notifRefreshTimer = nil
        
        if sender.selectedSegmentIndex == 0 {
            currentNotificationType = .all
        } else if sender.selectedSegmentIndex == 1 {
            currentNotificationType = .upvotes
        } else if sender.selectedSegmentIndex == 2 {
            currentNotificationType = .mentions
        } else if sender.selectedSegmentIndex == 3 {
            currentNotificationType = .comments
        } else if sender.selectedSegmentIndex == 4 {
            currentNotificationType = .subs
        }
        
        let indexPaths = (0..<tableView(tableView, numberOfRowsInSection: 0)).map { IndexPath(row: $0, section: 0) }
        
        notifications = []
        usernameMap = nil
        userImages.removeAll()
        didSuccessfullyFetchNotifications = false
        
        tableView.deleteRows(at: indexPaths, with: .automatic)
        
        getAllData(notificationType: currentNotificationType, shouldGetNewData: false, completion: { self.scheduleNotificationFetches() })
    }
}

extension NotificationsTableViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool { return true }
}
