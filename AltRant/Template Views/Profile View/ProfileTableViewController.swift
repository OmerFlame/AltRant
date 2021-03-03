//
//  ProfileTableViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/9/20.
//

import UIKit
//import SwiftUI
//import Combine
import ADNavigationBarExtension

public let secondaryProfilePages: [String] = ["Rants", "++'s", "Comments", "Favorites"]

class commentFeedData {
    var commentTypeContent = [CommentModel]()
}

class ProfileTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    //@IBOutlet weak var headerView: StretchyTableHeaderView!
    var profileData: Profile?
    var userID: Int
    
    var originalBlurRect: CGRect!
    var originalTitleRect: CGRect!
    var originalSmallTitleRect: CGRect!
    var originalTestRect: CGRect!
    
    var segmentedControl: UISegmentedControl!
        
    var testBlurView: UIVisualEffectView!
    var headerTitle: UIStackView!
    var blurView: UIVisualEffectView!
    var scoreRect: UIView!
    var scoreLabel: PaddingLabel!
    
    var currentBlurFrame: CGRect!
    
    var blurViewHeight = NSLayoutConstraint()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var didFinishLoading = false
    
    //var rantTypeContent = [RantInFeed]()
    var rantTypeContent = rantFeedData()
    
    //var commentTypeContent = [CommentModel]()
    var commentTypeContent = commentFeedData()
    
    var currentContentType: ProfileContentTypes = .rants
    
    var rantContentImages = [File?]()
    var commentContentImages = [File?]()
    
    var statusBarHeight: CGFloat = 0.0
    
    private var isFetchAlreadyInProgress = false
    
    init?(coder: NSCoder, userID: Int) {
        self.userID = userID
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.navigationController != nil {
            if !self.navigationController!.isNavigationBarHidden {
                self.navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
        
        guard tableView.tableHeaderView != nil else { return }
        
        let headerGeometry = self.geometry(view: (tableView.tableHeaderView as! StretchyTableHeaderView), scrollView: scrollView)
        let titleGeometry = self.geometry(view: headerTitle, scrollView: scrollView)
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.alpha = CGFloat(sqrt(headerGeometry.largeTitleWeight))
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageContainer.alpha = CGFloat(sqrt(headerGeometry.largeTitleWeight))
        
        let largeTitleOpacity = (max(titleGeometry.largeTitleWeight, 0.5) - 0.5) * 2
        let tinyTitleOpacity = 1 - min(titleGeometry.largeTitleWeight, 0.5) * 2
        
        headerTitle.alpha = CGFloat(sqrt(largeTitleOpacity))
        blurView.contentView.subviews[1].alpha = CGFloat(sqrt(tinyTitleOpacity))
        
        if largeTitleOpacity == 1 {
            if blurView.contentView.gestureRecognizers == nil {
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap(_:)))
                tableView.tableHeaderView!.addGestureRecognizer(gestureRecognizer)
                
                //blurView.contentView.addGestureRecognizer(gestureRecognizer)
                
                //blurView.contentView.isUserInteractionEnabled = true
                //blurView.isUserInteractionEnabled = true
            }
        } else {
            //blurView.contentView.gestureRecognizers!.forEach(blurView.contentView.removeGestureRecognizer)
            tableView.tableHeaderView!.gestureRecognizers!.forEach(tableView.tableHeaderView!.removeGestureRecognizer)
            
            blurView.contentView.isUserInteractionEnabled = false
            blurView.isUserInteractionEnabled = false
        }
        
        if let vfxSubview = blurView.subviews.first(where: {
            String(describing: type(of: $0)) == "_UIVisualEffectSubview"
        }) {
            vfxSubview.backgroundColor = UIColor.systemBackground.withAlphaComponent(0)
        }
        
        if let vfxBackdrop = blurView.subviews.first(where: {
            String(describing: type(of: $0)) == "_UIVisualEffectBackdropView"
        }) {
            vfxBackdrop.alpha = CGFloat(1 - sqrt(titleGeometry.largeTitleWeight))
        }
        
        var blurFrame = blurView.frame
        var titleFrame = headerTitle.frame
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            blurFrame.origin.y = max(originalBlurRect.minY, originalBlurRect.minY + titleGeometry.blurOffset)
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            blurFrame.origin.y = max(originalBlurRect.minY - 36, originalBlurRect.minY + titleGeometry.blurOffset - 36)
        }
        
        //print("BLUR OFFSET: \(titleGeometry.blurOffset)")
        
        if let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height {
            self.statusBarHeight = statusBarHeight
        }
        
        titleFrame.origin.y = originalTitleRect.minY + (413 - self.statusBarHeight)
        
        //print("TITLE OFFSET: \(originalTitleRect.minY + (413 - self.statusBarHeight))")
        
        blurView.frame = blurFrame
        headerTitle.frame = titleFrame
        
        currentBlurFrame = blurView.frame
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).scrollViewDidScroll(scrollView: scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        guard didFinishLoading else { return }
        
        tableView.tableHeaderView = StretchyTableHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 502))
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.backgroundColor = UIColor(hex: profileData!.avatar.b)!
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageContainer.backgroundColor = UIColor(hex: profileData!.avatar.b)!
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.backgroundColor = UIColor(hex: profileData!.avatar.b)!
        
        if profileData!.avatar.i != nil {
            let completionSemaphore = DispatchSemaphore(value: 0)
            var profileImage: UIImage?
            
            URLSession.shared.dataTask(with: URL(string: "https://avatars.devrant.com/" + profileData!.avatar.i!)!) { data, _, _ in
                profileImage = UIImage(data: data!)
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()
            
            if profileImage != nil {
                UIGraphicsBeginImageContextWithOptions(CGSize(width: 382, height: 382), false, CGFloat(profileImage!.size.height / 382))
                profileImage!.draw(in: CGRect(origin: .zero, size: CGSize(width: 382, height: 382)))
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image = newImage
            } else {
                (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image = UIImage(color: UIColor(hex: profileData!.avatar.b)!, size: CGSize(width: 382, height: 382))
            }
        } else {
            (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image = UIImage(color: UIColor(hex: profileData!.avatar.b)!, size: CGSize(width: 382, height: 382))
        }
        
        addTitle()
        
        currentBlurFrame = blurView.frame
        
        tableView.infiniteScrollIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        tableView.infiniteScrollIndicatorMargin = 40
        tableView.infiniteScrollTriggerOffset = 500
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionChanged(_:)), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize), name: NSNotification.Name("WindowDidResize"), object: nil)
        
        //let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap(_:)))
        //blurView.addGestureRecognizer(gestureRecognizer)
        
        //tableView.register(UINib(nibName: "RantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
        //tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
    }
    
    private func canLoadMore() -> Bool {
        switch tableView(tableView, numberOfRowsInSection: 0) {
        case self.profileData!.content.counts.rants,
             self.profileData!.content.counts.upvoted,
             self.profileData!.content.counts.comments,
             self.profileData!.content.counts.favorites:
            return false
            
        default:
            return true
        }
    }
    
    func addTitle() {
        let blurEffect = UIBlurEffect(style: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: UIScreen.main.bounds.size.width, height: 44 + 32)
        
        segmentedControl = UISegmentedControl(items: secondaryProfilePages)
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width - 32, height: 32)
        segmentedControl.apportionsSegmentWidthsByContent = true
        
        segmentedControl.backgroundColor = .systemBackground
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.selectedSegmentTintColor = UIColor(hex: profileData!.avatar.b)!
        
        scoreLabel = PaddingLabel()
        scoreLabel.topInset = 2.5
        scoreLabel.bottomInset = 2.5
        scoreLabel.leftInset = 5
        scoreLabel.rightInset = 5
        scoreLabel.text = "+\(String(profileData!.score))"
        scoreLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        scoreLabel.textColor = .black
        scoreLabel.backgroundColor = .white
        scoreLabel.cornerRadius = 5
        scoreLabel.clipsToBounds = true
        scoreLabel.layer.masksToBounds = true
        
        let smallScoreLabel = PaddingLabel()
        smallScoreLabel.topInset = 2.5
        smallScoreLabel.bottomInset = 2.5
        smallScoreLabel.leftInset = 5
        smallScoreLabel.rightInset = 5
        smallScoreLabel.text = "+\(String(profileData!.score))"
        smallScoreLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        smallScoreLabel.textColor = .black
        smallScoreLabel.backgroundColor = .white
        smallScoreLabel.layer.masksToBounds = true
        smallScoreLabel.clipsToBounds = true
        smallScoreLabel.cornerRadius = 5
        smallScoreLabel.layer.borderWidth = 1
        smallScoreLabel.layer.borderColor = UIColor.black.cgColor
        
        let largeLabelHeight = UIFont.systemFont(ofSize: 34, weight: .black).lineHeight
        let smallLabelHeight = UIFont.systemFont(ofSize: 18, weight: .bold).lineHeight
        
        print("FONT HEIGHT: \(largeLabelHeight.rounded(.up))")
        
        let bigLabelSize = profileData!.username.boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 32 - scoreLabel.intrinsicContentSize.width, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 34, weight: .black)], context: nil).size
        
        let smallLabelSize = profileData!.username.boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 32 - scoreLabel.intrinsicContentSize.width, height: CGFloat.greatestFiniteMagnitude), options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold)], context: nil).size
        
        let largeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bigLabelSize.width, height: largeLabelHeight.rounded(.up)))
        let smallLabel = UILabel(frame: CGRect(x: 0, y: 0, width: smallLabelSize.width, height: smallLabelHeight.rounded(.up)))
        
        largeLabel.text = profileData!.username
        largeLabel.font = .systemFont(ofSize: 34, weight: .black)
        largeLabel.textColor = .white
        largeLabel.adjustsFontSizeToFitWidth = true
        largeLabel.minimumScaleFactor = 0.2
        largeLabel.allowsDefaultTighteningForTruncation = true
        largeLabel.numberOfLines = 1
        
        smallLabel.text = profileData!.username
        smallLabel.font = .systemFont(ofSize: 18, weight: .bold)
        smallLabel.textColor = .label
        smallLabel.adjustsFontSizeToFitWidth = true
        smallLabel.minimumScaleFactor = 0.1
        smallLabel.allowsDefaultTighteningForTruncation = true
        smallLabel.numberOfLines = 1
        
        largeLabel.translatesAutoresizingMaskIntoConstraints = false
        smallLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerTitle = UIStackView(frame: CGRect(x: 0, y: 0, width: largeLabel.frame.size.width + 5 + scoreLabel.intrinsicContentSize.width, height: max(largeLabel.frame.size.height, scoreLabel.intrinsicContentSize.height)))
        
        headerTitle.axis = .horizontal
        headerTitle.alignment = .center
        headerTitle.distribution = .equalCentering
        
        headerTitle.addArrangedSubview(largeLabel)
        headerTitle.addArrangedSubview(scoreLabel)
        
        let smallHeaderTitle = UIStackView(frame: CGRect(x: 0, y: 0, width: smallLabel.frame.size.width + 5 + smallScoreLabel.intrinsicContentSize.width, height: max(smallLabel.frame.size.height, smallScoreLabel.intrinsicContentSize.height)))
        
        smallHeaderTitle.axis = .horizontal
        smallHeaderTitle.alignment = .center
        smallHeaderTitle.distribution = .equalCentering
        
        smallHeaderTitle.addArrangedSubview(smallLabel)
        smallHeaderTitle.addArrangedSubview(smallScoreLabel)
        
        blurView.contentView.addSubview(headerTitle)
        blurView.contentView.addSubview(smallHeaderTitle)
        blurView.contentView.addSubview(segmentedControl)
        tableView.tableHeaderView!.addSubview(blurView)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.heightAnchor.constraint(equalTo: tableView.tableHeaderView!.heightAnchor, constant: -view.window!.windowScene!.statusBarManager!.statusBarFrame.height).isActive = true
        blurView.bottomAnchor.constraint(equalTo: tableView.tableHeaderView!.bottomAnchor).isActive = true
        
        blurView.widthAnchor.constraint(equalTo: (tableView.tableHeaderView! as! StretchyTableHeaderView).containerView.widthAnchor).isActive = true
        
        largeLabel.translatesAutoresizingMaskIntoConstraints = false
        smallLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.leadingAnchor.constraint(equalTo: largeLabel.trailingAnchor, constant: 5).isActive = true
        
        largeLabel.centerYAnchor.constraint(equalTo: largeLabel.superview!.centerYAnchor).isActive = true
        
        smallHeaderTitle.translatesAutoresizingMaskIntoConstraints = false
        smallHeaderTitle.insetsLayoutMarginsFromSafeArea = false
        
        smallScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        smallScoreLabel.leadingAnchor.constraint(equalTo: smallLabel.trailingAnchor, constant: 5).isActive = true
        smallScoreLabel.bottomAnchor.constraint(equalTo: smallLabel.bottomAnchor).isActive = true
        
        smallHeaderTitle.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor).isActive = true
        smallHeaderTitle.heightAnchor.constraint(equalToConstant: max(smallLabel.frame.size.height, smallScoreLabel.intrinsicContentSize.height)).isActive = true
        smallHeaderTitle.widthAnchor.constraint(equalToConstant: smallLabel.frame.size.width + 5 + smallScoreLabel.intrinsicContentSize.width).isActive = true
        smallHeaderTitle.bottomAnchor.constraint(equalTo: segmentedControl.topAnchor, constant: -8).isActive = true
        
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        
        headerTitle.bottomAnchor.constraint(equalTo: segmentedControl.topAnchor, constant: -8).isActive = true
        headerTitle.widthAnchor.constraint(equalToConstant: largeLabel.frame.size.width + 5 + scoreLabel.intrinsicContentSize.width).isActive = true
        
        headerTitle.heightAnchor.constraint(equalToConstant: max(largeLabel.frame.size.height, scoreLabel.intrinsicContentSize.height)).isActive = true
        
        largeLabel.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16).isActive = true
        
        originalBlurRect = blurView.frame
        originalTitleRect = headerTitle.frame
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -8).isActive = true
        
        //segmentedControl.bottomAnchor.constraint(equalTo: (tableView.tableHeaderView! as! StretchyTableHeaderView).containerView.bottomAnchor, constant: -8).isActive = true
        
        //segmentedControl.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width - 32).isActive = true
        segmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16).isActive = true
        
        if let v = tableView.tableHeaderView as? StretchyTableHeaderView {
            v.segControl = segmentedControl
        }
        
        headerTitle.updateConstraints()
        
        scrollViewDidScroll(tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if !didFinishLoading {
            tableView.isHidden = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.global(qos: .userInitiated).sync {
                    self.getContent(contentType: .rants) { result in
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            
                            self.didFinishLoading = true
                            self.profileData = result!.profile
                            self.tableView.isHidden = false
                            self.viewDidLoad()
                            
                            self.rantTypeContent.rantFeed = result!.profile.content.content.rants
                            
                            for i in self.rantTypeContent.rantFeed {
                                if let attachedImage = i.attached_image {
                                    if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url!)!.lastPathComponent).relativePath) {
                                        self.rantContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url!)!.lastPathComponent), size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                                    } else {
                                        self.rantContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                                    }
                                } else {
                                    self.rantContentImages.append(nil)
                                }
                            }
                            
                            self.tableView.reloadData()
                            
                            self.tableView.addInfiniteScroll { tableView -> Void in
                                DispatchQueue.global(qos: .userInitiated).sync {
                                    if self.canLoadMore() {
                                        self.performFetch(contentType: self.currentContentType) {
                                            DispatchQueue.main.async {
                                                tableView.finishInfiniteScroll()
                                            }
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            tableView.finishInfiniteScroll()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if let _ = tableView.tableHeaderView {
                scrollViewDidScroll(tableView)
                tableView.reloadData()
            }
        }
    }
    
    func getContent(contentType: ProfileContentTypes, completion: @escaping ((ProfileResponse?) -> Void)) {
        do {
            let response = try APIRequest().getProfileFromID(self.userID, userContentType: contentType, skip: (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.rantFeed.count : commentTypeContent.commentTypeContent.count))
            completion(response)
        } catch {
            completion(nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if let _ = tableView.tableHeaderView {
            scrollViewDidScroll(tableView)
        }
    }
    
    fileprivate func showAlertWithError(_ error: String, retryHandler: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: (retryHandler != nil ? { _ in retryHandler!() } : nil)))
        present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc func segmentedControlSelectionChanged(_ sender: UISegmentedControl) {
        rantTypeContent.rantFeed = []
        commentTypeContent.commentTypeContent = []
        rantContentImages = []
        commentContentImages = []
        
        tableView.reloadData()
        
        switch sender.selectedSegmentIndex {
        case 0:
            currentContentType = .rants
            performFetch(contentType: .rants, { DispatchQueue.main.async { self.tableView.reloadData() } })
            break
            
        case 1:
            currentContentType = .upvoted
            performFetch(contentType: .upvoted, { DispatchQueue.main.async { self.tableView.reloadData() } })
            break
            
        case 2:
            currentContentType = .comments
            performFetch(contentType: .comments, { DispatchQueue.main.async { self.tableView.reloadData() } })
            break
            
        case 3:
            currentContentType = .favorite
            performFetch(contentType: .favorite, {
                            
                            DispatchQueue.main.async {
                            self.tableView.reloadData()
                
            } })
            break
            
        default:
            fatalError("How the fuck")
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /*if (segmentedControl == nil) || segmentedControl!.selectedSegmentIndex == 0 || segmentedControl!.selectedSegmentIndex == 1 || segmentedControl!.selectedSegmentIndex == 3  {
            return rantTypeContent.rantFeed.count
        } else {
            return commentTypeContent.commentTypeContent.count
        }*/
        
        /*if let segmentedControl = self.segmentedControl {
            switch currentContentType {
            case <#pattern#>:
                <#code#>
            default:
                <#code#>
            }
        } else {
            if let profileData = self.profileData {
                return profileData.content.counts.rants
            } else {
                return 0
            }
        }*/
        
        switch currentContentType {
        case .rants:
            return profileData?.content.counts.rants ?? 0
            
        case .upvoted:
            return profileData?.content.counts.upvoted ?? 0
            
        case .comments:
            return profileData?.content.counts.comments ?? 0
            
        case .favorite:
            return profileData?.content.counts.favorites ?? 0
        default:
            fatalError("wtf is this")
        }
    }
    
    // MARK: - Table View Data Source Prefetching
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: { $0.row >= (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.rantFeed.count : commentTypeContent.commentTypeContent.count) }) {
            print("PREFETCHING!")
            performFetch(contentType: currentContentType, {
                DispatchQueue.main.async {
                    //let indexPathsToReload = Array(Set(self.tableView.indexPathsForVisibleRows ?? []).intersection(indexPaths))
                    
                    /*if !indexPathsToReload.isEmpty {
                        self.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                    } else {
                        self.tableView.reloadData()
                    }*/
                    
                    self.tableView.reloadRows(at: self.tableView.indexPathsForVisibleRows ?? [], with: .automatic)
                }
            })
        }
    }
    
    // MARK: - Miscellaneous utilities
    fileprivate func performFetch(contentType: ProfileContentTypes, _ completionHandler: (() -> Void)?) {
        guard !isFetchAlreadyInProgress else {
            return
        }
        
        isFetchAlreadyInProgress = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.getContent(contentType: contentType) { response in
                guard response != nil else {
                    self.showAlertWithError("Failed to fetch user content.", retryHandler: { self.performFetch(contentType: contentType, completionHandler) })
                    self.isFetchAlreadyInProgress = false
                    return
                }
                
                var start = 0
                var end = 0
                
                switch contentType {
                case .rants:
                    start = self.rantTypeContent.rantFeed.count
                    end = response!.profile.content.content.rants.count + start
                    
                    self.commentTypeContent.commentTypeContent = []
                    break
                    
                case .upvoted:
                    start = self.rantTypeContent.rantFeed.count
                    end = response!.profile.content.content.upvoted.count + start
                    
                    self.commentTypeContent.commentTypeContent = []
                    break
                    
                case .favorite:
                    start = self.rantTypeContent.rantFeed.count
                    end = response!.profile.content.content.favorites!.count + start
                    
                    self.commentTypeContent.commentTypeContent = []
                    break
                    
                default:
                    start = self.commentTypeContent.commentTypeContent.count
                    end = response!.profile.content.content.comments.count + start
                    
                    self.rantTypeContent.rantFeed = []
                    break
                }
                
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                
                switch contentType {
                case .rants:
                    self.rantTypeContent.rantFeed.append(contentsOf: response!.profile.content.content.rants)
                    break
                    
                case .upvoted:
                    self.rantTypeContent.rantFeed.append(contentsOf: response!.profile.content.content.upvoted)
                    break
                    
                case .favorite:
                    self.rantTypeContent.rantFeed.append(contentsOf: response!.profile.content.content.favorites!)
                    break
                    
                default:
                    self.commentTypeContent.commentTypeContent.append(contentsOf: response!.profile.content.content.comments)
                    break
                }
                
                if !self.rantTypeContent.rantFeed.isEmpty {
                    for i in self.rantTypeContent.rantFeed[start..<end] {
                        if let attachedImage = i.attached_image {
                            self.rantContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                        } else {
                            self.rantContentImages.append(nil)
                        }
                    }
                    
                    self.isFetchAlreadyInProgress = false
                    
                    completionHandler?()
                } else {
                    for i in self.commentTypeContent.commentTypeContent[start..<end] {
                        if let attachedImage = i.attached_image {
                            //let completionSemaphore = DispatchSemaphore(value: 0)
                            
                            //var image = UIImage()
                            
                            /*URLSession.shared.dataTask(with: URL(string: attachedImage.url!)!) { data, _, _ in
                                image = UIImage(data: data!)!
                                
                                completionSemaphore.signal()
                            }.resume()
                            
                            completionSemaphore.wait()*/
                            
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url!)!.lastPathComponent).relativePath) {
                                self.commentContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url!)!.lastPathComponent), size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                            } else {
                                self.commentContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                            }
                            //self.commentContentImages.
                        } else {
                            self.commentContentImages.append(nil)
                        }
                    }
                    
                    self.isFetchAlreadyInProgress = false
                    
                    completionHandler?()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            if indexPath.row >= rantTypeContent.rantFeed.count || indexPath.row >= rantContentImages.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! SecondaryRantInFeedCell
                cell.configureLoading()
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! SecondaryRantInFeedCell
                cell.configure(with: &rantTypeContent.rantFeed[indexPath.row], image: rantContentImages[indexPath.row], parentTableViewController: self, parentTableView: tableView)
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            cell.configure(with: commentTypeContent.commentTypeContent[indexPath.row], supplementalImage: commentContentImages[indexPath.row], parentTableViewController: self, parentTableView: tableView, commentInFeed: &commentTypeContent.commentTypeContent[indexPath.row], allowedToPreview: false)
            
            return cell
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        DispatchQueue.global(qos: .userInteractive).async {
            self.shouldUpdateBlurPosition()
        }
    }
    
    func shouldUpdateBlurPosition() {
        DispatchQueue.main.async {
            self.blurView.frame = self.currentBlurFrame
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "rantInFeed", let rantViewController = segue.destination as? RantViewController {
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
            
            rantViewController.rantID = rantTypeContent.rantFeed[indexPath.row].id
            withUnsafeMutablePointer(to: &rantTypeContent.rantFeed[indexPath.row], { pointer in
                rantViewController.rantInFeed = pointer
            })
            
            //rantViewController.rantInFeed = $rantTypeContent.rantFeed[indexPath.row]
            
            rantViewController.supplementalRantImage = rantContentImages[indexPath.row]
            rantViewController.loadCompletionHandler = nil
        } else if segue.identifier == "commentInFeed", let rantViewController = segue.destination as? RantViewController {
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)!
            
            rantViewController.rantID = commentTypeContent.commentTypeContent[indexPath.row].rant_id
            rantViewController.rantInFeed = nil
            
            withUnsafeMutablePointer(to: &commentTypeContent.commentTypeContent[indexPath.row], { pointer in
                rantViewController.commentInFeed = pointer
            })
            
            rantViewController.supplementalRantImage = nil
            rantViewController.loadCompletionHandler = { tableViewController in
                DispatchQueue.global(qos: .userInitiated).async {
                    if let idx = tableViewController!.comments.firstIndex(where: {
                        $0.id == self.commentTypeContent.commentTypeContent[indexPath.row].id
                    }) {
                        DispatchQueue.main.async {
                            tableViewController!.tableView.scrollToRow(at: IndexPath(row: idx, section: 1), at: .middle, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleProfileImageTap(_ sender: UITapGestureRecognizer) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(profileData!.username).png")
        
        try! (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image!.pngData()!.write(to: url)
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in try! FileManager.default.removeItem(at: url) }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func windowDidResize() {
        scrollViewDidScroll(tableView)
        tableView.reloadData()
    }
}

extension ProfileTableViewController {
    struct HeaderGeometry {
        let width: CGFloat
        let headerHeight: CGFloat
        let elementsHeight: CGFloat
        let headerOffset: CGFloat
        let blurOffset: CGFloat
        let elementsOffset: CGFloat
        let largeTitleWeight: Double
    }
    
    func geometry(view: UIView, scrollView: UIScrollView) -> HeaderGeometry {
        let safeArea = scrollView.safeAreaInsets
        
        let minY = -(scrollView.contentOffset.y + scrollView.safeAreaInsets.top)
        
        let hasScrolledUp = minY > 0
        
        let hasScrolledToMinHeight = -minY >= 450 - 47 - safeArea.top

        let headerHeight = hasScrolledUp ?
            (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.frame.size.height + minY + 32 : (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.frame.size.height + 32

        let elementsHeight = (tableView.tableHeaderView as! StretchyTableHeaderView).frame.size.height + minY

        let headerOffset: CGFloat
        let blurOffset: CGFloat
        let elementsOffset: CGFloat
        let largeTitleWeight: Double

        if hasScrolledUp {
            headerOffset = -minY
            blurOffset = -minY
            elementsOffset = -minY
            largeTitleWeight = 1
        } else if hasScrolledToMinHeight {
            headerOffset = -minY - 450 + 47 + safeArea.top
            blurOffset = -minY - 450 + 47 + safeArea.top - 32
            elementsOffset = headerOffset / 2 - minY / 2
            largeTitleWeight = 0
        } else {
            headerOffset = 0
            blurOffset = 0
            elementsOffset = -minY / 2
            let difference = 450 - 47 - safeArea.top + minY
            largeTitleWeight = difference <= 47 + 1 ? Double(difference / (47 + 1)) : 1
        }
        
        return HeaderGeometry(width: (tableView.tableHeaderView as! StretchyTableHeaderView).frame.size.width, headerHeight: headerHeight, elementsHeight: elementsHeight, headerOffset: headerOffset, blurOffset: blurOffset, elementsOffset: elementsOffset, largeTitleWeight: largeTitleWeight)
    }
}

extension ProfileTableViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool { return false }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
