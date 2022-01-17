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
//import Sentry

class rantFeedData {
    var rantFeed = [RantInFeed]()
}

class HomeFeedTableViewController: UITableViewController, UITabBarControllerDelegate {
    fileprivate var currentPage = 0
    var rantFeed = rantFeedData()
    var supplementalImages = [IndexPath:File]()
    @IBOutlet weak var menuBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var composeBarButtonItem: UIBarButtonItem!
    
    var cellHeights = [IndexPath:CGFloat]()
    
    var timer: Timer!
    
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //SentrySDK.capture(message: "BRUH!!")
        //SentrySDK.crash()
        
        navigationController?.tabBarController?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForSharedURL), name: UIWindowScene.didActivateNotification, object: nil)
        
        //edgesForExtendedLayout = []
        
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //self.navigationController?.navigationBar.shadowImage = UIImage()
        //self.navigationController?.navigationBar.isTranslucent = true
        
        if UserDefaults.standard.integer(forKey: "DRUserID") == 0 || UserDefaults.standard.integer(forKey: "DRTokenID") == 0 || UserDefaults.standard.string(forKey: "DRTokenKey") == nil {
            
            //let loginVC = UINib(nibName: "LoginViewController", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? LoginViewController
            
            let loginVC = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! UINavigationController
            
            
            
            loginVC.isModalInPresentation = true
            
            present(loginVC, animated: true)
            
            (loginVC.viewControllers.first as! LoginViewController).viewControllerThatPresented = self
        } else {
            let loadingCellNib = UINib(nibName: "LoadingCell", bundle: nil)
            tableView.register(loadingCellNib, forCellReuseIdentifier: "LoadingCell")
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
                self.refreshControl!.endRefreshing()
                self.isLoading = false
            }
            
            let mainMenu = UIMenu(title: "", children: [
                                    UIAction(title: "Test Controller", image: UIImage(systemName: "scribble")) { _ in
                                        let avatarVC = UIStoryboard(name: "AvatarEditorViewController", bundle: nil).instantiateViewController(identifier: "AvatarEditorController") as! AvatarEditorViewController
                                        
                                        self.navigationController?.pushViewController(avatarVC, animated: true)
                                    },
                
                                    UIAction(title: "Settings", image: UIImage(systemName: "gearshape.fill")!) { action in
                                        let settingsVC = UIStoryboard(name: "SettingsViewController", bundle: nil).instantiateViewController(withIdentifier: "SettingsViewController") as! UINavigationController
                                        
                                        self.present(settingsVC, animated: true, completion: nil)
                                    },
                
                                    UIAction(title: "Log Out", image: UIImage(systemName: "lock.fill")!) { action in
                                        print("Tapped on Log Out")
                                        
                                        self.timer.invalidate()
                                        
                                        self.rantFeed.rantFeed = []
                                        self.supplementalImages = [:]
                                        
                                        self.tableView.reloadData {
                                            if self.timer != nil {
                                                self.timer.invalidate()
                                                self.timer = nil
                                            }
                                            
                                            UserDefaults.standard.setValue(0, forKey: "DRUserID")
                                            UserDefaults.standard.setValue(0, forKey: "DRTokenID")
                                            UserDefaults.standard.setValue(nil, forKey: "DRTokenKey")
                                            
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
                
                DispatchQueue.global(qos: .background).async {
                    let response = APIRequest().getRantFeed(skip: 0)
                    
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
                            
                            self.navigationController?.tabBarController?.viewControllers![2].tabBarItem.badgeValue = numNotifs != 0 ? String(response.num_notifs!) : nil
                        }
                    }
                }
            }
            
            //edgesForExtendedLayout = 
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    fileprivate func performFetch(_ completionHandler: (() -> Void)?) {
        fetchData { result in
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
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: indexPaths, with: .automatic)
                self.tableView.endUpdates()
                
                break
                
            case false:
                self.showAlertWithError("Failed to fetch rants")
            }
        }
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
    
    fileprivate func fetchData(handler: @escaping ((RantFeed) -> Void)) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds((rantFeed.rantFeed.count == 0 ? 0 : 1))) {
            let data = APIRequest().getRantFeed(skip: self.rantFeed.rantFeed.count)
            
            DispatchQueue.main.async {
                handler(data)
            }
        }
    }
    
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
            cell.configure(with: Optional(&rantFeed.rantFeed[indexPath.row]), image: supplementalImages[indexPath], parentTableViewController: self, parentTableView: tableView)
        
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if UserDefaults.standard.integer(forKey: "DRUserID") == 0 || UserDefaults.standard.integer(forKey: "DRTokenID") == 0 || UserDefaults.standard.string(forKey: "DRTokenKey") == nil {
                return 0
            } else {
                return rantFeed.rantFeed.count
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
        rantFeed.rantFeed = []
        supplementalImages = [:]
        
        tableView.reloadData()
        
        //tableView.beginInfiniteScroll(true)
        self.performFetch(nil)
        self.refreshControl!.endRefreshing()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if (offsetY > contentHeight - scrollView.frame.height * 4) && !isLoading {
            isLoading = true
            performFetch {
                self.isLoading = false
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RantInFeedCell", let rantViewController = segue.destination as? RantViewController {
            rantViewController.rantID = rantFeed.rantFeed[tableView.indexPath(for: sender as! UITableViewCell)!.row].id
            
            withUnsafeMutablePointer(to: &rantFeed.rantFeed[tableView.indexPath(for: sender as! UITableViewCell)!.row], { pointer in
                rantViewController.rantInFeed = pointer
            })
            
            rantViewController.supplementalRantImage = supplementalImages[tableView.indexPath(for: sender as! UITableViewCell)!]
            rantViewController.loadCompletionHandler = nil
        } else if segue.identifier == "AfterCompose", let rantViewController = segue.destination as? RantViewController {
            rantViewController.rantID = sender as! Int
            rantViewController.rantInFeed = nil
            rantViewController.supplementalRantImage = nil
            rantViewController.loadCompletionHandler = nil
        }
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
        if let notificationsViewController = (viewController as? ExtensibleNavigationBarNavigationController) {
            debugPrint("Creating notification refresh timer!")
            
            (notificationsViewController.viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer = Timer(timeInterval: 5, repeats: true) { _ in
                (notificationsViewController.viewControllers.first! as! NotificationsTableViewController).getAllData(notificationType: (notificationsViewController.viewControllers.first! as! NotificationsTableViewController).currentNotificationType, shouldGetNewData: true, completion: nil)
            }
        } else {
            debugPrint("Destroying notification refresh timer!")
            
            if ((tabBarController.viewControllers![2] as! ExtensibleNavigationBarNavigationController).viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer != nil {
                ((tabBarController.viewControllers![2] as! ExtensibleNavigationBarNavigationController).viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer.invalidate()
                
                ((tabBarController.viewControllers![2] as! ExtensibleNavigationBarNavigationController).viewControllers.first! as! NotificationsTableViewController).notifRefreshTimer = nil
            }
        }
    }
}

extension HomeFeedTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: { $0.row >= rantFeed.rantFeed.count }) {
            performFetch(nil)
        }
    }
}
