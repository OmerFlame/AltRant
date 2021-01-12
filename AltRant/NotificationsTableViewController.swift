//
//  NotificationsTableViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 1/4/21.
//

import UIKit
import ADNavigationBarExtension

class NotificationsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ScrollUISegmentControllerDelegate {
    var segmentedControl: ScrollUISegmentController!
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        //self.additionalSafeAreaInsets = UIEdgeInsets(top: 50)
        
        
        
        /*barExtension = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        //barExtension.effect = UIBlurEffect(style: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light)
        let testLabel = UILabel(frame: CGRect(x: 115.5, y: 10.5, width: 183, height: 29))
        
        testLabel.font = .systemFont(ofSize: 12)
        testLabel.text = "This label appears as part of the navigation bar."
        testLabel.numberOfLines = 0
        testLabel.preferredMaxLayoutWidth = 183
        
        barExtension.addSubview(testLabel)
        
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        testLabel.centerXAnchor.constraint(equalTo: barExtension.centerXAnchor).isActive = true
        testLabel.centerYAnchor.constraint(equalTo: barExtension.centerYAnchor).isActive = true
        
        (navigationController as! ExtensibleNavigationBarNavigationController).setNavigationBarExtensionView(barExtension, forHeight: 50)*/
        
        segmentedControl = ScrollUISegmentController()
        segmentedControl.frame.size.height = 32
        
        let itemWidth = ("Subscriptions" as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], context: nil).size.width
        
        segmentedControl.itemWidth = itemWidth + 10
        
        segmentedControl.segmentItems = ["All", "++'s", "Mentions", "Comments", "Subscriptions"]
        
        segmentedControl.segmentDelegate = self
        
        //visualEffectView.contentView.addSubview(segmentedControl)
        //visualEffectView.sizeToFit()
        
        (navigationController as! ExtensibleNavigationBarNavigationController).setNavigationBarExtensionView(segmentedControl, forHeight: 33)
        
        //view.addSubview(barExtension)
        //barExtension.translatesAutoresizingMaskIntoConstraints = false
        //barExtension.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        //barExtension.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -50).isActive = true
        //barExtension.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        //barExtension.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        //barExtension.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //barExtension.frame.origin.y += 193
        
        //self.additionalSafeAreaInsets = UIEdgeInsets(top: 50)
        
        //tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        
        /*for i in navigationController!.navigationBar.subviews {
            print(String(describing: type(of: i)))
        }
        
        for i in navigationController!.navigationBar.subviews.first!.subviews {
            print(String(describing: type(of: i)))
        }
        
        /*let visualEffectsView = navigationController?.navigationBar.subviews.first(where: {
            String(describing: type(of: $0)) == "_UIBarBackground"
        })?.subviews.first(where: {
            String(describing: type(of: $0)) == "UIVisualEffectView"
        }) as! UIVisualEffectView*/
        
        
        //visualEffectsView.frame.size.height = 32
        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light))
        
        segmentedControl = ScrollUISegmentController()
        segmentedControl.frame.size.height = 32
        
        visualEffectView.frame = segmentedControl.frame
        
        let itemWidth = ("Subscriptions" as NSString).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], context: nil).size.width
        
        segmentedControl.itemWidth = itemWidth + 10
        
        segmentedControl.segmentItems = ["All", "++'s", "Mentions", "Comments", "Subscriptions"]
        
        //visualEffectView.contentView.addSubview(segmentedControl)
        //visualEffectView.sizeToFit()
        
        (navigationController as! ExtensibleNavigationBarNavigationController).setNavigationBarExtensionView(visualEffectView, forHeight: 32)
        
        visualEffectView.contentView.addSubview(segmentedControl)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.topAnchor.constraint(equalTo: visualEffectView.contentView.topAnchor).isActive = true
        segmentedControl.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: visualEffectView.contentView.leadingAnchor).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: visualEffectView.contentView.trailingAnchor).isActive = true*/
        
        //navigationController?.navigationBar.isTranslucent = false
        
        //originalExtensionFrame = barExtension.frame
        
        //originalExtensionFrame = barExtension.convert(barExtension.frame, to: view)
        
        //print("ORIGINAL EXTENSION FRAME Y: \(originalExtensionFrame.origin.y)")
        
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
    
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("NEW CONTENT OFFSET: \(scrollView.contentOffset)")
        print("NAVIGATION BAR MAX Y: \(navigationController!.navigationBar.frame.maxY)")
        
        if navigationController!.navigationBar.frame.maxY > originalNavbarMaxY {
            barExtension.frame.origin.y = navigationController!.navigationBar.frame.maxY
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scrollViewDidScroll(tableView)
        
        transitionCoordinator?.animate(alongsideTransition: { [weak self](context) in
            self?.barExtension.alpha = 1
            self?.barExtension.frame.origin.y = (self?.navigationController!.navigationBar.frame.maxY)!
        }, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(tableView.frame.minY)
        
        transitionCoordinator?.animate(alongsideTransition: { [weak self](context) in
            self?.barExtension.alpha = 0
            self?.barExtension.frame.origin.y -= 50
        }, completion: { _ in
            self.navigationController?.navigationBar.shadowImage = nil
            self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        })
    }*/
    
    @objc func didPullToRefresh(_ sender: UIRefreshControl) {
        //notifications = []
        unreadNotificationCounters = nil
        //userImages.removeAll()
        //usernameMap = nil
        
        tableView.reloadData()
        //tableView.isHidden = true
        
        getAllData(notificationType: currentNotificationType, shouldGetNewData: true, completion: { sender.endRefreshing() })
        
        //sender.endRefreshing()
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
                //self.notifications = Array(notificationsData.items[0...99])
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
                    
                    /*if shouldGetNewData {
                        self.tabBarItem.badgeValue = "\(notificationsData.items.count)"
                    } else {
                        self.tabBarItem.badgeValue = nil
                    }*/
                    
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
    
    // MARK: - Trait Collection Changes
    
    /*override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        barExtension.effect = UIBlurEffect(style: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light)
    }*/
    
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
                        /*if let cell = tableView.cellForRow(at: IndexPath(row: j, section: 0)) as? RantUpvoteCell {
                            cell.usernameUpvoteLabel.font = .systemFont(ofSize: 17)
                            cell.usernameUpvoteLabel.isEnabled = false
                        }*/
                        
                        tableView.reloadRows(at: [IndexPath(row: j, section: 0)], with: .none)
                    }
                }
            }
            
            //let currentTabBarBadgeNumber = Int(navigationController!.tabBarItem.badgeValue ?? "")
            
            if let currentTabBarBadgeNumber = Int(navigationController!.tabBarItem.badgeValue ?? "") {
                if currentTabBarBadgeNumber - notificationsToModify.count == 0 {
                    navigationController!.tabBarItem.badgeValue = nil
                } else {
                    navigationController!.tabBarItem.badgeValue = String(currentTabBarBadgeNumber - notificationsToModify.count)
                }
            }
            
            /*if (tableView.cellForRow(at: indexPath) as! RantUpvoteCell).usernameUpvoteLabel.font == UIFont.systemFont(ofSize: 17, weight: .semibold) {
                (tableView.cellForRow(at: indexPath) as! RantUpvoteCell).usernameUpvoteLabel.font = .systemFont(ofSize: 17)
                (tableView.cellForRow(at: indexPath) as! RantUpvoteCell).usernameUpvoteLabel.isEnabled = false
                
                let currentTabBarBadgeNumber = Int(navigationController!.tabBarItem.badgeValue!)!
                navigationController!.tabBarItem.badgeValue = String(currentTabBarBadgeNumber - 1)
            }*/
            
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
    
    @IBAction func unwindToNotifications(_ unwindSegue: UIStoryboardSegue) {
        print("running this shit")
        //let sourceViewController = unwindSegue.source
        
        // Use data from the view controller which initiated the unwind segue
        
        if unwindSegue.identifier == "unwindToNotifications" {
            notifRefreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                self.getAllData(notificationType: self.currentNotificationType, shouldGetNewData: true, completion: nil)
            }
        }
    }
    
    func selectItemAt(index: Int, onScrollUISegmentController scrollUISegmentController: ScrollUISegmentController) {
        notifRefreshTimer.invalidate()
        notifRefreshTimer = nil
        
        if index == 0 {
            currentNotificationType = .all
        } else if index == 1 {
            currentNotificationType = .upvotes
        } else if index == 2 {
            currentNotificationType = .mentions
        } else if index == 3 {
            currentNotificationType = .comments
        } else if index == 4 {
            currentNotificationType = .subs
        }
        
        let indexPaths = (0..<tableView(tableView, numberOfRowsInSection: 0)).map { IndexPath(row: $0, section: 0) }
        
        notifications = []
        usernameMap = nil
        userImages.removeAll()
        didSuccessfullyFetchNotifications = false
        
        tableView.deleteRows(at: indexPaths, with: .automatic)
        
        //notifRefreshTimer.invalidate()
        //notifRefreshTimer = nil
        
        getAllData(notificationType: currentNotificationType, shouldGetNewData: false, completion: { self.scheduleNotificationFetches() })
    }
}

extension NotificationsTableViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool { return true }
}
