//
//  ViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/1/20.
//

import UIKit
import Combine
import SwiftUI

class rantFeedData: ObservableObject {
    @Published var rantFeed = [RantInFeed]()
}

class HomeFeedTableViewController: UITableViewController {
    fileprivate var currentPage = 0
    @ObservedObject var rantFeed = rantFeedData()
    var supplementalImages = [UIImage?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //edgesForExtendedLayout = []
        
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //self.navigationController?.navigationBar.shadowImage = UIImage()
        //self.navigationController?.navigationBar.isTranslucent = true
        
        if UserDefaults.standard.integer(forKey: "DRUserID") == 0 || UserDefaults.standard.integer(forKey: "DRTokenID") == 0 || UserDefaults.standard.string(forKey: "DRTokenKey") == nil {
            
            //let loginVC = UINib(nibName: "LoginViewController", bundle: nil).instantiate(withOwner: self, options: nil)[0] as? LoginViewController
            
            let loginVC = UIStoryboard(name: "LoginViewController", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! UINavigationController
            
            loginVC.isModalInPresentation = true
            
            present(loginVC, animated: true)
        } else {
            tableView.infiniteScrollIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            tableView.infiniteScrollIndicatorMargin = 40
            tableView.infiniteScrollTriggerOffset = 500
            
            //tableView.register(RantInFeedCell.self, forCellReuseIdentifier: "RantInFeedCell")
            tableView.register(UINib(nibName: "RantInFeedCell", bundle: nil), forCellReuseIdentifier: "RantInFeedCell")
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
            }
            
            //tableView.beginInfiniteScroll(true)
            self.performFetch(nil)
            
            //edgesForExtendedLayout = 
        }
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
                
                for (idx, rant) in result.rants!.enumerated() {
                    if rant.attached_image != nil {
                        let completionSemaphore = DispatchSemaphore(value: 0)
                        
                        var image = UIImage()
                        
                        URLSession.shared.dataTask(with: URL(string: (result.rants![idx].attached_image?.url!)!)!) { data, _, _ in
                            image = UIImage(data: data!)!
                            
                            completionSemaphore.signal()
                        }.resume()
                        
                        completionSemaphore.wait()
                        let resizeMultiplier = self.getImageResizeMultiplier(imageWidth: image.size.width, imageHeight: image.size.height, multiplier: 1)
                        
                        let finalSize = CGSize(width: image.size.width / resizeMultiplier, height: image.size.height / resizeMultiplier)
                        
                        UIGraphicsBeginImageContextWithOptions(finalSize, false, resizeMultiplier)
                        image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: finalSize))
                        let newImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        self.supplementalImages.append(newImage)
                    } else {
                        self.supplementalImages.append(nil)
                    }
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
        let rant = $rantFeed.rantFeed[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RantInFeedCell") as! RantInFeedCell
        
        //cell = RantInFeedCell.loadFromXIB()
        cell.configure(with: Optional(rant), image: supplementalImages[indexPath.row], parentTableViewController: self)
        
        return cell
        
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
        if UserDefaults.standard.integer(forKey: "DRUserID") == 0 || UserDefaults.standard.integer(forKey: "DRTokenID") == 0 || UserDefaults.standard.string(forKey: "DRTokenKey") == nil {
            return 0
        } else {
            return rantFeed.rantFeed.count
        }
    }
    
    @IBAction func handleRefresh() {
        rantFeed.rantFeed = []
        supplementalImages = []
        
        tableView.reloadData()
        
        //tableView.beginInfiniteScroll(true)
        self.performFetch(nil)
        self.refreshControl!.endRefreshing()
    }
}

