//
//  ProfileTableViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/9/20.
//

import UIKit

public let secondaryProfilePages: [String] = ["Rants", "++'s", "Comments", "Favorites"]

class ProfileTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
    
    init?(coder: NSCoder, userID: Int) {
        self.userID = userID
        super.init(coder: coder)
        //headerView = StretchyTableHeaderView.loadFromXIB()
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
        
        
        
        let headerGeometry = self.geometry(view: (tableView.tableHeaderView as! StretchyTableHeaderView), scrollView: scrollView)
        let titleGeometry = self.geometry(view: headerTitle, scrollView: scrollView)
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.alpha = CGFloat(sqrt(headerGeometry.largeTitleWeight))
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageContainer.alpha = CGFloat(sqrt(headerGeometry.largeTitleWeight))
        
        let largeTitleOpacity = (max(titleGeometry.largeTitleWeight, 0.5) - 0.5) * 2
        let tinyTitleOpacity = 1 - min(titleGeometry.largeTitleWeight, 0.5) * 2
        
        //(tableView.tableHeaderView as! StretchyTableHeaderView).largeHeaderTitle.alpha = CGFloat(sqrt(largeTitleOpacity))
        headerTitle.alpha = CGFloat(sqrt(largeTitleOpacity))
        blurView.contentView.subviews[1].alpha = CGFloat(sqrt(tinyTitleOpacity))
        //(tableView.tableHeaderView as! StretchyTableHeaderView).smallHeaderTitle.alpha = CGFloat(sqrt(tinyTitleOpacity))
        
        if let vfxSubview = blurView.subviews.first(where: {
            String(describing: type(of: $0)) == "_UIVisualEffectSubview"
        }) {
            vfxSubview.backgroundColor = UIColor.systemBackground.withAlphaComponent(0)
        }
        
        if let vfxBackdrop = blurView.subviews.first(where: {
            String(describing: type(of: $0)) == "_UIVisualEffectBackdropView"
        }) {
            vfxBackdrop.alpha = CGFloat(1 - sqrt(titleGeometry.largeTitleWeight))
            //vfxBackdrop.alpha = 1.0
        }
        
        var blurFrame = blurView.frame
        var titleFrame = headerTitle.frame
        
        blurFrame.origin.y = max(originalBlurRect.minY, originalBlurRect.minY + titleGeometry.blurOffset)
        titleFrame.origin.y = originalTitleRect.minY + 396
        
        blurView.frame = blurFrame
        headerTitle.frame = titleFrame
        
        currentBlurFrame = blurView.frame
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).scrollViewDidScroll(scrollView: scrollView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.navigationController?.isNavigationBarHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //headerView = StretchyTableHeaderView.loadFromXIB()
        tableView.tableHeaderView = StretchyTableHeaderView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 482))
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).containerView.backgroundColor = UIColor(hex: "d55161")!
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageContainer.backgroundColor = UIColor(hex: "d55161")!
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.backgroundColor = UIColor(hex: "d55161")!
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 382, height: 382), false, CGFloat(UIImage(named: "testheader")!.size.height / 382))
        UIImage(named: "testheader")!.draw(in: CGRect(origin: .zero, size: CGSize(width: 382, height: 382)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        (tableView.tableHeaderView as! StretchyTableHeaderView).imageView.image = newImage
        
        addTitle()
        
        currentBlurFrame = blurView.frame
        
        //originalBlurRect = (tableView.tableHeaderView as! StretchyTableHeaderView).blurView.frame
        //originalTitleRect = (tableView.tableHeaderView as! StretchyTableHeaderView).largeHeaderTitle.frame
        //originalSmallTitleRect = (tableView.tableHeaderView as! StretchyTableHeaderView).smallHeaderTitle.frame
        
        //scrollViewDidScroll(tableView)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TestCell")
        
        //let nc = NotificationCenter.default
        //nc.addObserver(self, selector: #selector(shouldUpdateBlurPosition), name: Notification.Name("ShouldUpdateBlurPosition"), object: nil)
    }
    
    func addTitle() {
        let blurEffect = UIBlurEffect(style: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: UIScreen.main.bounds.size.width, height: 44 + 32)
        
        segmentedControl = UISegmentedControl(items: secondaryProfilePages)
        segmentedControl.selectedSegmentIndex = 0
        
        segmentedControl.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width - 32, height: 32)
        
        UISegmentedControl.appearance().backgroundColor = .systemBackground
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        //UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(hex: profileData.avatar.b)!
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(hex: "d55161")!
        
        //segmentedControl.addTarget(self, action: #selector(selectionChanged(_:)), for: .valueChanged)
        
        //let scoreSize = "+\(String(profileData.score))".boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat.greatestFiniteMagnitude), options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)], context: nil).size
        //let scoreSize = "+9999".boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat.greatestFiniteMagnitude), options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)], context: nil).size
        
        //scoreLabel = PaddingLabel(withInsets: 2.5, 2.5, 5, 5)
        scoreLabel = PaddingLabel()
        scoreLabel.topInset = 2.5
        scoreLabel.bottomInset = 2.5
        scoreLabel.leftInset = 5
        scoreLabel.rightInset = 5
        scoreLabel.text = "+9999"
        scoreLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        scoreLabel.textColor = .black
        scoreLabel.backgroundColor = .white
        scoreLabel.cornerRadius = 5
        scoreLabel.clipsToBounds = true
        scoreLabel.layer.masksToBounds = true
        
        //let smallScoreLabel = PaddingLabel(withInsets: 2.5, 2.5, 5, 5)
        let smallScoreLabel = PaddingLabel()
        smallScoreLabel.topInset = 2.5
        smallScoreLabel.bottomInset = 2.5
        smallScoreLabel.leftInset = 5
        smallScoreLabel.rightInset = 5
        //smallScoreLabel.text = "+\(String(profileData.score))"
        smallScoreLabel.text = "+9999"
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
        
        //let bigLabelSize = profileData.username.boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 32 - scoreLabel.intrinsicContentSize.width, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 34, weight: .black)], context: nil).size
        
        let bigLabelSize = "OmerFlame".boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 32 - scoreLabel.intrinsicContentSize.width, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 34, weight: .black)], context: nil).size
        
        //let smallLabelSize = profileData.username.boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 32 - scoreLabel.intrinsicContentSize.width, height: CGFloat.greatestFiniteMagnitude), options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold)], context: nil).size
        
        let smallLabelSize = "OmerFlame".boundingRect(with: CGSize(width: UIScreen.main.bounds.size.width - 32 - scoreLabel.intrinsicContentSize.width, height: CGFloat.greatestFiniteMagnitude), options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .bold)], context: nil).size
        
        let largeLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bigLabelSize.width, height: largeLabelHeight.rounded(.up)))
        let smallLabel = UILabel(frame: CGRect(x: 0, y: 0, width: smallLabelSize.width, height: smallLabelHeight.rounded(.up)))
        
        largeLabel.text = "OmerFlame"
        //largeLabel.text = profileData.username
        largeLabel.font = .systemFont(ofSize: 34, weight: .black)
        largeLabel.textColor = .white
        largeLabel.adjustsFontSizeToFitWidth = true
        largeLabel.minimumScaleFactor = 0.2
        largeLabel.allowsDefaultTighteningForTruncation = true
        largeLabel.numberOfLines = 1
        
        //smallLabel.text = profileData.username
        smallLabel.text = "OmerFlame"
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
        //blurView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        blurView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        blurView.heightAnchor.constraint(equalTo: tableView.tableHeaderView!.heightAnchor).isActive = true
        
        //blurView.bottomAnchor.constraint(equalTo: tableView.tableHeaderView!.bottomAnchor).isActive = true
        
        blurView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width).isActive = true
        
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
        segmentedControl.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.size.width - 32).isActive = true
        segmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16).isActive = true
        
        if let v = tableView.tableHeaderView as? StretchyTableHeaderView {
            v.segControl = segmentedControl
        }
        
        headerTitle.updateConstraints()
        
        scrollViewDidScroll(tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        if let _ = tableView.tableHeaderView {
            scrollViewDidScroll(tableView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = tableView.tableHeaderView {
            scrollViewDidScroll(tableView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1000
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = "\(indexPath.row)"

        return cell
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        //scrollViewDidScroll(tableView)
        
        //blurView.frame = currentBlurFrame
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.shouldUpdateBlurPosition()
        }
    }
    
    @objc func shouldUpdateBlurPosition() {
        DispatchQueue.main.async {
            self.blurView.frame = self.currentBlurFrame
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
