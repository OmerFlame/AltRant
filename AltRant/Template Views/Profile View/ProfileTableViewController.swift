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
    //var originalSmallTitleRect: CGRect!
    var originalTestRect: CGRect!
    
    var segmentedControl: UISegmentedControl!
        
    var testBlurView: UIVisualEffectView!
    var headerTitle: UIStackView!
    var blurView: UIVisualEffectView!
    var scoreRect: UIView!
    var scoreLabel: PaddingLabel!
    
    var currentBlurFrame: CGRect!
    
    //var blurViewHeight = NSLayoutConstraint()
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
    
    private var cellHeights = [IndexPath:CGFloat]()
    
    init?(coder: NSCoder, userID: Int) {
        self.userID = userID
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        navigationController?.navigationBar.tintColor = blend(from: .white, to: UIColor(hex: profileData!.avatar.b)!, percent: Double(sqrt(offset)))
        
        // Set the opacity of the custom title view of the navigation bar to the square root of the offset.
        navigationItem.titleView?.alpha = sqrt(offset)
        
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
        } else {
            //blurView.contentView.gestureRecognizers!.forEach(blurView.contentView.removeGestureRecognizer)
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
        tableView.prefetchDataSource = self
        
        tableView.contentInsetAdjustmentBehavior = .never
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundView?.alpha = 0
        
        //navigationController?.title = ""
        navigationItem.title = ""
        
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
        
        //(tableView.tableHeaderView as! StretchyTableHeaderView).maskBlurView = navigationController?.navigationBar.visualEffectView
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).setMaskBlurView(newBlurView: navigationController?.navigationBar.visualEffectView?.copyView())
        
        scrollViewDidScroll(tableView)
        
        tableView.scrollIndicatorInsets.top = tableView.tableHeaderView!.frame.maxY - (navigationController!.navigationBar.frame.size.height + navigationController!.navigationBar.frame.minY)
        
        currentBlurFrame = blurView.frame
        
        tableView.infiniteScrollIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        tableView.infiniteScrollIndicatorMargin = 40
        tableView.infiniteScrollTriggerOffset = 500
        
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
    
    // Add the special title subviews at the top of the screen and set up the constraints.
    func addTitle() {
        blurView = navigationController?.navigationBar.visualEffectView?.copyView()
        
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
        
        headerTitle.addArrangedSubview(largeLabel)
        headerTitle.addArrangedSubview(scoreLabel)
        
        let smallHeaderTitle = UIStackView(frame: CGRect(x: 0, y: 0, width: smallLabel.frame.size.width + 5 + smallScoreLabel.intrinsicContentSize.width, height: max(smallLabel.frame.size.height, smallScoreLabel.intrinsicContentSize.height)))
        
        smallHeaderTitle.axis = .horizontal
        smallHeaderTitle.alignment = .center
        smallHeaderTitle.distribution = .equalCentering
        
        smallHeaderTitle.addArrangedSubview(smallLabel)
        smallHeaderTitle.addArrangedSubview(smallScoreLabel)
        
        blurView.contentView.addSubview(segmentedControl)
        
        tableView.tableHeaderView!.addSubview(headerTitle)
        tableView.tableHeaderView!.addSubview(blurView)
        
        navigationItem.titleView = smallHeaderTitle
        
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
        
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.leadingAnchor.constraint(equalTo: largeLabel.trailingAnchor, constant: 5).isActive = true
        
        largeLabel.centerYAnchor.constraint(equalTo: largeLabel.superview!.centerYAnchor).isActive = true
        
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
        }
        
        headerTitle.updateConstraints()
        
        //scrollViewDidScroll(tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didFinishLoading {
            tableView.isHidden = true
            
            APIRequest().getProfileFromID(self.userID, userContentType: .rants, skip: 0, completionHandler: { response in
                self.rantTypeContent.rantFeed = response!.profile.content.content.rants
                
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
                
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    
                    self.didFinishLoading = true
                    self.profileData = response!.profile
                    self.tableView.isHidden = false
                    self.viewDidLoad()
                    self.tableView.reloadData()
                }
            })
        } else {
            if let _ = tableView.tableHeaderView {
                scrollViewDidScroll(tableView)
                tableView.reloadData()
            }
        }
    }
    
    func getContent(contentType: ProfileContentTypes, completion: @escaping ((ProfileResponse?) -> Void)) {
        APIRequest().getProfileFromID(self.userID, userContentType: contentType, skip: (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.rantFeed.count : commentTypeContent.commentTypeContent.count), completionHandler: { result in completion(result) })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let targetHeight: CGFloat = 21
        
        var thresholdHeight = 502 - navigationController!.navigationBar.frame.maxY - 41 - 2 * 40
        
        thresholdHeight += 42
        
        var offset = ((tableView.contentOffset.y - thresholdHeight) / targetHeight)
        
        if offset > 1 {offset = 1}
        
        if offset < 0 { offset = 0 }
        
        print("RUNNING VIEWWILLAPPEAR")
        
        if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
            transitionCoordinator?.animate(alongsideTransition: { context in
                extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = sqrt(offset)
                
                self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
                
                if let profileData = self.profileData {
                    self.navigationController?.navigationBar.tintColor = blend(from: .white, to: UIColor(hex: profileData.avatar.b)!, percent: Double(sqrt(offset)))
                } else {
                    self.navigationController?.navigationBar.tintColor = .white
                }
                
                if self.navigationItem.titleView != nil {
                    self.navigationItem.titleView!.isHidden = false
                }
            }, completion: { context in
                if context.isCancelled && self.navigationController?.topViewController != self {
                    self.navigationController?.navigationBar.tintColor = UIButton().tintColor
                }
            })
        } else {
            transitionCoordinator?.animate(alongsideTransition: { context in
                self.navigationController?.navigationBar.backgroundView?.alpha = sqrt(offset)
                
                self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = sqrt(offset)
                
                if let profileData = self.profileData {
                    self.navigationController?.navigationBar.tintColor = blend(from: .white, to: UIColor(hex: profileData.avatar.b)!, percent: Double(sqrt(offset)))
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
        
        var thresholdHeight = tableView.tableHeaderView!.frame.size.height - navigationController!.navigationBar.frame.maxY - headerTitle.frame.size.height - 2 * (blurView.frame.size.height - 21)
        
        thresholdHeight += 42
        
        let previousTintColor = navigationController!.navigationBar.tintColor
        let previousBackgroundAlpha = navigationController!.navigationBar.backgroundView!.alpha
        let previousTitleView = navigationItem.titleView
        
        var offset = ((tableView.contentOffset.y - thresholdHeight) / targetHeight)
        
        if offset > 1 {offset = 1}
        
        if offset < 0 { offset = 0 }
        
        if let extendedNavigationController = navigationController as? ExtensibleNavigationBarNavigationController {
            
            print("RUNNING AS EXTENSIVE")
            transitionCoordinator?.animate(alongsideTransition: { context in
                if self.navigationItem.titleView!.alpha == 0 {
                    self.navigationItem.titleView!.isHidden = true
                }
                
                extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = 1
                self.navigationController?.navigationBar.backgroundView?.alpha = 1
                
                self.navigationController?.navigationBar.tintColor = UIButton().tintColor
            }, completion: { context in
                if context.isCancelled && self.navigationController?.topViewController == self {
                    
                    print("CANCELLED")
                    
                    print("FROM: \(context.viewController(forKey: .from)! is RantViewController ? "RantViewController" : "ProfileTableViewController")")
                    print("TO: \(context.viewController(forKey: .from)! is RantViewController ? "RantViewController" : "ProfileTableViewController")")
                    self.navigationItem.titleView!.isHidden = false
                    extendedNavigationController.navigationBarToolbar?.subviews.first(where: { String(describing: type(of: $0)) == "_UIBarBackground" })?.alpha = previousBackgroundAlpha
                    self.navigationController?.navigationBar.backgroundView?.alpha = previousBackgroundAlpha
                    
                    self.navigationController?.navigationBar.visualEffectView?.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectBackdropView" })?.alpha = previousBackgroundAlpha
                    
                    self.navigationController?.navigationBar.tintColor = previousTintColor
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
        
        super.viewWillDisappear(animated)
    }
    
    @objc func segmentedControlSelectionChanged(_ sender: UISegmentedControl) {
        rantTypeContent.rantFeed = []
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
                    self.tableView.reloadData()
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
        
        APIRequest().getProfileFromID(self.userID, userContentType: currentContentType, skip: (currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite ? rantTypeContent.rantFeed.count : commentTypeContent.commentTypeContent.count), completionHandler: { response in
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
                            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url!)!.lastPathComponent).relativePath) {
                                self.commentContentImages.append(File(url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: attachedImage.url!)!.lastPathComponent), size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                            } else {
                                self.commentContentImages.append(File.loadFile(image: attachedImage, size: CGSize(width: attachedImage.width!, height: attachedImage.height!)))
                            }
                        } else {
                            self.commentContentImages.append(nil)
                        }
                    }
                
                    self.isFetchAlreadyInProgress = false
                
                    completionHandler?()
                }
        })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            if indexPath.row >= rantTypeContent.rantFeed.count || indexPath.row >= rantContentImages.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! SecondaryRantInFeedCell
                cell.configureLoading()
                
                cell.layoutIfNeeded()
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! SecondaryRantInFeedCell
                cell.configure(with: &rantTypeContent.rantFeed[indexPath.row], image: rantContentImages[indexPath.row], parentTableViewController: self, parentTableView: tableView)
                
                cell.layoutIfNeeded()
                
                return cell
            }
        } else {
            if indexPath.row >= commentTypeContent.commentTypeContent.count || indexPath.row >= commentContentImages.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
                cell.configureLoading()
                
                cell.layoutIfNeeded()
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
                cell.configure(with: commentTypeContent.commentTypeContent[indexPath.row], supplementalImage: commentContentImages[indexPath.row], parentTableViewController: self, parentTableView: tableView, commentInFeed: &commentTypeContent.commentTypeContent[indexPath.row], allowedToPreview: false)
                
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            if indexPath.row < rantTypeContent.rantFeed.count && indexPath.row < rantContentImages.count {
                cellHeights[indexPath] = cell.frame.size.height
            }
        } else {
            if indexPath.row < commentTypeContent.commentTypeContent.count && indexPath.row < commentContentImages.count {
                cellHeights[indexPath] = cell.frame.size.height
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            if indexPath.row >= rantTypeContent.rantFeed.count || indexPath.row >= rantContentImages.count {
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
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard blurView != nil else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.shouldUpdateBlurPosition()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        if currentContentType == .rants || currentContentType == .upvoted || currentContentType == .favorite {
            guard indexPath.row < rantTypeContent.rantFeed.count && indexPath.row < rantContentImages.count else {
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
