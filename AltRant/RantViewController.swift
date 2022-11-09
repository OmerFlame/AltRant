//
//  RantViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/3/20.
//

import UIKit
//import SwiftUI
import QuickLook
import ADNavigationBarExtension
import SwiftRant
import Foundation
import SwiftHEXColors

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

actor UserImageStore {
    private var images = [Int: UIImage]()
    
    func store(userID: Int, image: UIImage) {
        images[userID] = image
    }
    
    func image(forUserID id: Int) -> UIImage? {
        return images[id]
    }
    
    func removeAllImages() {
        images = [:]
    }
}

actor UserImageLoader {
    private var store: UserImageStore
    private let urlSession: URLSession
    private var activeTasks = [Int: Task<UIImage, Error>]()
    
    init(store: UserImageStore) {
        self.store = store
        urlSession = URLSession(configuration: .background(withIdentifier: "UserImageStore"))
    }
    
    func loadImage(withUserID id: Int) async throws -> UIImage {
        if let existingTask = activeTasks[id] {
            return try await existingTask.value
        }
        
        let task = Task<UIImage, Error> {
            if let storedImage = await store.image(forUserID: id) {
                activeTasks[id] = nil
                return storedImage
            }
            
            let result = await SwiftRant.shared.getProfileFromID(id, token: nil, userContentType: .rants, skip: 0)
            
            switch result {
            case .success(let profile):
                if let avatarImage = profile.avatarSmall.avatarImage {
                    let url = URL(string: "https://avatars.devrant.com/\(avatarImage)")!
                    let (data, _) = try await urlSession.data(from: url)
                    let image = UIImage(data: data)
                    await store.store(userID: id, image: image!)
                    
                    activeTasks[id] = nil
                    return image!
                } else {
                    let image = UIImage(color: UIColor(hexString: profile.avatarSmall.backgroundColor)!, size: CGSize(width: 45, height: 45))!
                    await store.store(userID: id, image: image)
                    return image
                }
            case .failure(let failure):
                throw failure
            }
        }
        
        activeTasks[id] = task
        return try await task.value
    }
    
    func loadImage(from url: URL, forUserID id: Int) async throws -> UIImage {
        if let existingTask = activeTasks[id] {
            return try await existingTask.value
        }
        
        let task = Task<UIImage, Error> {
            if let storedImage = await store.image(forUserID: id) {
                activeTasks[id] = nil
                return storedImage
            }
            
            
            //let (data, _) = try await urlSession.data(from: url)
            
            //var resultData: Data! = nil
            
            
            
            //let image = UIImage(data: data)!
            //await store.store(userID: id, image: image)
            
            let image = await UIImage().loadFromWeb(url: url)!
            await store.store(userID: id, image: image)
            
            activeTasks[id] = nil
            return image
        }
        
        activeTasks[id] = task
        return try await task.value
    }
    
    func waitUntilAllTasksAreFinished() async {
        while !activeTasks.isEmpty {
            
        }
    }
    
    func cancelAllTasks() {
        for task in activeTasks {
            task.value.cancel()
        }
    }
}

protocol RantViewControllerDelegate: FeedDelegate {
    func changeRantVoteState(voteState: VoteState)
    func changeRantScore(score: Int)
    
    func changeCommentVoteState(commentID id: Int, voteState: VoteState)
    func changeCommentScore(commentID id: Int, score: Int)
    
    func reloadData()
}

class RantViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, RantViewControllerDelegate {
    //var delegate: RantViewControllerDelegate?
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    var didFinishLoading = false
    
    var rantID: Int?
    var tappedRant: RantCell?
    var tappedComment: CommentCell?
    var supplementalRantImage: File?
    
    var commentImages = [Int:File?]()
    
    var rant: Rant?
    var comments = [Comment]()
    var profile: Profile? = nil
    var ranterProfileImage: UIImage?
    //var rantInFeed: UnsafeMutablePointer<RantInFeed>?
    //var commentInFeed: UnsafeMutablePointer<Comment>?
    //var doesSupplementalImageExist = false
    
    var rantInFeed: RantInFeed?
    var commentInFeed: Comment?
    
    var homeFeedDelegate: HomeFeedTableViewControllerDelegate?
    var profileFeedDelegate: ProfileTableViewControllerDelegate?
    var subscribedFeedDelegate: SubscribedFeedViewControllerDelegate?
    
    @MainActor var loadCompletionHandler: ((RantViewController?) -> Void)?
    
    var rowHeights = [IndexPath:CGFloat]()
    
    var textsWithLinks = [Int:NSAttributedString]()
    
    let userImageStore = UserImageStore()
    var userImageLoader: UserImageLoader!
    
    var currentDate: Date!
    
    /*init(rantID: Int?) {
        self.rantID = rantID
        super.init(nibName: nil, bundle: nil)
    }*/
    
    /*convenience init() {
        self.init(rantID: nil)
    }*/
    
    /*init?(coder: NSCoder, rantID: Int, rantInFeed: Binding<RantInFeed>?, supplementalRantImage: File?, loadCompletionHandler: ((RantViewController?) -> Void)?) {
        self.rantID = rantID
        self.rantInFeed = rantInFeed
        self.supplementalRantImage = supplementalRantImage
        self.loadCompletionHandler = loadCompletionHandler
        //self.doesSupplementalImageExist = doesSupplementalImageExist
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        //super.init(coder: coder)
        fatalError("You must use the special coder init!")
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(fixNavigationBar), name: NSNotification.Name("FixNavigationBar"), object: nil)
        
        userImageLoader = UserImageLoader(store: userImageStore)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if didFinishLoading == false {
            //navigationItem.rightBarButtonItems![0].isEnabled = false
            //navigationItem.rightBarButtonItems![1].isEnabled = false
            
            navigationItem.rightBarButtonItems?.forEach({ $0.isEnabled = false })
            
            for constraint in self.tableView.constraints {
                self.tableView.removeConstraint(constraint)
            }
            //self.edgesForExtendedLayout = []
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            
            //self.tableView.contentInset = UIEdgeInsets(top: -self.view.safeAreaInsets.top, left: 0, bottom: -self.view.safeAreaInsets.bottom, right: 0)
            
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            self.loadingIndicator.startAnimating()
            
            Task {
                let result = await SwiftRant.shared.getRantFromID(token: nil, id: rantID ?? -1, lastCommentID: nil)
                self.currentDate = Date()
                
                if case .success(let (rant, comments)) = result {
                    self.rant = rant
                    
                    self.comments = (!comments.isEmpty ? comments : [])
                    
                    if rant.links != nil {
                        let links = rant.links!
                        let attributedString = NSMutableAttributedString(string: rant.text)
                        
                        attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: (rant.text as NSString).range(of: rant.text))
                        
                        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: (rant.text as NSString).range(of: rant.text))
                        
                        for link in links {
                            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), range: link.calculatedRange)
                            
                            if link.type == "mention" {
                                attributedString.addAttribute(.link, value: "mention://\(link.url)", range: link.calculatedRange)
                            } else {
                                attributedString.addAttribute(.link, value: link.url, range: link.calculatedRange)
                            }
                        }
                        
                        self.textsWithLinks[rant.id] = attributedString
                    }
                    
                    for comment in comments {
                        if let avatarImage = comment.userAvatar.avatarImage {
                            Task {
                                try? await self.userImageLoader.loadImage(from: URL(string: "https://avatars.devrant.com/\(avatarImage)")!, forUserID: comment.userID)
                                
                                //try? await self.userImageLoader.loadImage(withUserID: comment.userID)
                            }
                        } else {
                            await self.userImageStore.store(userID: comment.userID, image: UIImage(color: UIColor(hexString: comment.userAvatar.backgroundColor)!, size: CGSize(width: 45, height: 45))!)
                        }
                        
                        /*if comment.attachedImage == nil {
                            //commentImages.append(nil)
                            self.commentImages[comment.id] = nil
                        } else {
                            self.commentImages[comment.id] = File.loadFile(image: comment.attachedImage!, size: CGSize(width: comment.attachedImage!.width, height: comment.attachedImage!.height))
                        }*/
                        
                        if comment.links != nil {
                            let links = comment.links!
                            
                            let attributedString = NSMutableAttributedString(string: comment.body)
                            
                            attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: (comment.body as NSString).range(of: comment.body))
                            
                            attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: (comment.body as NSString).range(of: comment.body))
                            
                            for link in links {
                                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), range: link.calculatedRange)
                                
                                if link.type == "mention" {
                                    attributedString.addAttribute(.link, value: "mention://\(link.url)", range: link.calculatedRange)
                                } else {
                                    attributedString.addAttribute(.link, value: link.url, range: link.calculatedRange)
                                }
                            }
                            
                            self.textsWithLinks[comment.id] = attributedString
                        }
                    }
                    
                    let profileResult = await SwiftRant.shared.getProfileFromID(rant.userID, token: nil, userContentType: .rants, skip: 0)
                    
                    if case .success(let profile) = profileResult {
                        self.profile = profile
                        
                        /*if self.rant?.attachedImage != nil && self.supplementalRantImage == nil {
                            self.supplementalRantImage = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                        }*/
                        
                        
                        
                        if self.rant?.userAvatarLarge.avatarImage != nil {
                            self.ranterProfileImage = await UIImage().loadFromWeb(url: URL(string: "https://avatars.devrant.com/\(rant.userAvatarLarge.avatarImage!)")!)
                        }
                        
                        await userImageLoader.waitUntilAllTasksAreFinished()
                        
                        if let weekly = rant.weekly {
                            let header = UINib(nibName: "WeeklyRantHeaderSmall", bundle: nil).instantiate(withOwner: nil)[0] as! WeeklyRantHeaderSmall
                            
                            header.titleLabel.text = weekly.topic
                            header.subtitleLabel.text = "Week \(weekly.week) Group Rant"
                            header.frame.size.height = 50
                            
                            (navigationController as! ExtensibleNavigationBarNavigationController).setNavigationBarExtensionView(header, forHeight: 50)
                            
                            //self.tableView.tableHeaderView = header
                        }
                        
                        self.didFinishLoading = true
                        self.loadingIndicator.stopAnimating()
                        self.tableView.isHidden = false
                        
                        self.tableView.dataSource = self
                        self.tableView.delegate = self
                        self.tableView.register(UINib(nibName: "RantCell", bundle: nil), forCellReuseIdentifier: "RantCell")
                        self.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
                        
                        self.tableView.reloadData {
                            self.navigationItem.rightBarButtonItems![0].isEnabled = true
                            self.navigationItem.rightBarButtonItems![1].isEnabled = true
                            
                            self.loadCompletionHandler?(self)
                            
                            self.tableView.setNeedsLayout()
                            self.tableView.layoutIfNeeded()
                            self.tableView.reloadData()
                            
                            /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.500) {
                                /*self.tableView.setNeedsLayout()
                                self.tableView.layoutIfNeeded()
                                self.tableView.reloadData()*/
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.500) {
                                    /*UIView.performWithoutAnimation {
                                        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                                        self.tableView.setContentOffset(.zero, animated: true)
                                    }*/
                                    
                                    /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.500) {
                                        UIView.performWithoutAnimation {
                                            self.tableView.beginUpdates()
                                            self.tableView.endUpdates()
                                        }
                                    }*/
                                }
                                
                                /*DispatchQueue.main.async {
                                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                                    NotificationCenter.default.post(name: windowResizeNotification, object: nil)
                                }*/
                            }*/
                        }
                        
                        /*DispatchQueue.main.async {
                            self.didFinishLoading = true
                            self.loadingIndicator.stopAnimating()
                            self.tableView.isHidden = false
                            
                            self.tableView.dataSource = self
                            self.tableView.delegate = self
                            self.tableView.register(UINib(nibName: "RantCell", bundle: nil), forCellReuseIdentifier: "RantCell")
                            self.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
                            
                            self.tableView.reloadData {
                                self.loadCompletionHandler?(self)
                            }
                        }*/
                        
                        /*DispatchQueue.main.async {
                            self.didFinishLoading = true
                            self.loadingIndicator.stopAnimating()
                            self.tableView.isHidden = false
                            
                            self.tableView.dataSource = self
                            self.tableView.delegate = self
                            self.tableView.register(UINib(nibName: "RantCell", bundle: nil), forCellReuseIdentifier: "RantCell")
                            self.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
                            
                            self.tableView.reloadData {
                                self.loadCompletionHandler?(self)
                            }
                        }*/
                    } else if case .failure(let failure) = profileResult {
                        self.showAlertWithError(failure.message, retryHandler: nil)
                    }
                } else if case .failure(let failure) = result {
                    self.showAlertWithError(failure.message, retryHandler: nil)
                }
            }
            
            /*SwiftRant.shared.getRantFromID(token: nil, id: rantID!, lastCommentID: nil) { [weak self] error, rant, comments in
                if let rant = rant, let comments = comments {
                    self?.rant = rant
                    
                    self?.comments = (!comments.isEmpty ? comments : [])
                    
                    if rant.links != nil {
                        let links = rant.links!
                        let attributedString = NSMutableAttributedString(string: rant.text)
                        
                        attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: (rant.text as NSString).range(of: rant.text))
                        
                        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: (rant.text as NSString).range(of: rant.text))
                        
                        for link in links {
                            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), range: link.calculatedRange)
                            
                            if link.type == "mention" {
                                attributedString.addAttribute(.link, value: "mention://\(link.url)", range: link.calculatedRange)
                            } else {
                                attributedString.addAttribute(.link, value: link.url, range: link.calculatedRange)
                            }
                        }
                        
                        self?.textsWithLinks[rant.id] = attributedString
                    }
                    
                    for comment in comments {
                        if comment.attachedImage == nil {
                            //commentImages.append(nil)
                            self?.commentImages[comment.id] = nil
                        } else {
                            self?.commentImages[comment.id] = File.loadFile(image: comment.attachedImage!, size: CGSize(width: comment.attachedImage!.width, height: comment.attachedImage!.height))
                        }
                        
                        if comment.links != nil {
                            let links = comment.links!
                            
                            let attributedString = NSMutableAttributedString(string: comment.body)
                            
                            attributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: (comment.body as NSString).range(of: comment.body))
                            
                            attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: (comment.body as NSString).range(of: comment.body))
                            
                            for link in links {
                                attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .semibold), range: link.calculatedRange)
                                
                                if link.type == "mention" {
                                    attributedString.addAttribute(.link, value: "mention://\(link.url)", range: link.calculatedRange)
                                } else {
                                    attributedString.addAttribute(.link, value: link.url, range: link.calculatedRange)
                                }
                            }
                            
                            self?.textsWithLinks[comment.id] = attributedString
                        }
                    }
                    
                    SwiftRant.shared.getProfileFromID(rant.userID, token: nil, userContentType: .rants, skip: 0) { profileFetchError, profile in
                        if let profile = profile {
                            self?.profile = profile
                            
                            if self?.rant?.attachedImage != nil && self?.supplementalRantImage == nil {
                                self?.supplementalRantImage = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                            }
                            
                            if self?.rant?.userAvatarLarge.avatarImage != nil {
                                self?.ranterProfileImage = UIImage().loadFromWeb(url: URL(string: "https://avatars.devrant.com/\(rant.userAvatarLarge.avatarImage!)")!)
                            }
                            
                            DispatchQueue.main.async {
                                self?.didFinishLoading = true
                                self?.loadingIndicator.stopAnimating()
                                self?.tableView.isHidden = false
                                
                                self?.tableView.dataSource = self
                                self?.tableView.delegate = self
                                self?.tableView.register(UINib(nibName: "RantCell", bundle: nil), forCellReuseIdentifier: "RantCell")
                                self?.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
                                
                                self?.tableView.reloadData {
                                    self?.loadCompletionHandler?(self)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self?.showAlertWithError(profileFetchError ?? "An unknown error occurred while fetching the user's profile.", retryHandler: nil)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showAlertWithError(error ?? "An unknown error occurred while fetching the rant.", retryHandler: nil)
                    }
                }
            }*/
            
            /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.global(qos: .userInitiated).sync {
                    self.getRant()
                    
                    if self.rant != nil {
                        let completionSemaphore = DispatchSemaphore(value: 0)
                        
                        self.getProfile(successHandler: {
                            completionSemaphore.signal()
                        })
                        
                        completionSemaphore.wait()
                        if self.rant!.attachedImage != nil && self.supplementalRantImage == nil {
                            self.supplementalRantImage = File.loadFile(image: self.rant!.attachedImage!, size: CGSize(width: self.rant!.attachedImage!.width, height: self.rant!.attachedImage!.height))
                        }
                        
                        /*if self.supplementalRantImage == nil && self.doesSupplementalImageExist == true {
                            self.supplementalRantImage = File.loadFile(image: self.rant!.attached_image!, size: CGSize(width: self.rant!.attached_image!.width!, height: self.rant!.attached_image!.height!))
                        }*/
                        
                        if self.rant!.userAvatarLarge.avatarImage != nil {
                            self.getRanterImage()
                        }
                        
                        DispatchQueue.main.async {
                            self.didFinishLoading = true
                            self.loadingIndicator.stopAnimating()
                            //self.loadingIndicator.superview?.removeFromSuperview()
                            self.tableView.isHidden = false
                            
                            self.tableView.dataSource = self
                            self.tableView.delegate = self
                            //self.tableView.register(RantCell.self, forCellReuseIdentifier: "RantCell")
                            self.tableView.register(UINib(nibName: "RantCell", bundle: nil), forCellReuseIdentifier: "RantCell")
                            //self.tableView.register(CommentCell.self, forCellReuseIdentifier: "CommentCell")
                            self.tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
                            
                            self.tableView.reloadData {
                                self.loadCompletionHandler?(self)
                            }
                        }
                    }
                }
            }*/
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
            print("RUNNING AS EXTENDED")
            extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = 1
            self.navigationController?.navigationBar.backgroundView?.alpha = 1
        } else {
            print("RUNNING AS NORMAL")
            self.navigationController?.navigationBar.backgroundView?.alpha = 1
            self.navigationController?.navigationBar.visualEffectView?.alpha = 1
            self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = 1
        }
        
        self.navigationController?.navigationBar.tintColor = UIButton().tintColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        print("WILL APPEAR")
    }
    
    func reloadData(completion: ((UITableView?) -> Void)?) {
        tableView.reloadData()
        
        completion?(tableView)
    }
    
    private func getRanterImage() {
        let completionSemaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: URL(string: "https://avatars.devrant.com/\(self.rant!.userAvatarLarge.avatarImage!)")!) { data, _, _ in
            self.ranterProfileImage = UIImage(data: data!)
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return
    }
    
    /*func getRant() {
        do {
            let response = try APIRequest().getRantFromID(id: self.rantID!, lastCommentID: nil)
            self.rant = response!.rant
            self.comments = (!response!.comments.isEmpty ? response!.comments : [])
            
            for comment in response!.comments {
                if comment.attached_image == nil {
                    //commentImages.append(nil)
                    commentImages[comment.id] = nil
                } else {
                    /*let completionSemaphore = DispatchSemaphore(value: 0)
                    
                    var image = UIImage()
                    
                    URLSession.shared.dataTask(with: URL(string: comment.attached_image!.url!)!) { data, _, _ in
                        image = UIImage(data: data!)!
                        
                        completionSemaphore.signal()
                    }.resume()
                    
                    completionSemaphore.wait()
                    let resizeMultiplier = self.getImageResizeMultiplier(imageWidth: image.size.width, imageHeight: image.size.height, multiplier: 1)
                    
                    let finalSize = CGSize(width: image.size.width / resizeMultiplier, height: image.size.height / resizeMultiplier)
                    
                    UIGraphicsBeginImageContextWithOptions(finalSize, false, resizeMultiplier)
                    image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: finalSize))
                    let newImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()*/
                    
                    self.commentImages[comment.id] = File.loadFile(image: comment.attached_image!, size: CGSize(width: comment.attached_image!.width!, height: comment.attached_image!.height!))
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showAlertWithError("Could not fetch rant with ID \(self.rantID!)", retryHandler: self.getRant)
            }
        }
    }*/
    
    /*private func getProfile(successHandler: (() -> Void)?) {
        /*do {
            self.profile = try APIRequest().getProfileFromID(rant!.user_id, userContentType: .rants, skip: 0)?.profile
        } catch {
            DispatchQueue.main.async {
                self.showAlertWithError("Could not fetch profile with ID \(self.rant!.user_id)", retryHandler: self.getProfile)
            }
        }*/
        
        APIRequest().getProfileFromID(rant!.user_id, userContentType: .rants, skip: 0, completionHandler: { result in
            if let profile = result {
                self.profile = profile.profile
                
                successHandler?()
            } else {
                DispatchQueue.main.async {
                    self.showAlertWithError("Could not fetch profile with ID \(self.rant!.user_id)", retryHandler: { self.getProfile(successHandler: successHandler) })
                }
            }
        })
    }*/
    
    fileprivate func showAlertWithError(_ error: String, retryHandler: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: (retryHandler != nil ? { _ in retryHandler!() } : nil)))
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return comments.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        rowHeights[indexPath] = cell.frame.size.height
        
        NotificationCenter.default.post(name: windowResizeNotification, object: nil)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Task {
            await userImageLoader.cancelAllTasks()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantCell") as! RantCell
            
            //cell = RantCell.loadFromXIB() as! RantCell
            cell.configure(with: rant!, userImage: ranterProfileImage, supplementalImage: nil, profile: profile!, parentTableViewController: self, currentDate: currentDate)
            
            cell.delegate = self
            
            //cell.layoutIfNeeded()
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            //cell = CommentCell.loadFromXIB() as! CommentCell
            cell.configure(with: comments[indexPath.row], supplementalImage: nil, parentTableViewController: self, parentTableView: tableView, currentDate: currentDate, allowedToPreview: true)
            
            cell.delegate = self
            
            return cell
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        NotificationCenter.default.post(name: windowResizeNotification, object: nil)
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        /*if index == 0 {
            return PreviewItem(url: tappedRant?.file?.previewItemURL, title: "Picture from \(tappedRant!.rantContents!.username)")
        } else {
            return PreviewItem(url: tappedComment?.file?.previewItemURL, title: "Picture from \(tappedComment!.commentContents!.username)")
        }*/
        
        if tappedComment == nil {
            let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(URL(string: tappedRant!.rantContents.attachedImage!.url)!.lastPathComponent)
            
            try? (temporaryFileURL.pathExtension != "" && temporaryFileURL.pathExtension != "png" ? tappedRant!.supplementalImageView.image!.jpegData(compressionQuality: 1.0) : tappedRant!.supplementalImageView.image!.pngData())!.write(to: temporaryFileURL, options: .atomic)
            
            return PreviewItem(url: temporaryFileURL, title: "Picture from \(tappedRant!.rantContents!.username)")
        } else {
            let temporaryFileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(URL(string: tappedComment!.commentContents.attachedImage!.url)!.lastPathComponent)
            
            try? (temporaryFileURL.pathExtension != "" && temporaryFileURL.pathExtension != "png" ? tappedComment!.supplementalImageView.image!.jpegData(compressionQuality: 1.0) : tappedComment!.supplementalImageView.image!.pngData())!.write(to: temporaryFileURL, options: .atomic)
            
            return PreviewItem(url: temporaryFileURL, title: "Picture from \(tappedComment!.commentContents!.username)")
        }
    }
    
    /*func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: QLPreviewItem) -> Bool {
        guard url.pathExtension != "" else { return false }
        
        if tappedRant != nil {
            do {
                try (url.pathExtension != "png" ? tappedRant!.supplementalImageView.image!.jpegData(compressionQuality: 1.0) : tappedRant!.supplementalImageView.image!.pngData())!.write(to: url, options: .atomic)
                
                return true
            } catch {
                return false
            }
        } else if tappedComment != nil {
            do {
                try (url.pathExtension != "png" ? tappedComment!.supplementalImageView.image!.jpegData(compressionQuality: 1.0) : tappedComment!.supplementalImageView.image!.pngData())!.write(to: url, options: .atomic)
            } catch {
                return false
            }
        }
        
        return false
    }*/
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        if tappedComment == nil {
            return tappedRant?.supplementalImageView
        } else {
            return tappedComment?.supplementalImageView
        }
    }
    
    /*func previewController(_ controller: QLPreviewController, frameFor item: QLPreviewItem, inSourceView view: AutoreleasingUnsafeMutablePointer<UIView?>) -> CGRect {
        //print("SOURCE VIEW WIDTH:  \(view.pointee!.frame.size.width)")
        //print("SOURCE VIEW HEIGHT: \(view.pointee!.frame.size.height)")
        
        
        
        if tappedComment == nil {
            print("IMAGE VIEW FRAME: \(tappedRant!.supplementalImageView.frame)")
            return (tappedRant?.supplementalImageView.frame)!
        } else {
            print("IMAGE VIEW FRAME: \(tappedComment!.supplementalImageView.frame)")
            return (tappedComment?.supplementalImageView.frame)!
        }
    }*/
    
    func previewController(_ controller: QLPreviewController, transitionImageFor item: QLPreviewItem, contentRect: UnsafeMutablePointer<CGRect>) -> UIImage? {
        if tappedComment == nil {
            contentRect.pointee = tappedRant!.convert(tappedRant!.supplementalImageView.frame, to: tableView)
            return tappedRant?.supplementalImageView.image
        } else {
            contentRect.pointee = tappedComment!.convert(tappedComment!.supplementalImageView.frame, to: tableView)
            return tappedComment?.supplementalImageView.image
        }
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        let tempURL = previewController(controller, previewItemAt: 0).previewItemURL!
        
        try? FileManager.default.removeItem(at: tempURL)
        
        tappedRant = nil
        tappedComment = nil
    }
    
    private func getImageResizeMultiplier(imageWidth: CGFloat, imageHeight: CGFloat, multiplier: Int) -> CGFloat {
        if imageWidth / CGFloat(multiplier) < 315 && imageHeight / CGFloat(multiplier) < 420 {
            return CGFloat(multiplier)
        } else {
            return getImageResizeMultiplier(imageWidth: imageWidth, imageHeight: imageHeight, multiplier: multiplier + 2)
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if parent == nil {
            profile = nil
            comments.removeAll()
            commentImages.removeAll()
            supplementalRantImage = nil
            ranterProfileImage = nil
            rant = nil
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        tappedRant = nil
        tappedComment = nil
        supplementalRantImage = nil
        commentImages = [:]
        rant = nil
        comments = []
        profile = nil
        ranterProfileImage = nil
        textsWithLinks = [:]
        loadCompletionHandler = nil
        
        didFinishLoading = false
        
        //tableView.reloadData()
        tableView.isHidden = true
        
        viewDidAppear(false)
    }
    
    @IBAction func compose(_ sender: Any) {
        let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
        (composeVC.viewControllers.first as! ComposeViewController).rantID = rantID
        (composeVC.viewControllers.first as! ComposeViewController).isEdit = false
        (composeVC.viewControllers.first as! ComposeViewController).isComment = true
        (composeVC.viewControllers.first as! ComposeViewController).viewControllerThatPresented = self
        
        composeVC.isModalInPresentation = true
        
        present(composeVC, animated: true, completion: nil)
    }
    
    @IBAction func goBack(_ sender: Any) {
        if type(of: navigationController?.viewControllers.first!) == NotificationsTableViewController.self {
            performSegue(withIdentifier: "unwindToNotifications", sender: self)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc func fixNavigationBar() {
        if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
            print("RUNNING AS EXTENDED")
            extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = 1
            self.navigationController?.navigationBar.backgroundView?.alpha = 1
        } else {
            print("RUNNING AS NORMAL")
            navigationController?.navigationBar.backgroundView?.alpha = 1
            navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = 1
        }
        
        self.navigationController?.navigationBar.tintColor = UIButton().tintColor
    }
    
    // MARK: - Feed Delegate
    
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantCell) {
        SwiftRant.shared.voteOnRant(nil, rantID: id, vote: vote) { [weak self] result in
            if case .success(let updatedRant) = result {
                /*if let rantInFeed = self?.rantInFeed {
                    rantInFeed.pointee.voteState = vote
                    rantInFeed.pointee.score = updatedRant.score
                }*/
                
                self?.rant?.voteState = updatedRant.voteState
                self?.rant?.score = updatedRant.score
                
                /*if let parentTableViewController = self?.parentTableViewController {
                    parentTableViewController.rant?.voteState = updatedRant.voteState
                    parentTableViewController.rant?.score = updatedRant.score
                    
                    DispatchQueue.main.async {
                        parentTableViewController.tableView.reloadData()
                    }
                }*/
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    
                    self?.homeFeedDelegate?.changeRantVoteState(rantID: id, voteState: updatedRant.voteState)
                    self?.homeFeedDelegate?.changeRantScore(rantID: id, score: updatedRant.score)
                    
                    self?.homeFeedDelegate?.reloadData()
                    
                    self?.profileFeedDelegate?.setVoteStateForRant(withID: id, voteState: updatedRant.voteState)
                    self?.profileFeedDelegate?.setScoreForRant(withID: id, score: updatedRant.score)
                    
                    self?.profileFeedDelegate?.reloadData()
                    
                    self?.subscribedFeedDelegate?.setVoteStateForRant(withID: id, voteState: updatedRant.voteState)
                    self?.subscribedFeedDelegate?.setScoreForRant(withID: id, score: updatedRant.score)
                    
                    self?.subscribedFeedDelegate?.reloadData()
                    
                    //#error("Implement a Profile Table View Delegate!")
                }
            } else if case .failure(let failure) = result {
                let alertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    //self?.parentTableViewController?.present(alertController, animated: true, completion: nil)
                    self?.present(alertController, animated: true)
                }
            }
        }
        
        /*if success == nil {
            print("ERROR WHILE UPVOTING")
        } else {
            if rantInFeed != nil {
                rantInFeed!.pointee.voteState = vote
                rantInFeed!.pointee.score = success!.rant.score
            }
            //parentTableViewController?.rant!.voteState = vote
            
            if parentTableViewController != nil {
                parentTableViewController?.rant!.voteState = success!.rant.voteState
                parentTableViewController?.rant!.score = success!.rant.score
            }
            
            if let parentTableViewController = self.parentTableViewController {
                parentTableViewController.tableView.reloadData()
            }
        }*/
    }
    
    func indexOfComment(withID id: Int) -> Int? {
        if let commentIdx = comments.firstIndex(where: { $0.id == id }) {
            return commentIdx
        }
        
        return nil
    }
    
    func didVoteOnComment(withID id: Int, vote: VoteState, cell: CommentCell) {
        let commentIndex = indexOfComment(withID: id)
        
        guard let commentIndex = commentIndex else {
            let alertController = UIAlertController(title: "Error", message: "Could not find comment in comment list. This looks like a bug, please file a bug report!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            present(alertController, animated: true)
            
            return
        }

        
        SwiftRant.shared.voteOnComment(nil, commentID: id, vote: vote) { result in
            if case .success(let updatedComment) = result {
                /*if let commentInFeed = self.commentInFeed {
                    commentInFeed.pointee.voteState = vote
                    commentInFeed.pointee.score = updatedComment.score
                }*/
                
                self.comments[commentIndex].voteState = updatedComment.voteState
                self.comments[commentIndex].score = updatedComment.score
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
                    self.profileFeedDelegate?.setVoteStateForComment(withID: id, voteState: updatedComment.voteState)
                    self.profileFeedDelegate?.setScoreForComment(withID: id, score: updatedComment.score)
                    
                    self.profileFeedDelegate?.reloadData()
                    
                    //#error("Implement a Profile Table View Delegate!")
                }
                
                /*if let idx = (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent.firstIndex(where: {
                    $0.id == self.commentContents!.id
                }) {
                    (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].voteState = updatedComment.voteState
                    (self.parentTableViewController as? ProfileTableViewController)?.commentTypeContent.commentTypeContent[idx].score = updatedComment.score
                } else if let idx = (self.parentTableViewController as? RantViewController)?.comments.firstIndex(where: {
                    $0.id == self.commentContents!.id
                }) {
                    (self.parentTableViewController as? RantViewController)?.comments[idx].voteState = updatedComment.voteState
                    (self.parentTableViewController as? RantViewController)?.comments[idx].score = updatedComment.score
                }
                
                DispatchQueue.main.async {
                    self.parentTableView?.reloadData()
                }*/
            } else if case .failure(let failure) = result {
                let alertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                //alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.handleDownvote(sender) }))
                
                alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.didVoteOnComment(withID: id, vote: vote, cell: cell) }))
                
                DispatchQueue.main.async {
                    //parentTableViewController.present(alertController, animated: true, completion: nil)
                    
                    self.present(alertController, animated: true)
                }
            }
        }
    }
    
    func changeRantVoteState(voteState: VoteState) {
        rant?.voteState = voteState
    }
    
    func changeRantScore(score: Int) {
        rant?.score = score
    }
    
    func changeCommentVoteState(commentID id: Int, voteState: VoteState) {
        comments[comments.firstIndex(where: { $0.id == id })!].voteState = voteState
        //comments.first(where: { $0.id == id })?.voteState = voteState
    }
    
    func changeCommentScore(commentID id: Int, score: Int) {
        comments[comments.firstIndex(where: { $0.id == id })!].score = score
        //comments.first(where: { $0.id == id })
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    func didDeleteRant(withID id: Int) {
        SwiftRant.shared.deleteRant(nil, rantID: rant!.id) { result in
            if case .success() = result {
                let successAlertController = UIAlertController(title: "Success", message: "Rant successfully deleted!", preferredStyle: .alert)
                
                successAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                DispatchQueue.main.async {
                    let navigationController = self.navigationController
                    
                    self.navigationController?.popViewController(animated: true) {
                        
                        navigationController?.topViewController?.present(successAlertController, animated: true, completion: nil)
                    }
                }
            } else if case .failure(let failure) = result {
                let failureAlertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                //failureAlertController.addAction(UIAlertAction(title: "Retry", style: .destructive, handler: { _ in self.delete() }))
                
                DispatchQueue.main.async {
                    self.title = "Rant"
                    self.navigationItem.leftBarButtonItem?.isEnabled = true
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    
                    self.navigationItem.rightBarButtonItems![0].isEnabled = true
                    self.navigationItem.rightBarButtonItems![1].isEnabled = true
                    
                    self.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func didDeleteComment(withID id: Int, cell: CommentCell) {
        let originalColor = navigationController?.navigationBar.tintColor
        
        navigationController?.navigationBar.isUserInteractionEnabled = false
        navigationController?.navigationBar.tintColor = UIColor.systemGray
        
        SwiftRant.shared.deleteComment(nil, commentID: id) { result in
            if case .success() = result {
                let commentIdx = self.comments.firstIndex(where: {
                    $0.id == id
                })!
                
                self.comments.remove(at: commentIdx)
                self.commentImages[id] = nil
                
                DispatchQueue.main.async {
                    self.title = "Rant"
                    self.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.navigationController?.navigationBar.tintColor = originalColor
                    
                    self.tableView.deleteRows(at: [IndexPath(row: commentIdx, section: 1)], with: .fade)
                }
            } else if case .failure(let failure) = result {
                let failureAlertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                DispatchQueue.main.async {
                    self.title = "Rant"
                    self.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.navigationController?.navigationBar.tintColor = originalColor
                    
                    self.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }
    }
}

extension RantViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool {
        if let rant = self.rant {
            if rant.weekly != nil {
                return true
            }
        }
        
        return false
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL? = nil, title: String? = nil) {
        previewItemURL = url
        previewItemTitle = title
    }
}
