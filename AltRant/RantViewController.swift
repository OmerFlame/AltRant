//
//  RantViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/3/20.
//

import UIKit
import SwiftUI
import QuickLook

protocol RantViewControllerDelegate {
    func vote(_ rantViewController: RantViewController, vote: Int)
}

class RantViewController: UIViewController, UITableViewDataSource, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    var delegate: RantViewControllerDelegate?
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    var didFinishLoading = false
    
    var rantID: Int?
    var tappedRant: RantCell?
    var supplementalRantImage: UIImage?
    
    var commentImages = [File?]()
    
    var rant: RantModel?
    var profile: Profile? = nil
    var ranterProfileImage: UIImage?
    var rantInFeed: Binding<RantInFeed>
    
    /*init(rantID: Int?) {
        self.rantID = rantID
        super.init(nibName: nil, bundle: nil)
    }*/
    
    /*convenience init() {
        self.init(rantID: nil)
    }*/
    
    init?(coder: NSCoder, rantID: Int, rantInFeed: Binding<RantInFeed>, supplementalRantImage: UIImage?) {
        self.rantID = rantID
        self.rantInFeed = rantInFeed
        self.supplementalRantImage = supplementalRantImage
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        //super.init(coder: coder)
        fatalError("You must use the special coder init!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if didFinishLoading == false {
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.global(qos: .userInitiated).sync {
                    self.getRant()
                    
                    if self.rant != nil {
                        self.getProfile()
                        
                        if self.rant!.user_avatar_lg.i != nil {
                            self.getRanterImage()
                        }
                        
                        DispatchQueue.main.async {
                            self.didFinishLoading = true
                            self.loadingIndicator.stopAnimating()
                            self.tableView.isHidden = false
                            
                            self.tableView.dataSource = self
                            self.tableView.register(RantCell.self, forCellReuseIdentifier: "RantCell")
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    private func getRanterImage() {
        let completionSemaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: URL(string: "https://avatars.devrant.com/\(self.rant!.user_avatar_lg.i!)")!) { data, _, _ in
            self.ranterProfileImage = UIImage(data: data!)
            
            completionSemaphore.signal()
        }.resume()
        
        completionSemaphore.wait()
        return
    }
    
    func getRant() {
        do {
            let response = try APIRequest().getRantFromID(id: self.rantID!)
            self.rant = response!.rant
        } catch {
            DispatchQueue.main.async {
                self.showAlertWithError("Could not fetch rant with ID \(self.rantID!)", retryHandler: self.getRant)
            }
        }
    }
    
    private func getProfile() {
        do {
            self.profile = try APIRequest().getProfileFromID(rant!.user_id, userContentType: .rants, skip: 0)?.profile
        } catch {
            DispatchQueue.main.async {
                self.showAlertWithError("Could not fetch profile with ID \(self.rant!.user_id)", retryHandler: self.getProfile)
            }
        }
    }
    
    fileprivate func showAlertWithError(_ error: String, retryHandler: (() -> Void)?) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: (retryHandler != nil ? { _ in retryHandler!() } : nil)))
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "RantCell") as! RantCell
        
        cell = RantCell.loadFromXIB() as! RantCell
        cell.configure(with: rant!, rantInFeed: Optional(rantInFeed), userImage: ranterProfileImage, supplementalImage: supplementalRantImage, profile: profile!, parentTableViewController: self)
        
        return cell
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return PreviewItem(url: tappedRant?.file?.previewItemURL, title: "Picture from \(tappedRant!.rantContents!.user_username)")
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        tappedRant?.supplementalImageView
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        tappedRant = nil
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    
    init(url: URL? = nil, title: String? = nil) {
        previewItemURL = url
        previewItemTitle = title
    }
}
