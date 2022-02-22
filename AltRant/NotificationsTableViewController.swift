//
//  NotificationsTableViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 1/4/21.
//

import UIKit
import ADNavigationBarExtension
import SwiftRant
import struct SwiftRant.Notification
//import SPAlert

class NotificationsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    var barExtension: UIView!
    
    var currentNotificationType: Notifications.Categories = .all
    
    var notifications = [Notification]()
    var notificationIndexPaths = [IndexPath]()
    var unreadNotificationCounters: Notifications.UnreadNotifications?
    var usernameMap: Notifications.UsernameMapArray?
    var userImages = [Int:UIImage]()
    var didSuccessfullyFetchNotifications = false
    
    private var didAnotherRequestStart = false
    
    var didFinishLoading = false
    
    var isLoading = false
    
    var originalNavbarMaxY: CGFloat!
    
    var notifRefreshTimer: Timer!
    
    //private var workItems = [DispatchWorkItem]()
    private var dispatchGroup = DispatchGroup()
    
    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)
    
    private var indexPathsToInsert = [IndexPath]()
    private var badgeValue: String?
    
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
            
            if self.isLoading == false {
                self.isLoading = true
                let refreshControlBackup = self.tableView.refreshControl
                self.tableView.refreshControl = nil
                //self.tableView.refreshControl!.isEnabled = false
                
                self.getAllData(notificationType: self.currentNotificationType, shouldGetNewData: true, completion: nil)
                
                self.dispatchGroup.notify(queue: .main) { [weak self] in
                    //self?.tableView.beginUpdates()
                    //self?.tableView.insertRows(at: self?.indexPathsToInsert ?? [], with: .automatic)
                    //self?.tableView.endUpdates()
                    
                    self?.tableView.reloadData()
                    
                    self?.isLoading = false
                    //self?.tableView.refreshControl!.isEnabled = true
                    self?.tableView.refreshControl = refreshControlBackup
                }
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFinishLoading {
            loadingIndicator.startAnimating()
            
            isLoading = true
            
            getAllData(notificationType: currentNotificationType, shouldGetNewData: false, completion: nil)
            
            dispatchGroup.notify(queue: .main) {
                if self.didSuccessfullyFetchNotifications {
                    
                    let bruh = self.notifications
                    
                    let indexPaths = (0..<self.notifications.count).map { IndexPath(row: $0, section: 0) }
                    
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                    //self.asynchronousRemoveAllFromArray(arr: &self.indexPathsToInsert)
                    self.tableView.endUpdates()
                    
                    self.navigationController!.tabBarItem.badgeValue = self.badgeValue
                    
                    self.isLoading = false
                    
                    self.scheduleNotificationFetches()
                }
            }
        } else {
            self.scheduleNotificationFetches()
        }
    }
    
    @objc func didPullToRefresh(_ sender: UIRefreshControl) {
        unreadNotificationCounters = nil
        
        tableView.reloadData()
        
        notifRefreshTimer.invalidate()
        
        isLoading = true
        getAllData(notificationType: currentNotificationType, shouldGetNewData: true, completion: nil)
        
        dispatchGroup.notify(queue: .main) {
            sender.endRefreshing()
            
            //self.tableView.beginUpdates()
            //self.tableView.insertRows(at: self.indexPathsToInsert, with: .automatic)
            //self.tableView.endUpdates()
            
            self.tableView.reloadData()
            
            self.isLoading = false
        }
        
        scheduleNotificationFetches()
    }

    // MARK: - Table View Data Source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count// - indexPathsToInsert.count
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { actions -> UIMenu in
            let action = UIAction(title: "Test Action", image: UIImage(systemName: "scribble")) { action in
                print("bruh")
            }
            
            return UIMenu(title: "Menu", image: nil, identifier: nil, options: [], children: [action])
        }
        
        return configuration
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
            
            cell.upvoteBadge.tintColor = UIColor(hex: userMapping.avatar.backgroundColor)!
            
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
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.backgroundColor)!
            
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
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.backgroundColor)!
            
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
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.backgroundColor)!
            
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
            
            cell.upvoteBadge.tintColor = UIColor(hex: userMapping.avatar.backgroundColor)!
            
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
            
            cell.badgeBackgroundColor = UIColor(hex: userMapping.avatar.backgroundColor)!
            
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
    
    func getAllData(notificationType: Notifications.Categories, shouldGetNewData: Bool, completion: (() -> ())?) {
        debugPrint("TASK ENTERING!")
        dispatchGroup.enter()
        
        
        
        SwiftRant.shared.getNotificationFeed(token: nil, lastCheckTime: nil, shouldGetNewNotifs: shouldGetNewData, category: notificationType) { error, result in
            if let notificationsResult = result {
                let completionSemaphore = DispatchSemaphore(value: 0)
                let downloadGroup = DispatchGroup()
                
                for item in notificationsResult.items {
                    //debugPrint("DOWNLOAD TASK ENTERING!")
                    downloadGroup.enter()
                    
                    if let avatarLink = notificationsResult.usernameMap!.array.first(where: {
                        $0.uidForUsername == String(item.uid)
                    })?.avatar.avatarImage {
                        if let cachedFile = FileManager.default.contents(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(avatarLink).relativePath) {
                            self.asynchronousWriteToDict(dict: &self.userImages, key: item.uid, value: UIImage(data: cachedFile)!)
                            
                            //debugPrint("DOWNLOAD TASK LEAVING!")
                            downloadGroup.leave()
                        } else {
                            let session = URLSession(configuration: .default)
                            
                            session.dataTask(with: URL(string: "https://avatars.devrant.com/\(avatarLink)")!) { data, _, _ in
                                self.asynchronousWriteToDict(dict: &self.userImages, key: item.uid, value: UIImage(data: data!)!)
                                
                                FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(avatarLink).relativePath, contents: data, attributes: nil)
                                
                                //debugPrint("DOWNLOAD TASK LEAVING!")
                                downloadGroup.leave()
                                
                                //completionSemaphore.signal()
                            }.resume()
                            
                            //completionSemaphore.wait()
                            continue
                        }
                    } else {
                        let avatarColor = notificationsResult.usernameMap!.array.first(where: {
                            $0.uidForUsername == String(item.uid)
                        })!.avatar.backgroundColor
                        
                        self.asynchronousWriteToDict(dict: &self.userImages, key: item.uid, value: UIImage(color: UIColor(hex: avatarColor)!, size: CGSize(width: 45, height: 45))!)
                        
                        //debugPrint("DOWNLOAD TASK LEAVING!")
                        downloadGroup.leave()
                        
                        continue
                    }
                }
                
                downloadGroup.wait()
                //debugPrint("DOWNLOAD GROUP TASK FINISHED WAITING!")
                
                //let indexPaths = !shouldGetNewData ? (0..<100).map { IndexPath(row: $0, section: 0) } : (0..<notificationsData.items.count).map { IndexPath(row: $0, section: 0) }
                
                let indexPaths = (0..<notificationsResult.items.count).map { IndexPath(row: $0, section: 0) }
                
                if !shouldGetNewData { self.accessQueue.async(flags: .barrier) { self.notifications = [] } }
                
                self.accessQueue.async(flags: .barrier) {
                    self.notifications.insert(contentsOf: notificationsResult.items[0..<notificationsResult.items.count], at: 0)
                }
                
                self.unreadNotificationCounters = notificationsResult.unread
                
                if self.usernameMap != nil {
                    if notificationsResult.usernameMap != nil {
                        self.asynchronousAppendToArray(arr: &self.usernameMap!.array, arrayToAppend: notificationsResult.usernameMap!.array)
                    }
                } else {
                    self.accessQueue.async(flags: .barrier) {
                        self.usernameMap = notificationsResult.usernameMap
                    }
                }
                
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.didSuccessfullyFetchNotifications = true
                    self.loadingIndicator.stopAnimating()
                    self.tableView.isHidden = false
                    
                    if self.tableView.dataSource == nil || self.tableView.delegate == nil {
                        self.tableView.dataSource = self
                        self.tableView.delegate = self
                    }
                    
                    self.accessQueue.async(flags: .barrier) {
                        self.indexPathsToInsert = indexPaths
                    }
                    
                    self.badgeValue = self.unreadNotificationCounters!.all != 0 ? String(self.unreadNotificationCounters!.all) : nil
                    
                    debugPrint("TASK LEAVING!")
                    self.dispatchGroup.leave()
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.showAlertWithError(error ?? "An unknown error occurred while fetching the user's notifications.", retryHandler: nil)
                }
            } else {
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.loadingIndicator.stopAnimating()
                    self.didSuccessfullyFetchNotifications = false
                    
                    debugPrint("TASK LEAVING!")
                    self.dispatchGroup.leave()
                }
            }
        }
        
        /*DispatchQueue.global(qos: .userInitiated).async {
            
            
            let notificationResult = APIRequest().getNotificationFeed(shouldGetNewNotifs: shouldGetNewData, category: notificationType)
            
            if let notificationsData = notificationResult.data {
                let completionSemaphore = DispatchSemaphore(value: 0)
                
                for item in (!shouldGetNewData ? notificationsData.items[0...99] : notificationsData.items[..<notificationsData.items.count]) {
                    if let avatarLink = notificationsData.usernameMap!.array.first(where: {
                        $0.uidForUsername == String(item.uid)
                    })!.avatar.i {
                        if let cachedFile = FileManager.default.contents(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(avatarLink).relativePath) {
                            //self.userImages[item.uid] = UIImage(data: cachedFile)
                            self.asynchronousWriteToDict(dict: &self.userImages, key: item.uid, value: UIImage(data: cachedFile)!)
                        } else {
                            URLSession.shared.dataTask(with: URL(string: "https://avatars.devrant.com/\(avatarLink)")!) { data, _, _ in
                                
                                //self.userImages[item.uid] = UIImage(data: data!)
                                self.asynchronousWriteToDict(dict: &self.userImages, key: item.uid, value: UIImage(data: data!)!)
                                
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
                        
                        //self.userImages[item.uid] = UIImage(color: UIColor(hex: avatarColor)!, size: CGSize(width: 45, height: 45))
                        
                        self.asynchronousWriteToDict(dict: &self.userImages, key: item.uid, value: UIImage(color: UIColor(hex: avatarColor)!, size: CGSize(width: 45, height: 45))!)
                        
                        continue
                    }
                }
                
                let indexPaths = !shouldGetNewData ? (0..<100).map { IndexPath(row: $0, section: 0) } : (0..<notificationsData.items.count).map { IndexPath(row: $0, section: 0) }
                
                if !shouldGetNewData {
                    //self.asynchronousRemoveAllFromArray(arr: &self.notifications)
                    //self.asynchronousAppendToArray(arr: &self.notifications, arrayToAppend: Array(notificationsData.items[!shouldGetNewData ? 0..<100 : 0..<notificationsData.items.count]))
                    self.accessQueue.async(flags: .barrier) {
                        self.notifications = []
                    }
                    
                    self.accessQueue.async(flags: .barrier) {
                        self.notifications.insert(contentsOf: notificationsData.items[!shouldGetNewData ? 0..<100 : 0..<notificationsData.items.count], at: 0)
                    }
                } else {
                    self.accessQueue.async(flags: .barrier) {
                        self.notifications.insert(contentsOf: notificationsData.items[!shouldGetNewData ? 0..<100 : 0..<notificationsData.items.count], at: 0)
                    }
                }
                
                self.unreadNotificationCounters = notificationsData.unread
                
                if self.usernameMap != nil {
                    if notificationsData.usernameMap != nil {
                        //self.usernameMap!.array.append(contentsOf: notificationsData.usernameMap!.array)
                        self.asynchronousAppendToArray(arr: &self.usernameMap!.array, arrayToAppend: notificationsData.usernameMap!.array)
                    }
                } else {
                    self.accessQueue.async(flags: .barrier) {
                        self.usernameMap = notificationsData.usernameMap
                    }
                }
                
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.didSuccessfullyFetchNotifications = true
                    self.loadingIndicator.stopAnimating()
                    self.tableView.isHidden = false
                    
                    self.tableView.dataSource = self
                    self.tableView.delegate = self
                    
                    //self.tableView.beginUpdates()
                    //self.tableView.insertRows(at: indexPaths, with: .automatic)
                    //self.tableView.endUpdates()
                    
                    //self.navigationController!.tabBarItem.badgeValue = self.unreadNotificationCounters!.all != 0 ? String(self.unreadNotificationCounters!.all) : nil
                    
                    //self.indexPathsToInsert = indexPaths
                    //self.asynchronousRemoveAllFromArray(arr: &self.indexPathsToInsert)
                    self.accessQueue.async(flags: .barrier) {
                        self.indexPathsToInsert = indexPaths
                    }
                    //self.asynchronousAppendToArray(arr: &self.indexPathsToInsert, arrayToAppend: indexPaths)
                    self.badgeValue = self.unreadNotificationCounters!.all != 0 ? String(self.unreadNotificationCounters!.all) : nil
                    
                    self.dispatchGroup.leave()
                    
                    //completion?()
                }
            } else {
                DispatchQueue.main.async {
                    self.didFinishLoading = true
                    self.loadingIndicator.stopAnimating()
                    self.didSuccessfullyFetchNotifications = false
                    
                    /*self.showAlertWithError("An error occurred while requesting notifications.", retryHandler: nil)
                    
                    completion?()*/
                }
            }
        }*/
    }
    
    private func asynchronousWriteToDict<Key, Value>(dict: inout Dictionary<Key, Value>, key: Key, value: Value) {
        /*accessQueue.async(flags: .barrier) {
            var dict = dict
            &dict.pointee[key] = value
        }*/
        
        withUnsafeMutablePointer(to: &dict) { pointer in
            accessQueue.async(flags: .barrier) {
                pointer.pointee[key] = value
            }
        }
    }
    
    private func asynchronousDeleteAllInDict<Key, Value>(dict: inout Dictionary<Key, Value>) {
        /*let dictPointer: UnsafePointer<Dictionary<Key, Value>> = UnsafePointer(dict)
        
        accessQueue.async(flags: .barrier) { [dict] in
            var dict = dict
            dict.removeAll()
        }*/
        
        withUnsafeMutablePointer(to: &dict) { pointer in
            self.accessQueue.async(flags: .barrier) {
                pointer.pointee.removeAll()
            }
        }
    }
    
    private func asynchronousAppendToArray<T>(arr: inout Array<T>, element: T) {
        withUnsafeMutablePointer(to: &arr) { pointer in
            self.accessQueue.async(flags: .barrier) {
                pointer.pointee.append(element)
            }
        }
    }
    
    private func asynchronousAppendToArray<T>(arr: inout Array<T>, arrayToAppend: Array<T>) {
        withUnsafeMutablePointer(to: &arr) { pointer in
            self.accessQueue.async(flags: .barrier) {
                pointer.pointee.append(contentsOf: arrayToAppend)
            }
        }
    }
    
    private func asynchronousRemoveAllFromArray<T>(arr: inout Array<T>) {
        withUnsafeMutablePointer(to: &arr) { pointer in
            pointer.pointee = []
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
                        $0.createdTime == self.notifications[indexPath.row].createdTime && $0.username == self.usernameMap!.array.first(where: {
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
                        $0.createdTime == self.notifications[indexPath.row].createdTime && $0.username == self.usernameMap!.array.first(where: {
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
    
    @IBAction func clearNotifications(_ sender: Any) {
        segmentedControl.isEnabled = false
        let refreshControlBackup = tableView.refreshControl
        tableView.refreshControl = nil
        (sender as! UIBarButtonItem).isEnabled = false
        
        SwiftRant.shared.clearNotifications(nil) { error, success in
            if success {
                let unreadNotifications = self.notifications.filter({ $0.read == 0 })
                
                for notification in unreadNotifications {
                    let index = self.notifications.firstIndex(where: { $0.uid == notification.uid })!
                    
                    self.notifications[index].read = 1
                }
                
                DispatchQueue.main.async {
                    self.segmentedControl.isEnabled = true
                    self.tableView.refreshControl = refreshControlBackup
                    self.navigationController!.tabBarItem.badgeValue = nil
                    (sender as! UIBarButtonItem).isEnabled = true
                    self.tableView.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlertWithError(error ?? "An unknown error has occurred while clearing notifications.", retryHandler: { self.clearNotifications(sender) })
                }
            }
        }
    }
    
    @objc func handleChange(_ sender: UISegmentedControl) {
        sender.isEnabled = false
        
        if notifRefreshTimer != nil {
            notifRefreshTimer.invalidate()
            notifRefreshTimer = nil
        }
        
        //dispatchGroup.leave()
        
        /*DispatchQueue.global(qos: .background).sync {
            dispatchGroup.wait()
        }*/
        
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
        
        //let indexPaths = (0..<tableView(tableView, numberOfRowsInSection: 0)).map { IndexPath(row: $0, section: 0) }
        let indexPaths = tableView.indexPathsForRows(in: CGRect(origin: .zero, size: tableView.contentSize)) ?? []
        
        //notifications = []
        
        //asynchronousRemoveAllFromArray(arr: &notifications)
        
        accessQueue.async(flags: .barrier) {
            self.notifications = []
        }
        
        self.notifications = []
        
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: indexPaths, with: .automatic)
        self.tableView.endUpdates()
        
        //usernameMap = nil
        accessQueue.async(flags: .barrier) {
            self.usernameMap = nil
        }
        //userImages.removeAll()
        asynchronousDeleteAllInDict(dict: &userImages)
        didSuccessfullyFetchNotifications = false
        
        accessQueue.async(flags: .barrier) {
            self.notifications = []
        }
        
        tableView.reloadData()
        
        //getAllData(notificationType: currentNotificationType, shouldGetNewData: false, completion: { self.scheduleNotificationFetches() })
        getAllData(notificationType: currentNotificationType, shouldGetNewData: false, completion: nil)
        
        dispatchGroup.notify(queue: .main) {
            debugPrint("TASK NOTIFIED!")
            
            if self.didSuccessfullyFetchNotifications {
                //print("INDEX PATH COUNT: \(self.indexPathsToInsert.count)")
                //let oldIndexPaths = (0..<self.tableView(self.tableView, numberOfRowsInSection: 0)).map { IndexPath(row: $0, section: 0) }
                let newIndexPaths = (0..<100).map { IndexPath(row: $0, section: 0) }
                
                let currentNotifications = self.notifications
                
                self.notifications = []
                
                let oldIndexPaths = (0..<self.tableView(self.tableView, numberOfRowsInSection: 0)).map { IndexPath(row: $0, section: 0) }
                
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: oldIndexPaths, with: .automatic)
                self.tableView.endUpdates()
                
                guard currentNotifications.count > 0 else {
                    /*let alertView = SPAlertView(message: "No Notifications.")
                    alertView.present(duration: 1.0)*/
                    
                    sender.isEnabled = true
                    return
                }
                
                self.notifications = currentNotifications
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: newIndexPaths, with: .automatic)
                //self.asynchronousRemoveAllFromArray(arr: &self.indexPathsToInsert)
                //self.tableView.reloadRows(at: self.indexPathsToInsert, with: .automatic)
                self.tableView.endUpdates()
                
                //self.tableView.reloadData()
                
                self.navigationController!.tabBarItem.badgeValue = self.badgeValue
                
                sender.isEnabled = true
            } else {
                self.showAlertWithError("An error occurred while requesting notifications.", retryHandler: { self.handleChange(sender) })
                
                sender.isEnabled = true
            }
            
            if self.notifRefreshTimer != nil {
                self.notifRefreshTimer.invalidate()
                self.notifRefreshTimer = nil
            }
            
            self.scheduleNotificationFetches()
        }
    }
}

extension NotificationsTableViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool { return true }
}
