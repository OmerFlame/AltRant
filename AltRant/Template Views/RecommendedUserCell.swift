//
//  RecommendedUserCell.swift
//  AltRant
//
//  Created by Omer Shamai on 23/02/2022.
//

import UIKit
import SwiftRant
import SwiftHEXColors

protocol InternalRecommendedUserCellDelegate {
    func didSubscribe(to user: SubscribedFeed.UsernameMap.User)
    
    func didCloseRecommendation(of user: SubscribedFeed.UsernameMap.User)
}

class RecommendedUserCell: UITableViewCell, UICollectionViewDelegate, InternalRecommendedUserCellDelegate, UICollectionViewDelegateFlowLayout {
    // TODO: - ADD SUBSCRIBE/UNSUBSCRIBE FUNCTIONALITY!
    //@IBOutlet weak var internalRecommendedUserTableView: UITableView!
    @IBOutlet weak var internalRecommendedUserCollectionView: UICollectionView!
    
    //@IBOutlet weak var showMoreUsersButton: UILabel!
    @IBOutlet weak var showMoreUsersButton: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    var subscribedFeed: UnsafeMutablePointer<SubscribedFeed>! = nil
    var parentTableView: UITableView! = nil
    
    var moreUsersButtonPressCounter = 1
    
    var lastDataSourceItemIndexInSubscribedFeed = 2
    
    var subscribedUsers = [Int]()
    var closedUsers = [Int]()
    
    var imageDownloadSemaphore = DispatchSemaphore(value: 1)
    
    var concurrentQueue = DispatchQueue(label: "thread-safe-subscribed-users-array-access-queue", attributes: .concurrent)
    
    enum Section: Int, CaseIterable, Hashable {
        case recommendedUsers
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, SubscribedFeed.UsernameMap.User>
    
    //lazy var dataSource = makeDataSource()
    //var collectionView: UICollectionView! = nil
    
    
    
    var dataSource: UICollectionViewDiffableDataSource<Section, SubscribedFeed.UsernameMap.User>! = nil
    
    func configure(subscribedFeed: UnsafeMutablePointer<SubscribedFeed>, parentTableView: UITableView) {
        //internalRecommendedUserCollectionView.delegate = self
        //internalRecommendedUserCollectionView.dataSource = self
        
        self.subscribedFeed = subscribedFeed
        self.parentTableView = parentTableView
        
        //var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        //config.backgroundColor = .clear
        
        //var layout = UICollectionViewCompositionalLayout.list(using: config)
        
        
        
        //internalRecommendedUserCollectionView.collectionViewLayout = layout
        
        
        //let cellNib = UINib(nibName: "InternalRecommendedUserCell", bundle: nil)
        
        //internalRecommendedUserCollectionView.register(cellNib, forCellWithReuseIdentifier: "InternalRecommendedUserCell")
        
        //configureLayout()
        //applyInitialSnapshots()
        
        //configureHierarchy()
        internalRecommendedUserCollectionView.collectionViewLayout = createLayout()
        internalRecommendedUserCollectionView.delegate = self
        configureDataSource()
        
        //internalRecommendedUserCollectionView.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: 0, right: 0)
        
        //internalRecommendedUserCollectionView.heightAnchor.constraint(equalToConstant: internalRecommendedUserCollectionView.collectionViewLayout.collectionViewContentSize.height).isActive = true
        
        //let height = internalRecommendedUserCollectionView.collectionViewLayout.collectionViewContentSize.height
        
        //collectionViewHeight.constant = internalRecommendedUserCollectionView.collectionViewLayout.collectionViewContentSize.height
        //layoutIfNeeded()
        
        contentView.layoutIfNeeded()
    }
    
    func createLayout() -> UICollectionViewLayout {
        //var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        //config.showsSeparators = false
        
        //let layout = UICollectionViewCompositionalLayout.list(using: config)
        //return UICollectionViewCompositionalLayout.list(using: config)
        
        return UICollectionViewCompositionalLayout { [unowned self] section, layoutEnvironment in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(61))
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.interGroupSpacing = 8
            
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            
            let config = UICollectionViewCompositionalLayoutConfiguration()
            
            config.scrollDirection = .vertical
            
            let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
            
            
            
            //var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            //config.showsSeparators = false
            
            
            //let listSection = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
            //listSection.interGroupSpacing = 8
            
            
            
            return section
        }
    }
    
    func configureDataSource() {
        /*let cellRegistration = UICollectionView.CellRegistration<InternalRecommendedUserCell, SubscribedFeed.UsernameMap.User> { cell, indexPath, item in
            return .init(cellNib: UINib(nibName: "InternalRecommendedUserCell", bundle: nil)) { cell, _, item in
                cell.configure(userData: item)
            }
        }*/
        
        let cellRegistration = UICollectionView.CellRegistration<InternalRecommendedUserCell, SubscribedFeed.UsernameMap.User>(cellNib: UINib(nibName: "InternalRecommendedUserCell", bundle: nil)) { cell, _, item in
            cell.configure(userData: item)
            cell.fetchAndSetUserImage(downloadSemaphore: self.imageDownloadSemaphore)
            cell.delegate = self
            
            if self.subscribedUsers.contains(item.userID) {
                cell.subscribeButton.setTitle("Subscribed", for: .normal)
                cell.subscribeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
                cell.subscribeButton.tintColor = .label
            } else {
                cell.subscribeButton.setTitle("Subscribe", for: .normal)
                cell.subscribeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
                cell.subscribeButton.tintColor = .systemGray
            }
        }
        
        if dataSource == nil {
            dataSource = UICollectionViewDiffableDataSource<Section, SubscribedFeed.UsernameMap.User>(collectionView: internalRecommendedUserCollectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: SubscribedFeed.UsernameMap.User) -> UICollectionViewCell? in
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
        
        //var snapshot = NSDiffableDataSourceSnapshot<Section, SubscribedFeed.UsernameMap.User>()
        var snapshot = dataSource.snapshot()
        if snapshot.numberOfSections == 0 {
            snapshot.appendSections([.recommendedUsers])
        }
        //snapshot.appendItems(Array(subscribedFeed.pointee.usernameMap.users[0..<(3 * moreUsersButtonPressCounter <= subscribedFeed.pointee.usernameMap.users.count ? 3 * moreUsersButtonPressCounter : subscribedFeed.pointee.usernameMap.users.count)]))
        
        snapshot.appendItems(Array(subscribedFeed.pointee.usernameMap.users[0...lastDataSourceItemIndexInSubscribedFeed]).filter { !closedUsers.contains($0.userID) })
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
        
        //let height = internalRecommendedUserCollectionView.collectionViewLayout.collectionViewContentSize.height
        
        // The height of a single recommended user cell is 69 points, so we need to set the height to the amount of recommended users we have times 69!
        
        //collectionViewHeight.constant = CGFloat(69 * (3 * moreUsersButtonPressCounter <= subscribedFeed.pointee.usernameMap.users.count ? 3 * moreUsersButtonPressCounter : subscribedFeed.pointee.usernameMap.users.count))
        
        collectionViewHeight.constant = CGFloat(69 * (lastDataSourceItemIndexInSubscribedFeed + 1 - closedUsers.count))
        
        internalRecommendedUserCollectionView.layoutIfNeeded()
        
        //internalRecommendedUserCollectionView.collectionViewLayout.invalidateLayout()
        //internalRecommendedUserCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    @IBAction func showMoreUsers() {
        moreUsersButtonPressCounter += 1
        var snapshot = NSDiffableDataSourceSnapshot<Section, SubscribedFeed.UsernameMap.User>()
        snapshot.appendSections([.recommendedUsers])
        
        let numberOfCellsToAdd = 3 * moreUsersButtonPressCounter <= subscribedFeed.pointee.usernameMap.users.count ? 3 * moreUsersButtonPressCounter : subscribedFeed.pointee.usernameMap.users.count
        
        // If we have 3 or more recommended users that haven't been shown yet, then add 3 cells. If there are less than 3, then show the remaining recommended users in the array.
        //let numberOfCellsToAdd = subscribedFeed.pointee.usernameMap.users.count - (3 * moreUsersButtonPressCounter) >= 3 ? 3 : subscribedFeed.pointee.usernameMap.users.count - (3 * moreUsersButtonPressCounter)
        
        // Add the next numberOfCellsToAdded amount of users to the snapshot, starting from the last user we displayed.
        
        let usersToAdd = Array(subscribedFeed.pointee.usernameMap.users[0..<numberOfCellsToAdd]).filter { !self.closedUsers.contains($0.userID) }
        
        //snapshot.appendItems(Array(subscribedFeed.pointee.usernameMap.users[(lastDataSourceItemIndexInSubscribedFeed + 1)..<(lastDataSourceItemIndexInSubscribedFeed + numberOfCellsToAdd)]))
        
        snapshot.appendItems(usersToAdd)
        
        // Set the index of the last recommended user we displayed in the collection view to the index of the last user we just added to the snapshot.
        
        UIView.transition(with: internalRecommendedUserCollectionView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.collectionViewHeight.constant += CGFloat(69 * (numberOfCellsToAdd - 1 - self.lastDataSourceItemIndexInSubscribedFeed))
            
            if 3 * self.moreUsersButtonPressCounter >= self.subscribedFeed.pointee.usernameMap.users.count {
                self.showMoreUsersButton.isHidden = true
            }
            
            self.internalRecommendedUserCollectionView.collectionViewLayout.invalidateLayout()
        }, completion: { _ in self.lastDataSourceItemIndexInSubscribedFeed = numberOfCellsToAdd - 1
        })
        
        parentTableView.beginUpdates()
        parentTableView.endUpdates()
        
        /*dataSource.apply(snapshot, animatingDifferences: true, completion: {
            self.dataSource.apply(snapshot, animatingDifferences: false)
        })*/
        //self.internalRecommendedUserCollectionView.collectionViewLayout.invalidateLayout()
        
        dataSource.apply(snapshot, animatingDifferences: true)
        internalRecommendedUserCollectionView.layoutIfNeeded()
    }
    
    func didSubscribe(to user: SubscribedFeed.UsernameMap.User) {
        // I tried making this thread-safe to the best of my ability. Only time will tell if this is going to be another source of crashes in the app.
        
        var isUserInSubscribedList: Bool!
        
        concurrentQueue.sync {
            isUserInSubscribedList = self.subscribedUsers.contains(user.userID)
        }
        
        if !isUserInSubscribedList {
            concurrentQueue.async(flags: .barrier) {
                self.subscribedUsers.append(user.userID)
                
                //let indexPath = dataSource.indexPath(for: user)
                
                var snapshot = self.dataSource.snapshot()
                
                snapshot.reconfigureItems([user])
                
                //snapshot.reloadItems([user])
                
                DispatchQueue.main.async {
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
            }
            
            SwiftRant.shared.subscribeToUser(nil, userID: user.userID) { result in
                if case .success() = result {
                    /*self.subscribedUsers.append(user.userID)
                    
                    //let indexPath = dataSource.indexPath(for: user)
                    
                    var snapshot = self.dataSource.snapshot()
                    
                    snapshot.reconfigureItems([user])
                    self.dataSource.apply(snapshot, animatingDifferences: false)*/
                } else if case .failure(let failure) = result {
                    self.concurrentQueue.async(flags: .barrier) {
                        self.subscribedUsers.removeAll(where: { $0 == user.userID })
                        
                        var snapshot = self.dataSource.snapshot()
                        
                        snapshot.reconfigureItems([user])
                        
                        //snapshot.reloadItems([user])
                        
                        DispatchQueue.main.async {
                            self.dataSource.apply(snapshot, animatingDifferences: false)
                            
                            let alertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.didSubscribe(to: user) }))
                            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                            
                            self.parentViewController?.present(alertController, animated: true)
                        }
                    }
                }
            }
        } else {
            self.concurrentQueue.async(flags: .barrier) {
                self.subscribedUsers.removeAll(where: { $0 == user.userID })
                
                var snapshot = self.dataSource.snapshot()
                
                snapshot.reconfigureItems([user])
                
                //snapshot.reloadItems([user])
                
                DispatchQueue.main.async {
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
            }
            
            SwiftRant.shared.unsubscribeFromUser(nil, userID: user.userID) { result in
                if case .success() = result {
                    /*self.subscribedUsers.removeAll(where: { $0 == user.userID })
                    
                    var snapshot = self.dataSource.snapshot()
                    
                    snapshot.reconfigureItems([user])
                    self.dataSource.apply(snapshot, animatingDifferences: false)*/
                } else if case .failure(let failure) = result {
                    self.concurrentQueue.async(flags: .barrier) {
                        self.subscribedUsers.append(user.userID)
                        
                        var snapshot = self.dataSource.snapshot()
                        
                        snapshot.reconfigureItems([user])
                        
                        //snapshot.reloadItems([user])
                        
                        DispatchQueue.main.async {
                            self.dataSource.apply(snapshot, animatingDifferences: false)
                            
                            let alertController = UIAlertController(title: "Error", message: failure.message, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.didSubscribe(to: user) }))
                            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                            
                            self.parentViewController?.present(alertController, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    func didCloseRecommendation(of user: SubscribedFeed.UsernameMap.User) {
        closedUsers.append(user.userID)
        var snapshot = dataSource.snapshot()
        
        snapshot.deleteItems([user])
        
        dataSource.apply(snapshot, animatingDifferences: true, completion: {
            self.dataSource.apply(snapshot, animatingDifferences: false)
        })
        
        UIView.transition(with: internalRecommendedUserCollectionView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.collectionViewHeight.constant -= 69
            
            /*if 3 * self.moreUsersButtonPressCounter >= self.subscribedFeed.pointee.usernameMap.users.count {
                self.showMoreUsersButton.isHidden = true
            }*/
        }, completion: nil)
        
        parentTableView.beginUpdates()
        parentTableView.endUpdates()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 69)
    }
}

class InternalRecommendedUserCell: UICollectionViewCell {
    @IBOutlet weak var usernameStackView: UIStackView!
    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var scoreLabel: PaddingLabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    var userData: SubscribedFeed.UsernameMap.User! = nil
    
    var delegate: InternalRecommendedUserCellDelegate? = nil
    
    var shouldSetImage = true
    
    var downloadTask: URLSessionDataTask? = nil
    
    var downloadSemaphore: DispatchSemaphore! = nil
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        usernameLabel.text = ""
        scoreLabel.text = ""
        userImageView.image = nil
        userData = nil
        
        downloadTask?.cancel()
        downloadTask = nil
        
        downloadSemaphore.signal()
        
        downloadSemaphore = nil
    }
    
    func configure(userData: SubscribedFeed.UsernameMap.User) {
        self.userData = userData
        
        usernameLabel.text = self.userData.username
        scoreLabel.text = "+\(self.userData.score)"
        
        imageViewHeight.constant = 45
        
        userImageView.backgroundColor = UIColor(hexString: self.userData.avatar.backgroundColor)!
        
        //userImageView.image = nil
        
        contentView.layoutIfNeeded()
        
        usernameStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUserTap)))
        userImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUserTap)))
    }
    
    func fetchAndSetUserImage(downloadSemaphore: DispatchSemaphore) {
        self.downloadSemaphore = downloadSemaphore
        if self.userData.avatar.avatarImage != nil {
            if FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: self.userData.avatar.avatarImage!)!.lastPathComponent).relativePath) {
                let userImage = UIImage(contentsOfFile: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: self.userData.avatar.avatarImage!)!.lastPathComponent).relativePath)
                
                userImageView.image = userImage
            } else {
                let url = URL(string: "https://avatars.devrant.com/\(self.userData.avatar.avatarImage!)")!
                //userImageView.image = nil
                DispatchQueue.global(qos: .userInitiated).async {
                    downloadSemaphore.wait()
                    
                    self.downloadTask = URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data {
                            FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: self.userData.avatar.avatarImage!)!.lastPathComponent).relativePath, contents: data, attributes: nil)
                            
                            let userImage = UIImage(data: data)
                            
                            DispatchQueue.main.async {
                                UIView.transition(with: self.userImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                                    self.userImageView.image = userImage
                                }, completion: { _ in
                                    downloadSemaphore.signal()
                            })
                        }
                    }
                }
                    
                self.downloadTask?.resume()
            }
            //let session = URLSession(configuration: .default)
                
                /*URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        //FileManager.default.createFile(atPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(URL(string: self.userData.avatar.avatarImage!)!.lastPathComponent).relativePath, contents: data, attributes: nil)
                        
                        let userImage = UIImage(data: data)
                        
                        DispatchQueue.main.async {
                            if self.shouldSetImage {
                                UIView.transition(with: self.userImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                                    self.userImageView.image = userImage
                                }, completion: { _ in downloadSemaphore.signal() })
                            }
                        }
                    }
                }.resume()*/
            }
            
            /*DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.main.async {
                    UIView.transition(with: self.userImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                        self.userImageView.image = UIImage(named: "devtea")
                    }, completion: nil)
                }
            }*/
        }
    }
    
    @IBAction func subscribeHandler(_ sender: Any) {
        
        delegate?.didSubscribe(to: userData)
    }
    
    @IBAction func closeHandler() {
        delegate?.didCloseRecommendation(of: userData)
    }
    
    @objc func handleUserTap() {
        if let parentNavigationController = self.parentNavigationController {
            let profileVC = UIStoryboard(name: "ProfileTableViewController", bundle: nil).instantiateViewController(identifier: "ProfileTableViewController", creator: { coder in
                return ProfileTableViewController(coder: coder, userID: self.userData.userID)
            })
            
            parentNavigationController.pushViewController(profileVC, animated: true)
        }
    }
}
