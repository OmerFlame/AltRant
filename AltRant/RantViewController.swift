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
}

actor UserImageLoader {
    private var store: UserImageStore
    private let urlSession: URLSession
    private var activeTasks = [Int: Task<UIImage, Error>]()
    
    init(store: UserImageStore) {
        self.store = store
        urlSession = URLSession(configuration: .default)
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
            
            let (profileRetrieveError,profile) = await SwiftRant.shared.getProfileFromID(id, token: nil, userContentType: .rants, skip: 0)
            
            if let profile = profile, profileRetrieveError == nil {
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
            } else {
                throw profileRetrieveError ?? String("An unknown error has occurred while attempting to retrieve the user's profile.")
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
            
            let (data, _) = try await urlSession.data(from: url)
            let image = UIImage(data: data)!
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
}

protocol RantViewControllerDelegate {
    func vote(_ rantViewController: RantViewController, vote: Int)
}

class RantViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    var delegate: RantViewControllerDelegate?
    
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
    var rantInFeed: UnsafeMutablePointer<RantInFeed>?
    var commentInFeed: UnsafeMutablePointer<Comment>?
    //var doesSupplementalImageExist = false
    
    @MainActor var loadCompletionHandler: ((RantViewController?) -> Void)?
    
    var rowHeights = [IndexPath:CGFloat]()
    
    var textsWithLinks = [Int:NSAttributedString]()
    
    let userImageStore = UserImageStore()
    var userImageLoader: UserImageLoader!
    
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
        
        /*if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
            print("RUNNING AS EXTENDED")
            extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = 1
            self.navigationController?.navigationBar.backgroundView?.alpha = 1
        } else {
            print("RUNNING AS NORMAL")
            navigationController?.navigationBar.backgroundView?.alpha = 1
            navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = 1
        }*/
        
        //navigationController?.navigationBar.tintColor = UIButton().tintColor
        
        if didFinishLoading == false {
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
            
            /*DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.loadingIndicator.stopAnimating()
                self.tableView.isHidden = false
                
                //let headerRant = RantCell.loadFromXIB() as! RantCell
                //headerRant.testConfigure()
                
                //self.tableView.tableHeaderView = headerRant
                
                self.tableView.dataSource = self
                self.tableView.register(RantCell.self, forCellReuseIdentifier: "RantCell")
                self.tableView.reloadData()
            }*/
            
            Task {
                let (error, rant, comments) = await SwiftRant.shared.getRantFromID(token: nil, id: rantID!, lastCommentID: nil)
                
                if let rant = rant, let comments = comments {
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
                            }
                        } else {
                            await self.userImageStore.store(userID: comment.userID, image: UIImage(color: UIColor(hexString: comment.userAvatar.backgroundColor)!, size: CGSize(width: 45, height: 45))!)
                        }
                        
                        if comment.attachedImage == nil {
                            //commentImages.append(nil)
                            self.commentImages[comment.id] = nil
                        } else {
                            self.commentImages[comment.id] = File.loadFile(image: comment.attachedImage!, size: CGSize(width: comment.attachedImage!.width, height: comment.attachedImage!.height))
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
                            
                            self.textsWithLinks[comment.id] = attributedString
                        }
                    }
                    
                    let (profileFetchError, profile) = await SwiftRant.shared.getProfileFromID(rant.userID, token: nil, userContentType: .rants, skip: 0)
                    
                    if let profile = profile {
                        self.profile = profile
                        
                        if self.rant?.attachedImage != nil && self.supplementalRantImage == nil {
                            self.supplementalRantImage = File.loadFile(image: rant.attachedImage!, size: CGSize(width: rant.attachedImage!.width, height: rant.attachedImage!.height))
                        }
                        
                        if self.rant?.userAvatarLarge.avatarImage != nil {
                            self.ranterProfileImage = UIImage().loadFromWeb(url: URL(string: "https://avatars.devrant.com/\(rant.userAvatarLarge.avatarImage!)")!)
                        }
                        
                        await userImageLoader.waitUntilAllTasksAreFinished()
                        
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
                    } else {
                        self.showAlertWithError(profileFetchError ?? "An unknown error occurred while fetching the user's profile.", retryHandler: nil)
                    }
                } else {
                    self.showAlertWithError(error ?? "An unknown error occurred while fetching the rant.", retryHandler: nil)
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
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantCell") as! RantCell
            
            //cell = RantCell.loadFromXIB() as! RantCell
            cell.configure(with: rant!, rantInFeed: rantInFeed, userImage: ranterProfileImage, supplementalImage: supplementalRantImage, profile: profile!, parentTableViewController: self)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            //cell = CommentCell.loadFromXIB() as! CommentCell
            cell.configure(with: comments[indexPath.row], supplementalImage: commentImages[comments[indexPath.row].id] ?? nil, parentTableViewController: self, parentTableView: tableView, commentInFeed: (commentInFeed != nil && commentInFeed!.pointee.id == comments[indexPath.row].id ? commentInFeed : nil), allowedToPreview: true)
            
            return cell
        }
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        /*if index == 0 {
            return PreviewItem(url: tappedRant?.file?.previewItemURL, title: "Picture from \(tappedRant!.rantContents!.username)")
        } else {
            return PreviewItem(url: tappedComment?.file?.previewItemURL, title: "Picture from \(tappedComment!.commentContents!.username)")
        }*/
        
        if tappedComment == nil {
            return PreviewItem(url: tappedRant?.file?.previewItemURL, title: "Picture from \(tappedRant!.rantContents!.username)")
        } else {
            return PreviewItem(url: tappedComment?.file?.previewItemURL, title: "Picture from \(tappedComment!.commentContents!.username)")
        }
    }
    
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
            return tappedRant?.supplementalImageView.image
        } else {
            return tappedComment?.supplementalImageView.image
        }
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
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
}

extension RantViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool { return false }
}

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL? = nil, title: String? = nil) {
        previewItemURL = url
        previewItemTitle = title
    }
}
