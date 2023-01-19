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
import SwiftRant
import CoreGraphics
import SwiftHEXColors

public let secondaryProfilePages: [String] = ["Rants", "++'s", "Comments", "Favorites"]

class commentFeedData {
    var commentTypeContent = [Comment]()
}

protocol ProfileTableViewControllerDelegate: FeedDelegate {
    func setVoteStateForRant(withID id: Int, voteState: VoteState)
    func setScoreForRant(withID id: Int, score: Int)
    
    func setVoteStateForComment(withID id: Int, voteState: VoteState)
    func setScoreForComment(withID id: Int, score: Int)
    
    func reloadData()
}

protocol PropertyLoopable {
    var allProperties: [String: Any] { get }
}

extension PropertyLoopable {
    var allProperties: [String: Any] {
        get {
            var result: [String: Any] = [:]
            
            let mirror = Mirror(reflecting: self)
            
            guard let style = mirror.displayStyle, style == .struct || style == .class else { return result }
            
            //let style = mirror.displayStyle
            
            for (label, value) in mirror.children {
                guard let label = label else { continue }
                
                result[label] = value
            }
            
            return result
        }
    }
}

extension Profile.UserCounts: PropertyLoopable {
    
}

class PassthroughVisualEffectView: UIVisualEffectView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        return view == self ? nil : view
    }
    
    /*override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.contains(where: { !$0.isHidden && $0.isUserInteractionEnabled && $0.point(inside: self.convert(point, to: $0), with: event) })
    }*/
}

/*extension UIVisualEffectView {
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        //print("UIVISUALEFFECTVIEW IMPLEMENTATION RUNNING")
        //print("TYPE OF VISUAL EFFECT VIEW: \(String(describing: type(of: self)))")
        
        print("HIJACK - HITTEST")
        
        return super.hitTest(point, with: event)
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if type(of: self) == PassthroughVisualEffectView.Type.self {
            print("HIJACK - POINT")
            
            return subviews.contains(where: { !$0.isHidden && $0.isUserInteractionEnabled && $0.point(inside: self.convert(point, to: $0), with: event) })
        } else {
            return super.point(inside: point, with: event)
        }
    }
}*/

/*extension UIVisualEffectView {
    func replaceHitTestImplementation() {
        guard let originalMethod = class_getInstanceMethod(UIVisualEffectView.self, #selector(hitTest(_:with:))),
              let swizzledMethod = class_getInstanceMethod(UIVisualEffectView.self, #selector(swizzledHitTest(_:with:))) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc func swizzledHitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        return view == self ? nil : view
    }
}*/

class ProfileTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ProfileTableViewControllerDelegate {
    //@IBOutlet weak var headerView: StretchyTableHeaderView!
    var profileData: Profile?
    var shouldLoadFromUsername = false
    var username: String?
    var userID: Int?
    
    var originalBlurRect: CGRect!
    var originalTitleRect: CGRect!
    //var originalSmallTitleRect: CGRect!
    var originalTestRect: CGRect!
    
    var segmentedControl: UISegmentedControl!
        
    var testBlurView: UIVisualEffectView!
    var headerTitle: UIStackView!
    var smallHeaderTitle: UIStackView!
    var blurView: UIVisualEffectView!
    var scoreRect: UIView!
    var scoreLabel: PaddingLabel!
    
    var currentBlurFrame: CGRect!
    
    //var blurViewHeight = NSLayoutConstraint()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var didFinishLoading = false
    
    var rantTypeContent = [RantInFeed]()
    //var rantTypeContent = rantFeedData()
    
    //var commentTypeContent = [CommentModel]()
    var commentTypeContent = commentFeedData()
    
    var currentContentType: Profile.ProfileContentTypes = .rants
    
    var rantContentImages = [File?]()
    var commentContentImages = [File?]()
    
    var statusBarHeight: CGFloat = 0.0
    
    private var isFetchAlreadyInProgress = false
    
    private var cellHeights = [IndexPath:CGFloat]()
    
    var currentDate: Date!
    
    let userImageStore = UserImageStore()
    let userImageLoader: UserImageLoader!
    
    var shouldModifyNavigationBar = true
    
    var defaultNavigationBarScrollEdgeAppearance: UINavigationBarAppearance?
    
    init?(coder: NSCoder, userID: Int?) {
        self.userID = userID
        self.userImageLoader = UserImageLoader(store: userImageStore)
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows, indexPathsForVisibleRows.contains(IndexPath(row: 0, section: 1)) && !isFetchAlreadyInProgress && tableView(tableView, numberOfRowsInSection: 0) > 0 {
            let currentCellCount = tableView(tableView, numberOfRowsInSection: 0)
            
            performFetch(contentType: currentContentType, {
                let indexPathsToInsert = ((currentCellCount)...(self.tableView(self.tableView, numberOfRowsInSection: 0) - 1)).map { IndexPath(row: $0, section: 0) }
                
                DispatchQueue.main.async {
                    self.tableView.insertRows(at: indexPathsToInsert, with: .none)
                    
                    /*UIView.performWithoutAnimation {
                        self?.scrollViewDidScroll(scrollView)
                    }*/
                    
                    //self?.tableView.insertRows(at: indexPathsToInsert, with: .none)
                    //self?.tableView.setContentOffset(scrollView.contentOffset, animated: false)
                    
                    self.tableView.reloadData()
                    self.scrollViewDidScroll(self.tableView)
                    
                    return
                    //self.tableView.reloadData()
                }
            })
        }
        
        // If this function runs and the header view property is nil, return immediately.
        guard tableView.tableHeaderView != nil, navigationController != nil else { return }
        
        // Get the CGRect of the OS's status bar. If it returns nil, then just assign a 0-length, 0-origin CGRect to the variable.
        let statusBarFrame = UIApplication.shared.windows[0].windowScene?.statusBarManager?.statusBarFrame ?? .zero
        
        // The amount that you need to scroll when you pass the scrolling threshold to finish a full effect cycle of the navigation bar show/hide animation.
        let targetHeight: CGFloat = 21
        
        /* The amount that you need to scroll in order to start the actual effect of the navigation bar. This variable's value will be different between form factors.
         * This variable consists of the height of the table view header, subtracting the full height + the vertical offset of the navigation bar, subtracting the height of the large header title, subtracting twice the half of the height of the blur view for the UISegmentedControl.
         */
        var thresholdHeight = tableView.tableHeaderView!.frame.size.height - navigationController!.navigationBar.frame.maxY - headerTitle.frame.size.height - 2 * (blurView.frame.size.height - 21)
        
        // Because of the complexity of the last line, the Swift compiler is complaining that the line is too complicated if we also add 63 to the equation, so I added it on a different line.
        // I absolutely cannot recall why I am adding 63 to the threshold height, but I need to.
        thresholdHeight += 63
        
        // Calculate how much of the header (including the animation) you scrolled.
        var offset = ((scrollView.contentOffset.y - thresholdHeight) / targetHeight)
        
        // The offset of the segmented control relative to the scroll view's vertical offset, adding the top safe area insets of the scroll view, subtracting 21 and diving the result by -1.
        let visualEffectViewOffset = -(scrollView.contentOffset.y + scrollView.safeAreaInsets.top - 21)
        
        // Get the current CGRect of the blur view that contains the segmented control.
        var blurFrame = blurView.frame
        
        /* Set the origin's Y coordinate of the blur view to the biggest value out of the 2: the original blur view's CGRect minimum Y coordinate subtracting half the height of the blur view OR the negative of the blur view's offset, because the more you scroll down, the higher the visualEffectViewOffset will be because in the Core Graphics coordinate space, the closer you get to the bottom edge of the screen the bigger the Y coordinate is.
         *
         * The reason we are doing this is because we want the blur view to always stick to the navigation bar if we scroll past the header view, so the user can switch between the different profile post types even if they are not at the top of the scroll view.
         */
        blurFrame.origin.y = max(originalBlurRect.minY - 21, -visualEffectViewOffset)
        
        // Set the current frame of the blur view to the new blur frame with the newly-calculated offset.
        blurView.frame = blurFrame
        
        // Set the property's value to the current blur view's CGRect frame.
        currentBlurFrame = blurView.frame
        
        // If the offset that we calculated earlier is bigger than 1, set it to 1.
        if offset > 1 { offset = 1 }
        
        // If the offset that we calculated earlier is smaller than 0, set it to 0.
        if offset < 0 { offset = 0 }
        
        // Change the tint color of the navigation bar to a color between white and the profile's background color, depending on how much we scroll.
        
        if shouldModifyNavigationBar {
            navigationController?.navigationBar.tintColor = blend(from: .white, to: UIColor(hexString: profileData!.avatar.backgroundColor)!, percent: Double(sqrt(offset)))
        }
        
        // Set the opacity of the custom title view of the navigation bar to the square root of the offset.
        if offset > 0 {
            navigationItem.titleView = smallHeaderTitle
        } else {
            navigationItem.titleView = nil
        }
        smallHeaderTitle?.alpha = sqrt(offset)
        navigationItem.titleView?.alpha = sqrt(offset)
        
        if shouldModifyNavigationBar {
            /* In here, we start to meddle with private views inside the navigation bar that provide the blur effect that the navigation bar has.
             *
             * We set the opacity of the navigation bar's private background and visual effect views to the square root of the offset we calculated earlier.
             */
            
            navigationController?.navigationBar.backgroundView?.alpha = sqrt(offset)
            navigationController?.navigationBar.visualEffectView?.alpha = sqrt(offset)
            
            // Set the opacity of one of the private views of the navigation bar's visual effect view. We search the subviews of the visual effect view for a view that has this private class name and the first one that pops up is the only one that exists. We set that view's alpha to the square root of the offset we calculated earlier.
            self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
            
            // If the user pushed this view controller into view through the notifications view controller, the structure of the navigation bar is different, so we need to set the opacity of the background of the UIToolbar that the extended navigation view has (which is a private Apple view as well) to the square root of the offset that we calculated earlier.
            if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
                extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = sqrt(offset)
            }
        }
        
        // We repeat the same procedures above on more private Apple views that are inside the blur view for the segmented control.
        
        blurView.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
        //blurView.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" })?.alpha = sqrt(offset)
        
        blurView.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" })?.alpha = offset == 1 ? 1 : 0
        
        // We set the opacity of the header view's container view and image container, as well as the header title to the square root of 1 subtracted by the offset we calculated earlier.
        //(tableView.tableHeaderView as! StretchyTableHeaderView).containerView.alpha = sqrt(1 - offset)
        //(tableView.tableHeaderView as! StretchyTableHeaderView).imageContainer.alpha = sqrt(1 - offset)
        (tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView.alpha = 1
        (tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" })?.alpha = sqrt(offset)
        (tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
        
        headerTitle.alpha = sqrt(1 - offset)
        
        // Completely hide the header title if the opacity is 0, and don't hide it if not.
        if headerTitle.alpha == 0 {
            headerTitle.isHidden = true
        } else {
            headerTitle.isHidden = false
        }
        
        blurView.alpha = 1
        
        // If the effect hasn't started yet, add a gesture recognizer to the profile image. If it's started, remove the gesture recognizer.
        if 1 - offset == 1 {
            if blurView.contentView.gestureRecognizers == nil {
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap(_:)))
                tableView.tableHeaderView!.addGestureRecognizer(gestureRecognizer)
            }
            
            /*if (tableView.tableHeaderView! as! StretchyTableHeaderView).imageView.gestureRecognizers == nil {
                //let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap(_:)))
                //(tableView.tableHeaderView! as! StretchyTableHeaderView).imageView.addGestureRecognizer(gestureRecognizer)
                
                (tableView.tableHeaderView! as! StretchyTableHeaderView).imageView.isUserInteractionEnabled = true
                
                //(tableView.tableHeaderView! as! StretchyTableHeaderView).maskBlurView?.isHidden = true
                //(tableView.tableHeaderView! as! StretchyTableHeaderView).maskBlurView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" })?.isHidden = true
                
                (tableView.tableHeaderView! as! StretchyTableHeaderView).maskBlurView?.isUserInteractionEnabled = false
                
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap(_:)))
                //(tableView.tableHeaderView! as! StretchyTableHeaderView).maskBlurView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" })?.isUserInteractionEnabled = true
            }*/
        } else {
            //blurView.contentView.gestureRecognizers!.forEach(blurView.contentView.removeGestureRecognizer)
            /*tableView.tableHeaderView!.gestureRecognizers!.forEach(tableView.tableHeaderView!.removeGestureRecognizer)
            
            blurView.contentView.isUserInteractionEnabled = false
            blurView.isUserInteractionEnabled = false*/
            
            //(tableView.tableHeaderView! as! StretchyTableHeaderView).imageView.gestureRecognizers!.forEach((tableView.tableHeaderView! as! StretchyTableHeaderView).imageView.removeGestureRecognizer)
            
            //(tableView.tableHeaderView! as! StretchyTableHeaderView).maskBlurView?.isHidden = false
            //(tableView.tableHeaderView! as! StretchyTableHeaderView).maskBlurView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" })?.isHidden = false
            
            tableView.tableHeaderView!.gestureRecognizers!.forEach(tableView.tableHeaderView!.removeGestureRecognizer)
            
            blurView.contentView.isUserInteractionEnabled = false
            blurView.isUserInteractionEnabled = false
        }
        
        // Call the header view's scrollViewDidScroll function to handle its layout and effects as well.
        (tableView.tableHeaderView as! StretchyTableHeaderView).scrollViewDidScroll(scrollView: scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.contentInsetAdjustmentBehavior = .never
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundView?.alpha = 0
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 500
        //tableView.rowHeight = UITableView.automaticDimension
        
        //navigationController?.title = ""
        navigationItem.title = ""
        
        guard didFinishLoading else { return }
        
        tableView.tableHeaderView = StretchyTableHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 502))
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.backgroundColor = UIColor(hexString: profileData!.avatar.backgroundColor)!
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageContainer.backgroundColor = UIColor(hexString: profileData!.avatar.backgroundColor)!
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.backgroundColor = UIColor(hexString: profileData!.avatar.backgroundColor)!
        
        tableView.register(UINib(nibName: "RantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
        tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: "LoadingCell")
        
        if profileData!.avatar.avatarImage != nil {
            /*let completionSemaphore = DispatchSemaphore(value: 0)
            var profileImage: UIImage?
            
            URLSession.shared.dataTask(with: URL(string: "https://avatars.devrant.com/" + profileData!.avatar.avatarImage!)!) { data, _, _ in
                profileImage = UIImage(data: data!)
                completionSemaphore.signal()
            }.resume()
            
            completionSemaphore.wait()*/
            
            var request = URLRequest(url: URL(string: "https://avatars.devrant.com/\(profileData!.avatar.avatarImage!)")!)
            request.cachePolicy = .returnCacheDataElseLoad
            
            // hopefully, this is cached.
            let dataTask = URLSession.shared.dataTask(with: request) { data, _, _ in
                if let data = data {
                    
                    if let profileImage = UIImage(data: data) {
                        UIGraphicsBeginImageContextWithOptions(CGSize(width: 382, height: 382), false, CGFloat(profileImage.size.height / 382))
                        profileImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 382, height: 382)))
                        let newImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        DispatchQueue.main.async { [weak self] in
                            (self?.tableView.tableHeaderView as? StretchyTableHeaderView)?.imageView.image = newImage
                        }
                    } else {
                        DispatchQueue.main.async { [weak self] in
                            if let self = self {
                                (self.tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image = UIImage(color: UIColor(hexString: self.profileData!.avatar.backgroundColor)!, size: CGSize(width: 382, height: 382))
                            }
                        }
                    }
                }
            }
            
            dataTask.delegate = self
            
            dataTask.resume()
        } else {
            (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image = UIImage(color: UIColor(hexString: profileData!.avatar.backgroundColor)!, size: CGSize(width: 382, height: 382))
        }
        
        addTitle()
        
        //(tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView = navigationController?.navigationBar.visualEffectView
        
        let copiedView: UIVisualEffectView? = navigationController?.navigationBar.visualEffectView?.copyView() as? UIVisualEffectView
        
        //object_setClass(copiedView, PassthroughVisualEffectView.self)
        
        //let casted: PassthroughVisualEffectView? = copiedView as? PassthroughVisualEffectView
        
        //(tableView.tableHeaderView as! StretchyTableHeaderView).setMaskBlurView(newBlurView: navigationController?.navigationBar.visualEffectView?.copyView())
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).setMaskBlurView(newBlurView: copiedView)
        
        
        (tableView.tableHeaderView! as! StretchyTableHeaderView).imageView.isUserInteractionEnabled = true
        //object_setClass((tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView, PassthroughVisualEffectView.self)
        
       // (tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView.replaceHitTestImplementation()
        
        scrollViewDidScroll(tableView)
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView.isUserInteractionEnabled = false
        
        //tableView.scrollIndicatorInsets.top = tableView.tableHeaderView!.frame.maxY - (navigationController!.navigationBar.frame.size.height + navigationController!.navigationBar.frame.minY)
        
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: tableView.tableHeaderView!.frame.maxY - (navigationController!.navigationBar.frame.size.height + navigationController!.navigationBar.frame.minY))
        
        currentBlurFrame = blurView.frame
        
        /*tableView.infiniteScrollIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        tableView.infiniteScrollIndicatorMargin = 40
        tableView.infiniteScrollTriggerOffset = 500*/
        
        //tableView.contentInset.top = 40
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlSelectionChanged(_:)), for: .valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize), name: NSNotification.Name("WindowDidResize"), object: nil)
        
        //tableView.register(UINib(nibName: "SecondaryRantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
        
        //let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap(_:)))
        //blurView.addGestureRecognizer(gestureRecognizer)
        
        //tableView.register(UINib(nibName: "RantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
        //tableView.register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
    }
    
    /*func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let targetHeight = blurView.frame.size.height
        
        let thresholdHeight = tableView.tableHeaderView!.frame.size.height - navigationController!.navigationBar.frame.size.height - headerTitle.frame.size.height - 2 * blurView.frame.size.height
        
        
        var offset = ((scrollView.contentOffset.y - thresholdHeight) / targetHeight)
        
        if offset > 0 && offset < 1 {
            scrollView.setContentOffset(CGPoint(x: 0, y: thresholdHeight + targetHeight + 21), animated: true)
        }
    }*/
    
    /*func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let targetHeight = blurView.frame.size.height
            
            let thresholdHeight = tableView.tableHeaderView!.frame.size.height - navigationController!.navigationBar.frame.size.height - headerTitle.frame.size.height - 2 * blurView.frame.size.height
            
            
            let offset = ((scrollView.contentOffset.y - thresholdHeight) / targetHeight)
            
            if offset > 0 && offset < 1 {
                scrollView.setContentOffset(CGPoint(x: 0, y: thresholdHeight + targetHeight + 42), animated: true)
            }
        }
    }*/
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        debugPrint("TARGET OFFSET: \(targetContentOffset.pointee)")
        
        let targetHeight: CGFloat = 21
        
        var thresholdHeight = tableView.tableHeaderView!.frame.size.height - navigationController!.navigationBar.frame.maxY - headerTitle.frame.size.height - 2 * (blurView.frame.size.height - 21)
        
        thresholdHeight += 42
        
        //let snapThresholdHeight = tableView.tableHeaderView!.frame.size.height - navigationController!.navigationBar.frame.size.height - headerTitle.frame.size.height - 2 * (blur
        
        var offset = ((scrollView.contentOffset.y - thresholdHeight) / targetHeight)
        
        if (offset > 0 && offset < 1) || (targetContentOffset.pointee.y > thresholdHeight && targetContentOffset.pointee.y < thresholdHeight + targetHeight + 42) {
            targetContentOffset.pointee.y = round(targetContentOffset.pointee.y / (thresholdHeight + targetHeight + 42)) * (thresholdHeight + targetHeight + 21)
        }
    }
    
    /*private func canLoadMore() -> Bool {
        switch tableView(tableView, numberOfRowsInSection: 0) {
        case self.profileData!.content.counts.rants,
             self.profileData!.content.counts.upvoted,
             self.profileData!.content.counts.comments,
             self.profileData!.content.counts.favorites:
            return false
            
        default:
            return true
        }
    }*/
    
    private func canLoadMore() -> Bool {
        let currentRowCount = tableView(tableView, numberOfRowsInSection: 0)
        
        return (profileData?.content.counts.allProperties[currentContentType.rawValue] as! Int?) ?? 0 > currentRowCount
    }
    
    // Add the special title subviews at the top of the screen and set up the constraints.
    func addTitle() {
        blurView = navigationController?.navigationBar.visualEffectView?.copyView()
        
        segmentedControl = UISegmentedControl(items: secondaryProfilePages)
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width - 32, height: 32)
        segmentedControl.apportionsSegmentWidthsByContent = true
        
        segmentedControl.backgroundColor = .systemBackground
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.selectedSegmentTintColor = UIColor(hexString: profileData!.avatar.backgroundColor)!
        
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
        smallScoreLabel.textColor = .systemBackground
        smallScoreLabel.backgroundColor = .label
        smallScoreLabel.layer.masksToBounds = true
        smallScoreLabel.clipsToBounds = true
        smallScoreLabel.cornerRadius = 5
        //smallScoreLabel.layer.borderWidth = 1
        //smallScoreLabel.layer.borderColor = UIColor.black.cgColor
        
        let moreInfoButton = UIButton()
        moreInfoButton.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        moreInfoButton.tintColor = .label
        moreInfoButton.addTarget(self, action: #selector(showMoreInfo), for: .touchUpInside)
        
        moreInfoButton.imageView?.preferredSymbolConfiguration = .init(scale: .large)
        
        moreInfoButton.contentHorizontalAlignment = .left
        
        moreInfoButton.translatesAutoresizingMaskIntoConstraints = false
        
        smallScoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let largeLabelHeight = UIFont.systemFont(ofSize: 34, weight: .black).lineHeight
        let smallLabelHeight = UIFont.systemFont(ofSize: 18, weight: .bold).lineHeight
        
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
        
        let scoreLabelContainerView = UIView()
        scoreLabelContainerView.translatesAutoresizingMaskIntoConstraints = false
        scoreLabelContainerView.addSubview(scoreLabel)
        
        let moreInfoButtonContainerView = UIView()
        moreInfoButtonContainerView.translatesAutoresizingMaskIntoConstraints = false
        moreInfoButtonContainerView.addSubview(moreInfoButton)
        
        headerTitle.addArrangedSubview(largeLabel)
        headerTitle.addArrangedSubview(scoreLabelContainerView)
        headerTitle.addArrangedSubview(moreInfoButtonContainerView)
        //headerTitle.addArrangedSubview(moreInfoButton)
        
        smallHeaderTitle = UIStackView(frame: CGRect(x: 0, y: 0, width: smallLabel.frame.size.width + 5 + smallScoreLabel.intrinsicContentSize.width, height: max(smallLabel.frame.size.height, smallScoreLabel.intrinsicContentSize.height)))
        
        smallHeaderTitle.axis = .horizontal
        smallHeaderTitle.alignment = .center
        smallHeaderTitle.distribution = .equalCentering
        
        smallHeaderTitle.addArrangedSubview(smallLabel)
        smallHeaderTitle.addArrangedSubview(smallScoreLabel)
        
        blurView.contentView.addSubview(segmentedControl)
        
        tableView.tableHeaderView!.addSubview(headerTitle)
        tableView.tableHeaderView!.addSubview(blurView)
        
        //navigationItem.titleView = smallHeaderTitle
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        segmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        //segmentedControl.heightAnchor.constraint(equalTo: blurView.heightAnchor, constant: -8).isActive = true
        
        segmentedControl.heightAnchor.constraint(equalTo: blurView.heightAnchor, constant: -29).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16).isActive = true
        segmentedControl.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -8).isActive = true
        segmentedControl.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor).isActive = true
        
        blurView.bottomAnchor.constraint(equalTo: tableView.tableHeaderView!.bottomAnchor).isActive = true
        blurView.leadingAnchor.constraint(equalTo: tableView.tableHeaderView!.leadingAnchor).isActive = true
        blurView.trailingAnchor.constraint(equalTo: tableView.tableHeaderView!.trailingAnchor).isActive = true
        
        largeLabel.translatesAutoresizingMaskIntoConstraints = false
        smallLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabelContainerView.heightAnchor.constraint(equalTo: headerTitle.heightAnchor).isActive = true
        moreInfoButtonContainerView.heightAnchor.constraint(equalTo: headerTitle.heightAnchor).isActive = true
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.leadingAnchor.constraint(equalTo: largeLabel.trailingAnchor, constant: 5).isActive = true
        
        scoreLabel.centerYAnchor.constraint(equalTo: scoreLabelContainerView.centerYAnchor, constant: 2.7).isActive = true
        moreInfoButton.centerYAnchor.constraint(equalTo: moreInfoButtonContainerView.centerYAnchor, constant: 3.7).isActive = true
        
        moreInfoButton.topAnchor.constraint(equalTo: largeLabel.topAnchor).isActive = true
        
        moreInfoButton.widthAnchor.constraint(equalTo: moreInfoButton.heightAnchor).isActive = true
        
        moreInfoButton.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: 5).isActive = true
        //moreInfoButton.centerYAnchor.constraint(equalTo: scoreLabelContainerView.centerYAnchor, constant: 2.7).isActive = true
        
        largeLabel.centerYAnchor.constraint(equalTo: largeLabel.superview!.centerYAnchor).isActive = true
        //scoreLabel.centerYAnchor.constraint(equalTo: scoreLabel.superview!.centerYAnchor, constant: 2.5).isActive = true
        
        
        
        //scoreLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        //let constraint = scoreLabel.heightAnchor.constraint(equalToConstant: 20)
        //constraint.priority = .init(999)
        //constraint.isActive = true
        //scoreLabel.centerYAnchor.constraint(equalTo: largeLabel.centerYAnchor, constant: 2.5).isActive = true
        //largeLabel.lastBaselineAnchor.constraint(equalTo: scoreLabel.lastBaselineAnchor).isActive = true
        
        smallHeaderTitle.translatesAutoresizingMaskIntoConstraints = false
        smallHeaderTitle.insetsLayoutMarginsFromSafeArea = false
        
        smallScoreLabel.translatesAutoresizingMaskIntoConstraints = false
        smallScoreLabel.leadingAnchor.constraint(equalTo: smallLabel.trailingAnchor, constant: 5).isActive = true
        smallScoreLabel.bottomAnchor.constraint(equalTo: smallLabel.bottomAnchor).isActive = true
        
        smallHeaderTitle.heightAnchor.constraint(equalToConstant: max(smallLabel.frame.size.height, smallScoreLabel.intrinsicContentSize.height)).isActive = true
        smallHeaderTitle.widthAnchor.constraint(equalToConstant: smallLabel.frame.size.width + 5 + smallScoreLabel.intrinsicContentSize.width).isActive = true
        
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        
        headerTitle.bottomAnchor.constraint(equalTo: segmentedControl.topAnchor, constant: -8).isActive = true
        headerTitle.widthAnchor.constraint(equalToConstant: largeLabel.frame.size.width + 5 + scoreLabel.intrinsicContentSize.width).isActive = true
        headerTitle.heightAnchor.constraint(equalToConstant: max(largeLabel.frame.size.height, scoreLabel.intrinsicContentSize.height)).isActive = true
        
        largeLabel.leadingAnchor.constraint(equalTo: tableView.tableHeaderView!.leadingAnchor, constant: 16).isActive = true
        
        blurView.frame = CGRect(x: 0, y: tableView.tableHeaderView!.frame.maxY - 40, width: UIScreen.main.bounds.size.width, height: 40)
        
        originalBlurRect = blurView.frame
        originalTitleRect = headerTitle.frame
        
        tableView.tableHeaderView!.bringSubviewToFront(headerTitle)
        
        if let v = tableView.tableHeaderView as? StretchyTableHeaderView {
            v.segControl = segmentedControl
            v.moreInfoButton = moreInfoButton
        }
        
        headerTitle.updateConstraints()
        
        //scrollViewDidScroll(tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFinishLoading {
            tableView.isHidden = true
            
            if shouldLoadFromUsername {
                SwiftRant.shared.getUserID(of: self.username!, completionHandler: { result in
                    self.userID = try! result.get()
                    
                    SwiftRant.shared.getProfileFromID(self.userID!, token: nil, userContentType: .rants, skip: 0, completionHandler: { result in
                        self.rantTypeContent = try! result.get().content.content.rants
                        self.currentDate = Date()
                        
                        /*for i in self.rantTypeContent {
                            if let attachedImage = i.attachedImage {
                                if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent).relativePath) {
                                    self.rantContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent), size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                                } else {
                                    self.rantContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                                }
                            } else {
                                self.rantContentImages.append(nil)
                            }
                        }*/
                        
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            
                            self.didFinishLoading = true
                            self.profileData = try! result.get()
                            self.tableView.isHidden = false
                            self.viewDidLoad()
                            self.tableView.reloadData()
                        }
                    })
                })
            } else {
                SwiftRant.shared.getProfileFromID(self.userID!, token: nil, userContentType: .rants, skip: 0, completionHandler: { result in
                    self.rantTypeContent = try! result.get().content.content.rants
                    self.currentDate = Date()
                    
                    /*for i in self.rantTypeContent {
                        if let attachedImage = i.attachedImage {
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent).relativePath) {
                                self.rantContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent), size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                            } else {
                                self.rantContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                            }
                        } else {
                            self.rantContentImages.append(nil)
                        }
                    }*/
                    
                    DispatchQueue.main.async {
                        self.loadingIndicator.stopAnimating()
                        
                        self.didFinishLoading = true
                        self.profileData = try! result.get()
                        self.tableView.isHidden = false
                        self.viewDidLoad()
                        self.tableView.reloadData()
                    }
                })
            }
        } else {
            if let _ = tableView.tableHeaderView {
                scrollViewDidScroll(tableView)
                tableView.reloadData()
            }
        }
    }
    
    /*func getContent(contentType: Profile.ProfileContentTypes, completion: @escaping ((String?, Profile?) -> Void)) {
        //APIRequest().getProfileFromID(self.userID!, userContentType: contentType, skip: (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.rantFeed.count : commentTypeContent.commentTypeContent.count), completionHandler: { result in completion(result) })
        SwiftRant.shared.getProfileFromID(self.userID!, token: nil, userContentType: contentType, skip: (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.count : commentTypeContent.commentTypeContent.count), completionHandler: { error, result in completion(error, result) })
    }*/
    
    override func viewWillAppear(_ animated: Bool) {
        let targetHeight: CGFloat = 21
        
        var thresholdHeight = 502 - navigationController!.navigationBar.frame.maxY - 41 - 2 * 40
        
        thresholdHeight += 42
        
        var offset = ((tableView.contentOffset.y - thresholdHeight) / targetHeight)
        
        if offset > 1 {offset = 1}
        
        if offset < 0 { offset = 0 }
        
        print("RUNNING VIEWWILLAPPEAR")
        
        shouldModifyNavigationBar = true
        
        //defaultNavigationBarScrollEdgeAppearance = navigationController?.navigationBar.scrollEdgeAppearance
        //let navigationBarAppearance = UINavigationBarAppearance()
        //navigationBarAppearance.shadowColor = .clear
        //navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        
        navigationController?.navigationBar.clipsToBounds = true
        
        if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
            transitionCoordinator?.animate(alongsideTransition: { context in
                extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = sqrt(offset)
                
                self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
                
                if let profileData = self.profileData {
                    self.navigationController?.navigationBar.tintColor = blend(from: .white, to: UIColor(hexString: profileData.avatar.backgroundColor)!, percent: Double(sqrt(offset)))
                } else {
                    self.navigationController?.navigationBar.tintColor = .white
                }
                
                if self.navigationItem.titleView != nil {
                    self.navigationItem.titleView!.isHidden = false
                }
                
                self.scrollViewDidScroll(self.tableView)
            }, completion: { context in
                if context.isCancelled && self.navigationController?.topViewController != self {
                    self.navigationController?.navigationBar.tintColor = UIButton().tintColor
                    
                    self.shouldModifyNavigationBar = false
                    extendedNavigationController.navigationBar.clipsToBounds = false
                }
            })
        } else {
            transitionCoordinator?.animate(alongsideTransition: { context in
                self.navigationController?.navigationBar.backgroundView?.alpha = sqrt(offset)
                
                self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
                
                if let profileData = self.profileData {
                    self.navigationController?.navigationBar.tintColor = blend(from: .white, to: UIColor(hexString: profileData.avatar.backgroundColor)!, percent: Double(sqrt(offset)))
                } else {
                    self.navigationController?.navigationBar.tintColor = .white
                }
                
                if self.navigationItem.titleView != nil {
                    self.navigationItem.titleView!.isHidden = false
                }
            }, completion: nil)
        }
        
        super.viewWillAppear(animated)
        
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
        let targetHeight: CGFloat = 21
        
        if let tableHeaderView = tableView.tableHeaderView, let navigationController = navigationController {
            var thresholdHeight = tableHeaderView.frame.size.height - navigationController.navigationBar.frame.maxY - headerTitle.frame.size.height - 2 * (blurView.frame.size.height - 21)
            
            thresholdHeight += 42
            
            let previousTintColor = navigationController.navigationBar.tintColor
            let previousBackgroundAlpha = navigationController.navigationBar.backgroundView!.alpha
            let previousTitleView = navigationItem.titleView
            
            var offset = ((tableView.contentOffset.y - thresholdHeight) / targetHeight)
            
            if offset > 1 {offset = 1}
            
            if offset < 0 { offset = 0 }
            
            shouldModifyNavigationBar = false
            
            navigationController.navigationBar.clipsToBounds = false
            
            if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
                
                print("RUNNING AS EXTENSIVE")
                transitionCoordinator?.animate(alongsideTransition: { context in
                    
                    if self.navigationItem.titleView != nil && self.navigationItem.titleView!.alpha == 0 {
                        self.navigationItem.titleView!.isHidden = true
                    }
                    
                    self.navigationController?.navigationBar.backgroundView?.alpha = 1
                    
                    self.navigationController?.navigationBar.tintColor = UIColor.tintColor
                    
                    debugPrint("TINT COLOR SET")
                    
                    //extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = 1
                    
                    if let barBackground = extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" }) {
                        barBackground.alpha = 1
                        
                        debugPrint("ALPHA SET")
                    } else {
                        print("COULD NOT FIND BAR BACKGROUND!")
                    }
                }, completion: { context in
                    if context.isCancelled && self.navigationController?.topViewController == self {
                        
                        print("CANCELLED")
                        
                        self.shouldModifyNavigationBar = true
                        extendedNavigationController.navigationBar.clipsToBounds = true
                        
                        print("FROM: \(context.viewController(forKey: .from)! is RantViewController ? "RantViewController" : "ProfileTableViewController")")
                        print("TO: \(context.viewController(forKey: .from)! is RantViewController ? "RantViewController" : "ProfileTableViewController")")
                        self.navigationItem.titleView?.isHidden = false
                        extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = previousBackgroundAlpha
                        self.navigationController?.navigationBar.backgroundView?.alpha = previousBackgroundAlpha
                        
                        self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = previousBackgroundAlpha
                        
                        self.navigationController?.navigationBar.tintColor = previousTintColor
                        
                        self.scrollViewDidScroll(self.tableView)
                    }
                })
            } else {
                print("NOT RUNNING AS EXTENSIVE")
                
                transitionCoordinator?.animate(alongsideTransition: { context in
                    if self.navigationItem.titleView!.alpha == 0 {
                        self.navigationItem.titleView!.isHidden = true
                    }
                    
                    self.navigationController?.navigationBar.backgroundView?.alpha = 1
                    self.navigationController?.navigationBar.visualEffectView?.alpha = 1
                    self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = 1
                    
                    self.navigationController?.navigationBar.tintColor = UIButton().tintColor
                }, completion: { context in
                    if context.isCancelled {
                        
                        print("CANCELLED")
                        
                        print("FROM: \(context.viewController(forKey: .from)! is RantViewController ? "RantViewController" : "ProfileTableViewController")")
                        print("TO: \(context.viewController(forKey: .from)! is RantViewController ? "RantViewController" : "ProfileTableViewController")")
                        self.navigationItem.titleView!.isHidden = false
                        
                        if self.navigationController?.topViewController == self {
                        
                            print("PREVIOUS BACKGROUND ALPHA: \(previousBackgroundAlpha)")
                            self.navigationController?.navigationBar.backgroundView?.alpha = previousBackgroundAlpha
                        
                            self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = previousBackgroundAlpha
                        
                            self.navigationController?.navigationBar.tintColor = previousTintColor
                            self.scrollViewDidScroll(self.tableView)
                        } else {
                            self.navigationController?.navigationBar.backgroundView?.alpha = 1
                            self.navigationController?.navigationBar.visualEffectView?.alpha = 1
                            self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = 1
                            
                            self.navigationController?.navigationBar.tintColor = UIButton().tintColor
                        }
                    }
                })
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    @objc func segmentedControlSelectionChanged(_ sender: UISegmentedControl) {
        rantTypeContent = []
        commentTypeContent.commentTypeContent = []
        rantContentImages = []
        commentContentImages = []
        
        cellHeights = [:]
        
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
            performFetch(contentType: .comments, {
                
                DispatchQueue.main.async { self.tableView.reloadData() } })
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
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /*switch currentContentType {
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
        }*/
        if section == 0 {
            if currentContentType != .comments {
                return rantTypeContent.count
            } else {
                return commentTypeContent.commentTypeContent.count
            }
        } else {
            if canLoadMore() {
                return 1
            } else {
                return 0
            }
        }
    }
    
    // MARK: - Table View Data Source Prefetching
    /*func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.contains(where: { $0.row >= (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.count : commentTypeContent.commentTypeContent.count) }) {
            print("PREFETCHING!")
            performFetch(contentType: currentContentType, {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
    }*/
    
    // MARK: - Miscellaneous utilities
    fileprivate func performFetch(contentType: Profile.ProfileContentTypes, _ completionHandler: (() -> Void)?) {
        guard !isFetchAlreadyInProgress else {
            return
        }
        
        isFetchAlreadyInProgress = true
        
        Task {
            let result = await SwiftRant.shared.getProfileFromID(self.userID!, token: nil, userContentType: self.currentContentType, skip: (self.currentContentType == .rants || self.currentContentType == .upvoted || self.currentContentType == .favorite ? self.rantTypeContent.count : self.commentTypeContent.commentTypeContent.count))
            
            guard case .success(let response) = result else {
                self.showAlertWithError("Failed to fetch user content.", retryHandler: { self.performFetch(contentType: contentType, completionHandler) })
            
                self.isFetchAlreadyInProgress = false
                return
            }
            
            self.currentDate = Date()
        
            var start = 0
            var end = 0
        
            switch contentType {
            case .rants:
                start = self.rantTypeContent.count
                end = response.content.content.rants.count + start
            
                self.commentTypeContent.commentTypeContent = []
                break
            
            case .upvoted:
                start = self.rantTypeContent.count
                end = response.content.content.upvoted.count + start
            
                self.commentTypeContent.commentTypeContent = []
                break
            
            case .favorite:
                start = self.rantTypeContent.count
                end = response.content.content.favorites!.count + start
            
                self.commentTypeContent.commentTypeContent = []
                break
            
            default:
                start = self.commentTypeContent.commentTypeContent.count
                end = response.content.content.comments.count + start
                
                /*for comment in response.content.content.comments {
                    if let avatarImage = comment.userAvatar.avatarImage {
                        Task {
                            try? await self.userImageLoader.loadImage(from: URL(string: "https://avatars.devrant.com/\(avatarImage)")!, forUserID: comment.userID)
                        }
                    } else {
                        await self.userImageStore.store(userID: comment.userID, image: UIImage(color: UIColor(hexString: comment.userAvatar.backgroundColor)!, size: CGSize(width: 45, height: 45))!)
                    }
                }*/
            
                self.rantTypeContent = []
                break
            }
        
            let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
        
            switch contentType {
            case .rants:
                self.rantTypeContent.append(contentsOf: response.content.content.rants)
                break
            
            case .upvoted:
                self.rantTypeContent.append(contentsOf: response.content.content.upvoted)
                break
            
            case .favorite:
                self.rantTypeContent.append(contentsOf: response.content.content.favorites!)
                break
            
            default:
                self.commentTypeContent.commentTypeContent.append(contentsOf: response.content.content.comments)
                break
            }
        
            if !self.rantTypeContent.isEmpty {
                /*for i in self.rantTypeContent[start..<end] {
                    if let attachedImage = i.attachedImage {
                        self.rantContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                    } else {
                        self.rantContentImages.append(nil)
                    }
                }*/
                
                //await userImageLoader.waitUntilAllTasksAreFinished()
                self.isFetchAlreadyInProgress = false
                
                await MainActor.run {
                    completionHandler?()
                }
            } else {
                /*for i in self.commentTypeContent.commentTypeContent[start..<end] {
                    if let attachedImage = i.attachedImage {
                        if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent).relativePath) {
                            self.commentContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent), size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                        } else {
                            self.commentContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                        }
                    } else {
                        self.commentContentImages.append(nil)
                    }
                }*/
                
                //await userImageLoader.waitUntilAllTasksAreFinished()
                self.isFetchAlreadyInProgress = false
                
                await MainActor.run {
                    completionHandler?()
                }
            }
        }
        
        /*SwiftRant.shared.getProfileFromID(self.userID!, token: nil, userContentType: currentContentType, skip: (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.count : commentTypeContent.commentTypeContent.count), completionHandler: { _, response in
                guard response != nil else {
                    DispatchQueue.main.async {
                        self.showAlertWithError("Failed to fetch user content.", retryHandler: { self.performFetch(contentType: contentType, completionHandler) })
                    }
                
                    self.isFetchAlreadyInProgress = false
                    return
                }
            
                var start = 0
                var end = 0
            
                switch contentType {
                case .rants:
                    start = self.rantTypeContent.count
                    end = response!.content.content.rants.count + start
                
                    self.commentTypeContent.commentTypeContent = []
                    break
                
                case .upvoted:
                    start = self.rantTypeContent.count
                    end = response!.content.content.upvoted.count + start
                
                    self.commentTypeContent.commentTypeContent = []
                    break
                
                case .favorite:
                    start = self.rantTypeContent.count
                    end = response!.content.content.favorites!.count + start
                
                    self.commentTypeContent.commentTypeContent = []
                    break
                
                default:
                    start = self.commentTypeContent.commentTypeContent.count
                    end = response!.content.content.comments.count + start
                    
                    for comment in response!.content.content.comments {
                        if let avatarImage = comment.userAvatar.avatarImage {
                            Task {
                                try? await self.userImageLoader.loadImage(from: URL(string: "https://avatars.devrant.com/\(avatarImage)")!, forUserID: comment.userID)
                            }
                        } else {
                            await self.userImageStore.store(userID: comment.userID, image: UIImage(color: UIColor(hexString: comment.userAvatar.backgroundColor), size: CGSize(width: 45, height: 45))!)
                        }
                    }
                
                    self.rantTypeContent = []
                    break
                }
            
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
            
                switch contentType {
                case .rants:
                    self.rantTypeContent.append(contentsOf: response!.content.content.rants)
                    break
                
                case .upvoted:
                    self.rantTypeContent.append(contentsOf: response!.content.content.upvoted)
                    break
                
                case .favorite:
                    self.rantTypeContent.append(contentsOf: response!.content.content.favorites!)
                    break
                
                default:
                    self.commentTypeContent.commentTypeContent.append(contentsOf: response!.content.content.comments)
                    break
                }
            
                if !self.rantTypeContent.isEmpty {
                    for i in self.rantTypeContent[start..<end] {
                        if let attachedImage = i.attachedImage {
                            self.rantContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                        } else {
                            self.rantContentImages.append(nil)
                        }
                    }
                
                    self.isFetchAlreadyInProgress = false
                
                    completionHandler?()
                } else {
                    for i in self.commentTypeContent.commentTypeContent[start..<end] {
                        if let attachedImage = i.attachedImage {
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent).relativePath) {
                                self.commentContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url)!.lastPathComponent), size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                            } else {
                                self.commentContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width, height: attachedImage.height)))
                            }
                        } else {
                            self.commentContentImages.append(nil)
                        }
                    }
                
                    self.isFetchAlreadyInProgress = false
                
                    completionHandler?()
                }
        })*/
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if currentContentType != .comments {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! RantInFeedCell
                cell.configure(with: rantTypeContent[indexPath.row], image: nil, parentTableViewController: self, parentTableView: tableView)
                
                var attributedTitle = NSMutableAttributedString(string: "\(rantTypeContent[indexPath.row].commentCount)")
                
                let attributes = [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12),
                    NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
                ]
                
                attributedTitle.addAttributes(attributes, range: NSRange(location: 0, length: attributedTitle.length))
                
                cell.commentCountLabel?.setAttributedTitle(attributedTitle, for: .normal)
                
                cell.contentView.layoutIfNeeded()
                
                // Here, we modify the original margin constraints and convert them to normal, non-margin constraints.
                // This is essential because cells with margin constraints to the content view glitch and bug out in this specific view controller, probably because of the stretchy header and the unconventional scrolling dynamics.
                // If we wouldn't perform this fix, the cells would contract and expand in size while scrolling them out of the viewable region, while breaking about 1000 constraints per second.
                // **I have no idea what is making this happen, but this is a solution that I came up with after days of fighting with this issue and almost giving up.**
                for constraint in cell.contentView.constraints {
                    switch constraint.identifier {
                    case "leadingMarginSpace":
                        cell.contentView.removeConstraint(constraint)
                        
                        let newConstraint = cell.contentStackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    case "trailingMarginSpace":
                        cell.contentView.removeConstraint(constraint)
                        
                        let newConstraint = cell.contentView.trailingAnchor.constraint(equalTo: cell.contentStackView.trailingAnchor, constant: 24)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    case "bottomMarginSpace":
                        //cell.contentView.removeConstraint(constraint)
                        
                        //let newConstraint = cell.contentView.bottomAnchor.constraint(equalTo: cell.tagList.bottomAnchor, constant: 15)
                        //newConstraint.isActive = true
                        
                        //cell.contentView.addConstraint(newConstraint)
                        break
                        
                    case "topMarginSpace":
                        cell.contentView.removeConstraint(constraint)
                        
                        let newConstraint = cell.contentStackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 15)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    default:
                        break
                    }
                }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
                cell.configure(with: commentTypeContent.commentTypeContent[indexPath.row], supplementalImage: nil, parentTableViewController: self, parentTableView: tableView, currentDate: currentDate, allowedToPreview: false)
                
                for constraint in cell.contentView.constraints {
                    switch constraint.identifier {
                    case "leadingMarginSpace":
                        cell.removeConstraint(constraint)
                        
                        let newConstraint = cell.contentStackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 20)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    case "trailingMarginSpace":
                        cell.contentView.removeConstraint(constraint)
                        
                        let newConstraint = cell.contentView.trailingAnchor.constraint(equalTo: cell.contentStackView.trailingAnchor, constant: 24)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    case "bottomMarginSpace":
                        cell.contentView.removeConstraint(constraint)
                        
                        //let newConstraint = cell.contentView.bottomAnchor.constraint(equalTo: cell.actionsStackView.bottomAnchor, constant: 0)
                        //newConstraint.isActive = true
                        
                        //cell.contentView.addConstraint(newConstraint)
                        
                        //let newConstraint = cell.contentView.bottomAnchor.constraint(equalTo: cell.contentStackView.bottomAnchor, constant: 15)
                        
                        let newConstraint = cell.contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: cell.contentStackView.bottomAnchor, constant: 4)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    case "topMarginSpace":
                        cell.contentView.removeConstraint(constraint)
                        
                        let newConstraint = cell.contentStackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 15)
                        newConstraint.isActive = true
                        
                        cell.contentView.addConstraint(newConstraint)
                        break
                        
                    default:
                        break
                    }
                }
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell") as! LoadingCell
            
            cell.activityIndicator.startAnimating()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            if indexPath.row < rantTypeContent.count && indexPath.row < rantContentImages.count {
                cellHeights[indexPath] = cell.frame.size.height
            }
        } else {
            if indexPath.row < commentTypeContent.commentTypeContent.count && indexPath.row < commentContentImages.count {
                cellHeights[indexPath] = cell.frame.size.height
            }
        }
    }
    
    /*func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            if indexPath.row >= rantTypeContent.count || indexPath.row >= rantContentImages.count {
                return 80
            } else {
                return cellHeights[indexPath] ?? UITableView.automaticDimension
            }
        } else {
            if indexPath.row >= commentTypeContent.commentTypeContent.count || indexPath.row >= commentContentImages.count {
                return 80
            } else {
                return cellHeights[indexPath] ?? UITableView.automaticDimension
            }
        }
    }*/
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard blurView != nil else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.shouldUpdateBlurPosition()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        /*if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            guard indexPath.row < rantTypeContent.count && indexPath.row < rantContentImages.count else {
                return
            }
        } else {
            guard indexPath.row < commentTypeContent.commentTypeContent.count && indexPath.row < commentContentImages.count else {
                return
            }
        }
        
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite || currentContentType == .viewed {
            performSegue(withIdentifier: "rantInFeed", sender: tableView.cellForRow(at: indexPath))
        } else {
            performSegue(withIdentifier: "commentInFeed", sender: tableView.cellForRow(at: indexPath))
        }*/
        
        /*if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            guard indexPath.row < rantTypeContent.count && indexPath.row < rantContentImages.count else {
                return
            }
        } else {
            guard indexPath.row < commentTypeContent.commentTypeContent.count && indexPath.row < commentContentImages.count else {
                return
            }
        }*/
        
        /*if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite || currentContentType == .viewed {
            performSegue(withIdentifier: "rantInFeed", sender: tableView.cellForRow(at: indexPath))
        }
        
        if currentContentType == .comments {
            performSegue(withIdentifier: "commentInFeed", sender: indexPath)
        }*/
        if indexPath.section == 0 {
            if currentContentType != .comments {
                performSegue(withIdentifier: "rantInFeed", sender: tableView.cellForRow(at: indexPath))
            } else {
                performSegue(withIdentifier: "commentInFeed", sender: indexPath)
            }
        } else {
            return
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
            
            rantViewController.rantID = rantTypeContent[indexPath.row].id
            rantViewController.profileFeedDelegate = self
            /*withUnsafeMutablePointer(to: &rantTypeContent[indexPath.row], { pointer in
                rantViewController.rantInFeed = pointer
            })*/
            
            //rantViewController.supplementalRantImage = rantContentImages[indexPath.row]
            rantViewController.loadCompletionHandler = nil
        } else if segue.identifier == "commentInFeed", let rantViewController = segue.destination as? RantViewController {
            let indexPath = sender as! IndexPath
            
            rantViewController.rantID = commentTypeContent.commentTypeContent[indexPath.row].rantID
            //rantViewController.rantInFeed = nil
            
            rantViewController.profileFeedDelegate = self
            
            /*withUnsafeMutablePointer(to: &commentTypeContent.commentTypeContent[indexPath.row], { pointer in
                rantViewController.commentInFeed = pointer
            })*/
            
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
        //tableView.reloadData()
    }
    
    fileprivate func indexForRant(withID id: Int) -> Int? {
        if let rantIdx = rantTypeContent.firstIndex(where: { $0.id == id }) {
            return rantIdx
        }
        
        return nil
    }
    
    fileprivate func indexForComment(withID id: Int) -> Int? {
        if let commentIdx = commentTypeContent.commentTypeContent.firstIndex(where: { $0.id == id }) {
            return commentIdx
        }
        
        return nil
    }
    
    // MARK: - Profile Table View Controller Delegate
    func setVoteStateForRant(withID id: Int, voteState: VoteState) {
        if let rantIndex = indexForRant(withID: id) {
            rantTypeContent[rantIndex].voteState = voteState
        }
    }
    
    func setScoreForRant(withID id: Int, score: Int) {
        guard [Profile.ProfileContentTypes.rants, Profile.ProfileContentTypes.favorite, Profile.ProfileContentTypes.upvoted].contains(currentContentType) else {
            return
        }
        
        if let rantIndex = indexForRant(withID: id) {
            rantTypeContent[rantIndex].score = score
        }
    }
    
    func setVoteStateForComment(withID id: Int, voteState: VoteState) {
        if let commentIndex = indexForComment(withID: id) {
            commentTypeContent.commentTypeContent[commentIndex].voteState = voteState
        }
    }
    
    func setScoreForComment(withID id: Int, score: Int) {
        guard currentContentType == .comments else {
            return
        }
        
        if let commentIndex = indexForComment(withID: id) {
            commentTypeContent.commentTypeContent[commentIndex].score = score
        }
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    // MARK: - Feed Delegate
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantInFeedCell) {
        let rantIndex = indexForRant(withID: id)
        
        SwiftRant.shared.voteOnRant(nil, rantID: id, vote: vote) { [weak self] result in
            if case .success(let updatedRant) = result {
                /*if let rantInFeed = self?.rantInFeed {
                    rantInFeed.pointee.voteState = vote
                    rantInFeed.pointee.score = updatedRant.score
                }*/
                
                //self?.rant?.voteState = updatedRant.voteState
                //self?.rant?.score = updatedRant.score
                
                if let rantIndex = rantIndex {
                    self?.rantTypeContent[rantIndex].voteState = updatedRant.voteState
                    self?.rantTypeContent[rantIndex].score = updatedRant.score
                }
                
                /*if let parentTableViewController = self?.parentTableViewController {
                    parentTableViewController.rant?.voteState = updatedRant.voteState
                    parentTableViewController.rant?.score = updatedRant.score
                    
                    DispatchQueue.main.async {
                        parentTableViewController.tableView.reloadData()
                    }
                }*/
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    
                    //self?.homeFeedDelegate?.changeRantVoteState(rantID: id, voteState: vote)
                    
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
    }
    
    func didVoteOnComment(withID id: Int, vote: VoteState, cell: CommentCell) {
        let commentIndex = indexForComment(withID: id)
        
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
                
                self.commentTypeContent.commentTypeContent[commentIndex].voteState = updatedComment.voteState
                self.commentTypeContent.commentTypeContent[commentIndex].score = updatedComment.score
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    
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
    
    @objc func showMoreInfo() {
        let moreInfoTVC = UIStoryboard(name: "UserInfoTableViewController", bundle: nil).instantiateViewController(identifier: "UserInfoTableViewController") as! UserInfoTableViewController
        
        moreInfoTVC.modalPresentationStyle = .pageSheet
        
        //let sheet = moreInfoTVC.sheetPresentationController
        
        //sheet!.detents = [.medium(), .large()]
        
        moreInfoTVC.methodForRunningAfterLoad = { vc in
            if self.profileData!.about == "" {
                //vc.aboutContentCell.isHidden = true
                //vc.aboutTitleCell.isHidden = true
                
                //let set = IndexSet(integer: 0)
                
                //vc.tableView.deleteSections(set, with: .none)
                
                vc.indexPathsToHide.append(IndexPath(row: 0, section: 0))
                vc.indexPathsToHide.append(IndexPath(row: 1, section: 0))
            } else {
                (vc.aboutContentCell.contentView.subviews.first(where: { $0 is UITextView }) as? UITextView)?.text = self.profileData!.about
            }
            
            if self.profileData!.skills == "" {
                //vc.skillsContentCell.isHidden = true
                //vc.skillsTitleCell.isHidden = true
                
                //let set = IndexSet(integer: 1)
                
                //vc.tableView.deleteSections(set, with: .none)
                
                vc.indexPathsToHide.append(IndexPath(row: 0, section: 1))
                vc.indexPathsToHide.append(IndexPath(row: 1, section: 1))
            } else {
                (vc.skillsContentCell.contentView.subviews.first(where: { $0 is UITextView }) as? UITextView)?.text = self.profileData!.skills
            }
            
            if self.profileData!.location == "" {
                //vc.locationContentCell.isHidden = true
                //vc.locationTItleCell.isHidden = true
                
                //let set = IndexSet(integer: 2)
                
                //vc.tableView.deleteSections(set, with: .none)
                
                vc.indexPathsToHide.append(IndexPath(row: 0, section: 2))
                vc.indexPathsToHide.append(IndexPath(row: 1, section: 2))
            } else {
                (vc.locationContentCell.contentView.subviews.first(where: { $0 is UILabel }) as? UILabel)?.text = self.profileData!.location
            }
            
            if let website = self.profileData!.website, website != "" {
                (vc.websiteContentCell.contentView.subviews.first(where: { $0 is UILabel }) as? UILabel)?.text = website
            } else {
                //vc.websiteContentCell.isHidden = true
                //vc.websiteTitleCell.isHidden = true
                
                
                //let set = IndexSet(integer: 4)
                
                //vc.tableView.deleteSections(set, with: .none)
                
                vc.indexPathsToHide.append(IndexPath(row: 0, section: 3))
                vc.indexPathsToHide.append(IndexPath(row: 1, section: 3))
            }
            
            if self.profileData!.github == "" {
                //vc.githubContentCell.isHidden = true
                //vc.githubTitleCell.isHidden = true
                
                //let set = IndexSet(integer: 3)
                
                //vc.tableView.deleteSections(set, with: .none)
                
                vc.indexPathsToHide.append(IndexPath(row: 0, section: 4))
                vc.indexPathsToHide.append(IndexPath(row: 1, section: 4))
            } else {
                (vc.githubContentCell.contentView.subviews.first(where: { $0 is UILabel }) as? UILabel)?.text = self.profileData!.github
            }
            
            //vc.tableView.beginUpdates()
            //vc.tableView.deleteRows(at: indexPaths, with: .none)
            //vc.tableView.endUpdates()
            
            //vc.tableView.deleteRows(at: indexPaths, with: .none)
            
            //vc.tableView.reloadData()
        }
        
        let navController = UINavigationController(rootViewController: moreInfoTVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        
        present(navController, animated: true)
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

extension ProfileTableViewController: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        debugPrint("CACHING PROFILE IMAGE FOR USER \(profileData!.username) WITH STORAGE POLICY: \(proposedResponse.storagePolicy == .allowed ? ".allowed" : proposedResponse.storagePolicy == .allowedInMemoryOnly ? ".allowedInMemoryOnly" : ".notAllowed")")
        
        completionHandler(proposedResponse)
    }
}

func blend(from: UIColor, to: UIColor, percent: Double) -> UIColor {
    var fR : CGFloat = 0.0
    var fG : CGFloat = 0.0
    var fB : CGFloat = 0.0
    var tR : CGFloat = 0.0
    var tG : CGFloat = 0.0
    var tB : CGFloat = 0.0

    from.getRed(&fR, green: &fG, blue: &fB, alpha: nil)
    to.getRed(&tR, green: &tG, blue: &tB, alpha: nil)

    let dR = tR - fR
    let dG = tG - fG
    let dB = tB - fB

    let rR = fR + dR * CGFloat(percent)
    let rG = fG + dG * CGFloat(percent)
    let rB = fB + dB * CGFloat(percent)

    return UIColor(red: rR, green: rG, blue: rB, alpha: 1.0)
}
