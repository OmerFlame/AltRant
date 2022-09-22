//
//  ViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
//import Combine
//import SwiftUI
import ADNavigationBarExtension
import UserNotifications
import SwiftRant
import SwiftKeychainWrapper
import InAppSettingsKit
//import Sentry

class rantFeedData {
    var rantFeed = [RantFeed]()
}

protocol HomeFeedTableViewControllerDelegate: FeedDelegate {
    func changeRantVoteState(rantID id: Int, voteState: VoteState)
    func changeRantScore(rantID id: Int, score: Int)
    
    func reloadData()
}

class HomeFeedTableViewController: UITableViewController, UITabBarControllerDelegate, HomeFeedTableViewControllerDelegate/*, WeeklyRantHeaderDelegate*/ {
    fileprivate var currentPage = 0
    var weeklyRantHeader: WeeklyRantHeaderLarge!
    var weeklyHeaderHeightConstraint: NSLayoutConstraint?
    
    var rantFeed = rantFeedData()
    var supplementalImages = [IndexPath:File]()
    @IBOutlet weak var menuBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var composeBarButtonItem: UIBarButtonItem!
    
    var settingsNavigationController: UINavigationController?
    
    var cellHeights = [IndexPath:CGFloat]()
    
    var timer: Timer!
    
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SentrySDK.capture(message: "BRUH!!")
        //SentrySDK.crash()
        
        navigationController?.tabBarController?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForSharedURL), name: UIWindowScene.didActivateNotification, object: nil)
        
        tableView.estimatedRowHeight = 500
        tableView.rowHeight = UITableView.automaticDimension
        
        let loadingCellNib = UINib(nibName: "LoadingCell", bundle: nil)
        tableView.register(loadingCellNib, forCellReuseIdentifier: "LoadingCell")
        
        //edgesForExtendedLayout = []
        
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //self.navigationController?.navigationBar.shadowImage = UIImage()
        //self.navigationController?.navigationBar.isTranslucent = true
        
        if SwiftRant.shared.tokenFromKeychain == nil {
            
            //let loginVC = UINib(nibName: "LoginViewController", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? LoginViewController
            
            let loginVC = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! UINavigationController
            
            loginVC.isModalInPresentation = true
            
            present(loginVC, animated: true)
            
            (loginVC.viewControllers.first as! LoginViewController).viewControllerThatPresented = self
        } else {
            /*tableView.infiniteScrollIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            tableView.infiniteScrollIndicatorMargin = 40
            tableView.infiniteScrollTriggerOffset = 500
            
            //tableView.register(RantInFeedCell.self, forCellReuseIdentifier: "RantInFeedCell")
            //tableView.register(UINib(nibName: "RantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
            //tableView.register
            //tableView.register(RantCell.self, forCellReuseIdentifier: "RantCell")
            
            tableView.addInfiniteScroll { tableView -> Void in
                self.performFetch {
                    tableView.finishInfiniteScroll()
                    self.refreshControl!.endRefreshing()
                    
                    /*if self.rantFeed.rantFeed.count == 20 || self.refreshControl!.isRefreshing {
                        //tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                        //tableView.contentOffset = CGPoint(x: 0, y: -self.navigationController!.navigationBar.frame.size.height)
                        //var contentOffset = tableView.contentOffset
                        //contentOffset.y += self.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: 0))
                        
                        //tableView.setContentOffset(contentOffset, animated: true)
                        //tableView.contentInset = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
                        self.refreshControl!.endRefreshing()
                        
                        //tableView.contentInset.top = self.navigationController!.navigationBar.frame.size.height
                    }*/
                }
            }*/
            
            //tableView.beginInfiniteScroll(true)
            isLoading = true
            self.performFetch {
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.isLoading = false
                }
            }
            
            let mainMenu = UIMenu(title: "", children: [
                                    UIAction(title: "Test Controller", image: UIImage(systemName: "scribble")) { _ in
                                        let avatarVC = UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarEditorController") as! AvatarEditorViewController
                                        
                                        self.navigationController?.pushViewController(avatarVC, animated: true)
                                    },
                
                                    UIAction(title: "Settings", image: UIImage(systemName: "gearshape.fill")!) { action in
                                        self.settingsNavigationController = UIStoryboard(name: "SettingsViewController", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController") as! UINavigationController
                                        (self.settingsNavigationController?.viewControllers.first as! IASKAppSettingsViewController).delegate = self
                                        
                                        NotificationCenter.default.addObserver(self, selector: #selector(self.updateHiddenKeys), name: Notification.Name.IASKSettingChanged, object: nil)
                                        
                                        //self.present(settingsVC, animated: true, completion: nil)
                                        
                                        self.present(self.settingsNavigationController!, animated: true)
                                        
                                        //(self.settingsNavigationController?.viewControllers.first as! IASKAppSettingsViewController).
                                        
                                        self.updateHiddenKeys()
                                    },
                
                                    UIAction(title: "Log Out", image: UIImage(systemName: "power")!) { action in
                                        print("Tapped on Log Out")
                                        
                                        self.timer.invalidate()
                                        
                                        self.rantFeed.rantFeed = []
                                        self.supplementalImages = [:]
                                        
                                        self.tableView.reloadData {
                                            if self.timer != nil {
                                                self.timer.invalidate()
                                                self.timer = nil
                                            }
                                            
                                            //UserDefaults.standard.setValue(0, forKey: "DRUserID")
                                            //UserDefaults.standard.setValue(0, forKey: "DRTokenID")
                                            //UserDefaults.standard.setValue(nil, forKey: "DRTokenKey")
                                            
                                            let keychainWrapper = KeychainWrapper(serviceName: "SwiftRant", accessGroup: "SwiftRantAccessGroup")
                                            
                                            let query: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                                                                       kSecMatchLimit as String: kSecMatchLimitOne,
                                                                       kSecReturnAttributes as String: true,
                                                                       kSecReturnData as String: true,
                                                                       kSecAttrLabel as String: "SwiftRant-Attached Account" as CFString
                                            ]
                                            
                                            keychainWrapper.removeAllKeys()
                                            UserDefaults.resetStandardUserDefaults()
                                            SecItemDelete(query as CFDictionary)
                                            
                                            let loginVC = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! UINavigationController
                                            loginVC.isModalInPresentation = true
                                            
                                            self.present(loginVC, animated: true)
                                            
                                            (loginVC.viewControllers.first as! LoginViewController).viewControllerThatPresented = self
                                        }
                                    }
            ])
            
            menuBarButtonItem.menu = mainMenu
            
            timer = Timer.scheduledTimer(withTimeInterval: 21, repeats: true) { _ in
                debugPrint("Running extended notification timer!")
                
                SwiftRant.shared.getRantFeed(token: nil, skip: 0, prevSet: nil) { [weak self] result in
                    DispatchQueue.main.async {
                        
                        if case .success(let feed) = result, let numNotifs = feed.notifCount {
                            let currentNotificationCount = Int(self?.navigationController!.tabBarController!.viewControllers![3].tabBarItem.badgeValue ?? "0")!
                            
                            if currentNotificationCount < numNotifs {
                                let content = UNMutableNotificationContent()
                                
                                content.title = "New devRant Notifications!"
                                content.body = "Tap to see notifications"
                                content.categoryIdentifier = "notification"
                                content.userInfo = ["customData": "bruh"]
                                content.sound = .default
                                
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                                
                                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                                UNUserNotificationCenter.current().add(request)
                            }
                            
                            self?.navigationController?.tabBarController?.viewControllers![3].tabBarItem.badgeValue = numNotifs != 0 ? String(numNotifs) : nil
                        }
                    }
                }
                
                /*DispatchQueue.global(qos: .background).async {
                    //let response = SwiftRant.shared.getRantFeed(token: nil, skip: 0, prevSet: nil, completionHandler: <#T##((String?, RantFeed?) -> Void)##((String?, RantFeed?) -> Void)##(String?, RantFeed?) -> Void#>)
                    
                    DispatchQueue.main.async {
                        if let numNotifs = response.num_notifs {
                            let currentNotificationCount = Int(self.navigationController!.tabBarController!.viewControllers![2].tabBarItem.badgeValue ?? "0")!
                            
                            if (currentNotificationCount < numNotifs) {
                                let content = UNMutableNotificationContent()
                                
                                content.title = "New devRant Notifications!"
                                content.body = "Tap to see notifications"
                                content.categoryIdentifier = "notification"
                                content.userInfo = ["customData": "bruh"]
                                content.sound = UNNotificationSound.default
                                
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                                
                                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                                UNUserNotificationCenter.current().add(request)
                            }
                            
                            self.navigationController?.tabBarController?.viewControllers![3].tabBarItem.badgeValue = numNotifs != 0 ? String(response.num_notifs!) : nil
                        }
                    }
                }*/
            }
            
            //edgesForExtendedLayout = 
        }
    }
    
    /*override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }*/
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    fileprivate func performFetch(_ completionHandler: (() -> Void)?) {
        var combinedRantInFeedCount = 0
        
        for feed in rantFeed.rantFeed {
            combinedRantInFeedCount += feed.rants.count
        }
        
        SwiftRant.shared.getRantFeed(token: nil, skip: combinedRantInFeedCount, prevSet: rantFeed.rantFeed.last?.set ?? nil) { [weak self] result in
            defer { completionHandler?() }
            
            if case .success(let feed) = result {
                let (start, end) = (combinedRantInFeedCount, feed.rants.count + combinedRantInFeedCount)
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                
                self?.rantFeed.rantFeed.append(feed)
                
                for (idx, rant) in feed.rants.enumerated() {
                    if rant.attachedImage != nil {
                        if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent).relativePath) {
                            self?.supplementalImages[indexPaths[idx]] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attachedImage!.url)!.lastPathComponent), size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                        } else {
                            self?.supplementalImages[indexPaths[idx]] = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                        }
                    }
                }
                
                self?.currentPage += 1
                
                var tempNews: RantFeed.News? = nil
                
                if UserDefaults.standard.bool(forKey: "AlwaysLoadWRWHeader") && feed.news == nil {
                    let semaphore = DispatchSemaphore(value: 0)
                    
                    SwiftRant.shared.getWeeklyRants(token: nil, skip: 0, completionHandler: { result in
                        if case .success(let feed) = result {
                            tempNews = feed.news!
                            
                            semaphore.signal()
                        }
                    })
                    
                    semaphore.wait()
                }
                
                DispatchQueue.main.async {
                    if let news = feed.news {
                        self?.weeklyRantHeader = UINib(nibName: "WeeklyRantHeaderLarge", bundle: nil).instantiate(withOwner: nil)[0] as! WeeklyRantHeaderLarge
                        
                        self?.weeklyRantHeader.headlineLabel.text = news.headline
                        self?.weeklyRantHeader.subjectLabel.text = news.body
                        self?.weeklyRantHeader.subtitleLabel.text = news.footer
                        self?.weeklyRantHeader.frame.size.height = 100
                        
                        self?.tableView.tableHeaderView = self?.weeklyRantHeader
                        
                        self?.weeklyHeaderHeightConstraint = self?.tableView.tableHeaderView?.heightAnchor.constraint(equalToConstant: 100)
                        
                        self?.weeklyHeaderHeightConstraint?.isActive = true
                        
                        self?.tableView.tableHeaderView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self?.didTapWeeklyHeader)))
                        
                        self?.weeklyRantHeader.delegate = self
                    } else if let news = tempNews {
                        self?.weeklyRantHeader = UINib(nibName: "WeeklyRantHeaderLarge", bundle: nil).instantiate(withOwner: nil)[0] as! WeeklyRantHeaderLarge
                        
                        self?.weeklyRantHeader.headlineLabel.text = "Weekly Group Rant"
                        self?.weeklyRantHeader.subjectLabel.text = news.headline
                        self?.weeklyRantHeader.subtitleLabel.text = news.footer.components(separatedBy: " - ")[1]
                        self?.weeklyRantHeader.frame.size.height = 100
                        
                        self?.tableView.tableHeaderView = self?.weeklyRantHeader
                        
                        self?.weeklyHeaderHeightConstraint = self?.tableView.tableHeaderView?.heightAnchor.constraint(equalToConstant: 100)
                        
                        self?.weeklyHeaderHeightConstraint?.isActive = true
                        
                        self?.tableView.tableHeaderView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self?.didTapWeeklyHeader)))
                        
                        self?.weeklyRantHeader.delegate = self
                    }
                    
                    /*self?.weeklyRantHeader = UINib(nibName: "WeeklyRantHeaderLarge", bundle: nil).instantiate(withOwner: nil)[0] as! WeeklyRantHeaderLarge
                    
                    self?.weeklyRantHeader.headlineLabel.text = "Weekly Group Rant"
                    self?.weeklyRantHeader.subjectLabel.text = "Your most embarrassing programming story?"
                    self?.weeklyRantHeader.subtitleLabel.text = "Add tag 'wk316' to your rant"
                    self?.weeklyRantHeader.frame.size.height = 100*/
                    
                    self?.navigationController?.tabBarController?.viewControllers![3].tabBarItem.badgeValue = feed.notifCount != 0 ? String(feed.notifCount!) : nil
                    
                    CATransaction.begin()
                    
                    CATransaction.setCompletionBlock {
                        //NotificationCenter.default.post(name: windowResizeNotification, object: nil)
                        
                        self?.tableView.reloadData()
                    }
                    
                    self?.tableView.beginUpdates()
                    self?.tableView.insertRows(at: indexPaths, with: .automatic)
                    self?.tableView.endUpdates()
                    
                    /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.tableView.reloadData()
                    }*/
                    
                    CATransaction.commit()
                }
            } else if case .failure(let failure) = result {
                DispatchQueue.main.async {
                    self?.showAlertWithError(failure.message)
                }
            }
        }
        
        /*fetchData { result in
            defer { completionHandler?() }
            
            switch result.success {
            case true:
                let count = self.rantFeed.rantFeed.count
                let (start, end) = (count, result.rants!.count + count)
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                
                self.rantFeed.rantFeed.append(contentsOf: result.rants!)
                
                //var file: File?
                
                if let numNotifs = result.num_notifs {
                    self.navigationController?.tabBarController?.viewControllers![2].tabBarItem.badgeValue = numNotifs != 0 ? String(numNotifs) : nil
                }
                
                for (idx, rant) in result.rants!.enumerated() {
                    if rant.attached_image != nil {
                        /*let completionSemaphore = DispatchSemaphore(value: 0)
                        
                        var image = UIImage()
                        
                        URLSession.shared.dataTask(with: URL(string: (result.rants![idx].attached_image?.url!)!)!) { data, _, _ in
                            image = UIImage(data: data!)!
                            
                            completionSemaphore.signal()
                        }.resume()
                        
                        completionSemaphore.wait()*/
                        
                        
                        //let resizeMultiplier = self.getImageResizeMultiplier(imageWidth: image.size.width, imageHeight: image.size.height, multiplier: 1)
                        
                        //let finalSize = CGSize(width: image.size.width / resizeMultiplier, height: image.size.height / resizeMultiplier)
                        
                        //UIGraphicsBeginImageContextWithOptions(finalSize, false, resizeMultiplier)
                        //image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: finalSize))
                        //let newImage = UIGraphicsGetImageFromCurrentImageContext()
                        //UIGraphicsEndImageContext()
                        
                        //self.supplementalImages.append(newImage)
                        
                        //file = File.loadFile(image: rant.attached_image!, size: CGSize(width: rant.attached_image!.width!, height: rant.attached_image!.height!))
                        
                        //self.supplementalImages.append(Optional(File.loadFile(image: rant.attached_image!, size: CGSize(width: rant.attached_image!.width!, height: rant.attached_image!.height!))))
                        if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attached_image!.url!)!.lastPathComponent).relativePath) {
                            self.supplementalImages[indexPaths[idx]] = File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: rant.attached_image!.url!)!.lastPathComponent), size: CGSize(width: rant.attached_image!.width!, height: rant.attached_image!.height!))
                        }
                        
                        self.supplementalImages[indexPaths[idx]] = File.loadFile(image: rant.attached_image!, size: CGSize(width: rant.attached_image!.width!, height: rant.attached_image!.height!))
                    }/* else {
                        self.supplementalImages.append(nil)
                    }*/
                }
                
                self.currentPage += 1
                
                
                CATransaction.begin()
                
                CATransaction.setCompletionBlock {
                    NotificationCenter.default.post(name: windowResizeNotification, object: nil)
                }
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: indexPaths, with: .automatic)
                self.tableView.endUpdates()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.tableView.reloadData()
                }
                
                CATransaction.commit()
                
                break
                
            case false:
                self.showAlertWithError("Failed to fetch rants")
            }
        }*/
    }
    
    fileprivate func showAlertWithError(_ error: String) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.performFetch(nil) }))
        present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //var defaults = UserDefaults.group.dictionaryRepresentation()
        
        checkForSharedURL()
    }
    
    @objc func checkForSharedURL() {
        if let sharedURL = UserDefaults.group.url(forKey: "ARSharedLink") {
            /*let alertController = UIAlertController(title: "SUCCESS", message: "GOT SHARED URL: \(sharedURL.absoluteString)", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "YAS", style: .default, handler: nil))
            
            present(alertController, animated: true, completion: nil)*/
            
            performSegue(withIdentifier: "AfterCompose", sender: Int(sharedURL.absoluteString.components(separatedBy: "/").last!)!)
            
            UserDefaults.group.set(nil, forKey: "ARSharedLink")
        }
    }
    
    /*fileprivate func fetchData(handler: @escaping ((RantFeed) -> Void)) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds((rantFeed.rantFeed.count == 0 ? 0 : 1))) {
            let data = APIRequest().getRantFeed(skip: self.rantFeed.rantFeed.count)
            
            DispatchQueue.main.async {
                handler(data)
            }
        }
    }*/
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            //let rant = rantFeed.rantFeed[indexPath.row]
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! SecondaryRantInFeedCell
        
            //let image = supplementalImages[indexPath.row]
        
            //cell = RantInFeedCell.loadFromXIB()
            
            // Calculate the index of the feed in the feed array and the index of the rant in the rant array
            var rantPointer: UnsafeMutablePointer<RantInFeed>? = nil
            var counter = 0
            var feedOffset = 0
            var rantOffset = 0
            
            for (idx, feed) in rantFeed.rantFeed.enumerated() {
                if counter + (feed.rants.count - 1) < indexPath.row {
                    counter += (feed.rants.count - 1)
                    feedOffset = idx
                    continue
                } else {
                    rantOffset = indexPath.row - counter
                }
            }
            
            cell.configure(with: Optional(rantFeed.rantFeed[feedOffset].rants[rantOffset]), image: supplementalImages[indexPath], parentTableViewController: self, parentTableView: tableView)
            
            cell.delegate = self
            
            cell.layoutIfNeeded()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            cell.activityIndicator.startAnimating()
            return cell
        }
        
        /*if indexPath.row % 2 == 0 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! RantInFeedCell
            
            cell = RantInFeedCell.loadFromXIB()
            cell.testConfigure()
            
            return cell
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "RantCell") as! RantCell
            
            cell = RantCell.loadFromXIB()
            cell.testConfigure()
            
            return cell
        }*/
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        NotificationCenter.default.post(name: windowResizeNotification, object: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if SwiftRant.shared.tokenFromKeychain == nil {
                return 0
            } else {
                var count = 0
                
                for feed in rantFeed.rantFeed {
                    count += feed.rants.count
                }
                
                return count
            }
        } else if section == 1 {
            return 1
        } else {
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    @IBAction func handleRefresh() {
        isLoading = true
        currentPage = 0
        let indexPaths = (0..<tableView(tableView, numberOfRowsInSection: 0)).map { return IndexPath(row: $0, section: 0) }
        rantFeed.rantFeed = []
        supplementalImages = [:]
        
        tableView.reloadData()
        //tableView.deleteRows(at: indexPaths, with: .automatic)
        
        //tableView.beginInfiniteScroll(true)
        self.performFetch {
            self.isLoading = false
        }
        self.refreshControl!.endRefreshing()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows,
           indexPathsForVisibleRows.contains(IndexPath(row: 0, section: 1)) && !isLoading && SwiftRant.shared.tokenFromKeychain != nil && tableView(tableView, numberOfRowsInSection: 0) > 0 {
            isLoading = true
            performFetch {
                self.isLoading = false
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RantInFeedCell", let rantViewController = segue.destination as? RantViewController {
            //rantViewController.rantID = rantFeed.rantFeed[tableView.indexPath(for: sender as! UITableViewCell)!.row].id
            
            rantViewController.rantID = (sender as! SecondaryRantInFeedCell).rantContents!.id
            
            /*withUnsafeMutablePointer(to: &(sender as! RantInFeedCell).rant, { pointer in
                rantViewController.rantInFeed = pointer
            })*/
            
            //rantViewController.rantInFeed = (sender as! SecondaryRantInFeedCell).rantContents
            rantViewController.homeFeedDelegate = self
            
            rantViewController.supplementalRantImage = supplementalImages[tableView.indexPath(for: sender as! UITableViewCell)!]
            rantViewController.loadCompletionHandler = nil
        } else if segue.identifier == "AfterCompose", let rantViewController = segue.destination as? RantViewController {
            rantViewController.rantID = sender as! Int
            rantViewController.rantInFeed = nil
            rantViewController.supplementalRantImage = nil
            rantViewController.loadCompletionHandler = nil
        }/* else if segue.identifier == "WeeklyRant", let weeklyRantFeedViewController = segue.destination as? WeeklyRantFeedViewController {
            
        }*/
    }
    
    @IBAction func openComposeView(_ sender: UIBarButtonItem) {
        let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
        (composeVC.viewControllers.first as! ComposeViewController).rantID = nil
        (composeVC.viewControllers.first as! ComposeViewController).isComment = false
        (composeVC.viewControllers.first as! ComposeViewController).isEdit = false
        (composeVC.viewControllers.first as! ComposeViewController).viewControllerThatPresented = self
        
        composeVC.isModalInPresentation = true
        
        present(composeVC, animated: true, completion: nil)
    }
    
    // MARK: - Tab Bar Controller Delegate
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let notificationsViewController = (viewController as? ExtensibleNavigationBarNavigationController), notificationsViewController.viewControllers.contains(where: { $0 is NotificationsTableViewController }) {
            debugPrint("Creating notification refresh timer!")
            
            /*(notificationsViewController.viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer = Timer(timeInterval: 5, repeats: true) { _ in
                (notificationsViewController.viewControllers.first! as! NotificationsTableViewController).getAllData(notificationType: (notificationsViewController.viewControllers.first! as! NotificationsTableViewController).currentNotificationType, shouldGetNewData: true, completion: nil)
            }*/
            
            (notificationsViewController.viewControllers.first! as! NotificationsTableViewController).scheduleNotificationFetches()
        } else {
            debugPrint("Destroying notification refresh timer!")
            
            if ((tabBarController.viewControllers![3] as! ExtensibleNavigationBarNavigationController).viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer != nil {
                ((tabBarController.viewControllers![3] as! ExtensibleNavigationBarNavigationController).viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer.invalidate()
                
                ((tabBarController.viewControllers![3] as! ExtensibleNavigationBarNavigationController).viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer = nil
            }
        }
    }
    
    private func indexOfRant(withID id: Int) -> IndexPath? {
        for (feedIdx, feed) in rantFeed.rantFeed.enumerated() {
            if let rantIdx = feed.rants.firstIndex(where: { $0.id == id }) {
                return IndexPath(row: rantIdx, section: feedIdx)
            }
        }
        
        return nil
    }
    
    // MARK: - Home Feed Table View Controller Delegate
    func changeRantVoteState(rantID id: Int, voteState: VoteState) {
        let rantIndex = indexOfRant(withID: id)
        
        if let rantIndex = rantIndex {
            rantFeed.rantFeed[rantIndex.section].rants[rantIndex.row].voteState = voteState
            
            //tableView.reloadData()
        }
    }
    
    func changeRantScore(rantID id: Int, score: Int) {
        let rantIndex = indexOfRant(withID: id)
        
        if let rantIndex = rantIndex {
            rantFeed.rantFeed[rantIndex.section].rants[rantIndex.row].score = score
            
            //tableView.reloadData()
        }
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    // MARK: - Feed Delegate
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: SecondaryRantInFeedCell) {
        let rantIndex = indexOfRant(withID: id)
        
        guard let rantIndex = rantIndex else {
            let alertController = UIAlertController(title: "Error", message: "Could not find rant in the feed. Please file in a bug report!", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            return
        }

        
        SwiftRant.shared.voteOnRant(nil, rantID: id, vote: vote) { [weak self] result in
            if case .success(let updatedRant) = result {
                self?.rantFeed.rantFeed[rantIndex.section].rants[rantIndex.row].voteState = updatedRant.voteState
                self?.rantFeed.rantFeed[rantIndex.section].rants[rantIndex.row].score = updatedRant.score
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            } else if case .failure(let failure) = result {
                let alertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func didTapWeeklyHeader() {
        performSegue(withIdentifier: "WeeklyRant", sender: nil)
    }
}

extension HomeFeedTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: { $0.row >= rantFeed.rantFeed.count }) {
            performFetch(nil)
        }
    }
}

extension HomeFeedTableViewController: IASKSettingsDelegate {
    @objc func updateHiddenKeys() {
        var hiddenKeys = Set<String>()
        if !UserDefaults.standard.bool(forKey: "NotificationServer") {
            hiddenKeys.formUnion(["NotificationServerAddress", "NotificationServerPort"])
        }
        
        (settingsNavigationController?.viewControllers.first as! IASKAppSettingsViewController).setHiddenKeys(hiddenKeys, animated: true)
    }
    
    func settingsViewControllerDidEnd(_ settingsViewController: IASKAppSettingsViewController) {
        settingsViewController.dismiss(animated: true)
    }
}

extension HomeFeedTableViewController: WeeklyRantHeaderDelegate {
    func didCloseWeeklyRantHeader(_ weeklyRantHeader: WeeklyRantHeaderLarge) {
        var newFrame = weeklyRantHeader.frame
        
        newFrame.size.height = 0
        
        UIView.animate(withDuration: 0.25, animations: {
            weeklyRantHeader.alpha = 0
            self.weeklyHeaderHeightConstraint?.constant = 0
            weeklyRantHeader.frame.size = CGSize(width: weeklyRantHeader.frame.width, height: 0)
            self.tableView.tableHeaderView = weeklyRantHeader
            self.tableView.layoutIfNeeded()
        }) { finished in
            weeklyRantHeader.isHidden = finished
            self.tableView.tableHeaderView = nil
        }
    }
}
