//
//  WeeklyRantFeedViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 08/09/2022.
//

import UIKit
import SwiftRant
import ADNavigationBarExtension

class WeeklyRantFeedViewController: UITableViewController, HomeFeedTableViewControllerDelegate {
    fileprivate var currentPage = 0
    
    var week = -1
    var feeds = [RantFeed]()
    var supplementalImages = [IndexPath:File]()
    
    var cellHeights = [IndexPath:CGFloat]()
    
    var isLoading = false
    
    var weeklyRantHeader: WeeklyRantHeaderSmall!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: "LoadingCell")
        tableView.register(UINib(nibName: "RantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.shadowColor = .clear
        
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.clipsToBounds = true
        
        isLoading = true
        performFetch {
            DispatchQueue.main.async {
                self.refreshControl!.endRefreshing()
                self.isLoading = false
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    fileprivate func performFetch(_ completionHandler: (() -> Void)?) {
        var combinedRantInFeedCount = 0
        
        for feed in feeds {
            combinedRantInFeedCount += feed.rants.count
        }
        
        SwiftRant.shared.getWeeklyRants(token: nil, skip: combinedRantInFeedCount, week: week) { [weak self] result in
            defer { completionHandler?() }
            
            if case .success(let feed) = result {
                
                //self?.weeklyRantHeader.titleLabel =
                
                //tableView.tableHeaderView = UINib(nibName: "WeeklyRantHeaderMedium", bundle: nil).instantiate(withOwner: nil)[0] as! WeeklyRantHeaderMedium
                
                if !feed.rants.isEmpty {
                    let (start, end) = (combinedRantInFeedCount, feed.rants.count + combinedRantInFeedCount)
                    let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                    
                    self?.feeds.append(feed)
                    
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
                    
                    DispatchQueue.main.async {
                        self?.weeklyRantHeader = UINib(nibName: "WeeklyRantHeaderMedium", bundle: nil).instantiate(withOwner: nil)[0] as! WeeklyRantHeaderSmall
                        
                        self?.weeklyRantHeader.titleLabel.text = feed.news!.headline
                        self?.weeklyRantHeader.subtitleLabel.text = feed.news!.footer
                        self?.weeklyRantHeader.frame.size.height = 65
                        
                        //self?.tableView.tableHeaderView = self?.weeklyRantHeader
                        
                        (self?.navigationController as! ExtensibleNavigationBarNavigationController).setNavigationBarExtensionView(self?.weeklyRantHeader, forHeight: 65)
                        
                        CATransaction.begin()
                        
                        CATransaction.setCompletionBlock {
                            self?.tableView.reloadData()
                        }
                        
                        self?.tableView.beginUpdates()
                        self?.tableView.insertRows(at: indexPaths, with: .automatic)
                        self?.tableView.endUpdates()
                        
                        CATransaction.commit()
                    }
                } else {
                    return
                }
            } else if case .failure(let failure) = result {
                DispatchQueue.main.async {
                    self?.showAlertWithError(failure.message)
                }
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! RantInFeedCell
            
            var counter = 0
            var feedOffset = 0
            var rantOffset = 0
            
            for (idx, feed) in feeds.enumerated() {
                if counter + (feed.rants.count - 1) < indexPath.row {
                    counter += (feed.rants.count - 1)
                    feedOffset = idx
                    continue
                } else {
                    rantOffset = indexPath.row - counter
                }
            }
            
            cell.configure(with: Optional(feeds[feedOffset].rants[rantOffset]), image: supplementalImages[indexPath], parentTableViewController: self, parentTableView: tableView)
            
            cell.delegate = self
            
            cell.layoutIfNeeded()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath) as! LoadingCell
            cell.activityIndicator.startAnimating()
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView(tableView, cellForRowAt: indexPath)
        
        performSegue(withIdentifier: "RantInFeedCell", sender: (self.tableView(tableView, cellForRowAt: indexPath) as! RantInFeedCell))
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
                
                for feed in feeds {
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
    
    @IBAction func handleRefresh(_ sender: Any) {
        isLoading = true
        currentPage = 0
        
        feeds = []
        supplementalImages = [:]
        
        tableView.reloadData()
        
        performFetch {
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
            rantViewController.rantID = (sender as! RantInFeedCell).rantContents!.id
            
            rantViewController.homeFeedDelegate = self
            
            rantViewController.supplementalRantImage = (sender as! RantInFeedCell).supplementalImage
            rantViewController.loadCompletionHandler = nil
        } else if segue.identifier == "AfterCompose", let rantViewController = segue.destination as? RantViewController {
            rantViewController.rantID = sender as! Int
            rantViewController.rantInFeed = nil
            rantViewController.supplementalRantImage = nil
            rantViewController.loadCompletionHandler = nil
        }
    }
    
    @IBAction func openComposeView(_ sender: Any) {
        let composeVC = UIStoryboard(name: "ComposeViewController", bundle: nil).instantiateViewController(identifier: "ComposeViewController") as! UINavigationController
        (composeVC.viewControllers.first as! ComposeViewController).rantID = nil
        (composeVC.viewControllers.first as! ComposeViewController).isComment = false
        (composeVC.viewControllers.first as! ComposeViewController).isEdit = false
        (composeVC.viewControllers.first as! ComposeViewController).viewControllerThatPresented = self
        (composeVC.viewControllers.first as! ComposeViewController).tags = "wk\(feeds[0].weeklyRantWeek!),"
        
        composeVC.isModalInPresentation = true
        
        present(composeVC, animated: true, completion: nil)
    }
    
    private func indexOfRant(withID id: Int) -> IndexPath? {
        for (feedIdx, feed) in feeds.enumerated() {
            if let rantIdx = feed.rants.firstIndex(where: { $0.id == id }) {
                return IndexPath(row: rantIdx, section: feedIdx)
            }
        }
        
        return nil
    }
    
    func changeRantVoteState(rantID id: Int, voteState: VoteState) {
        let rantIndex = indexOfRant(withID: id)
        
        if let rantIndex = rantIndex {
            feeds[rantIndex.section].rants[rantIndex.row].voteState = voteState
            
            //tableView.reloadData()
        }
    }
    
    func changeRantScore(rantID id: Int, score: Int) {
        let rantIndex = indexOfRant(withID: id)
        
        if let rantIndex = rantIndex {
            feeds[rantIndex.section].rants[rantIndex.row].score = score
            
            //tableView.reloadData()
        }
    }
    
    func didVoteOnRant(withID id: Int, vote: VoteState, cell: RantInFeedCell) {
        let rantIndex = indexOfRant(withID: id)
        
        guard let rantIndex = rantIndex else {
            let alertController = UIAlertController(title: "Error", message: "Could not find rant in the feed. Please file in a bug report!", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            return
        }

        
        SwiftRant.shared.voteOnRant(nil, rantID: id, vote: vote) { [weak self] result in
            if case .success(let updatedRant) = result {
                self?.feeds[rantIndex.section].rants[rantIndex.row].voteState = updatedRant.voteState
                self?.feeds[rantIndex.section].rants[rantIndex.row].score = updatedRant.score
                
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
    
    func reloadData() {
        self.reloadData()
    }
}

extension WeeklyRantFeedViewController: ExtensibleNavigationBarInformationProvider {
    var shouldExtendNavigationBar: Bool { return true }
}
