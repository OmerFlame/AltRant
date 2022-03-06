//
//  RecommendedUserCell.swift
//  AltRant
//
//  Created by Omer Shamai on 23/02/2022.
//

import UIKit
import SwiftRant
import SwiftHEXColors

class RecommendedUserCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var internalRecommendedUserTableView: UITableView!
    @IBOutlet weak var showMoreUsersButton: UILabel!
    
    var subscribedFeed: UnsafeMutablePointer<SubscribedFeed>! = nil
    
    var moreUsersButtonPressCounter = 1
    
    func configure(subscribedFeed: UnsafeMutablePointer<SubscribedFeed>) {
        internalRecommendedUserTableView.delegate = self
        internalRecommendedUserTableView.dataSource = self
        self.subscribedFeed = subscribedFeed
        
        internalRecommendedUserTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subscribedFeed.pointee.recommendedUsers.users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InternalRecommendedUserCell") as! InternalRecommendedUserCell
        
        cell.configure(userData: subscribedFeed.pointee.usernameMap.users[indexPath.row])
        
        return cell
    }
    
    class InternalRecommendedUserCell: UITableViewCell {
        @IBOutlet weak var userImageView: RoundedImageView!
        @IBOutlet weak var usernameLabel: UILabel!
        @IBOutlet weak var scoreLabel: PaddingLabel!
        
        var userData: SubscribedFeed.UsernameMap.User! = nil
        
        func configure(userData: SubscribedFeed.UsernameMap.User) {
            self.userData = userData
            
            usernameLabel.text = self.userData.username
            scoreLabel.text = "+\(self.userData.score)"
            
            userImageView.backgroundColor = UIColor(hexString: self.userData.avatar.backgroundColor)!
            
            if self.userData.avatar.avatarImage != nil {
                let session = URLSession(configuration: .default)
                
                let url = URL(string: "https://avatars.devrant.com/\(self.userData.avatar.avatarImage!)")!
                
                session.dataTask(with: url) { data, _, _ in
                    if let data = data {
                        let userImage = UIImage(data: data)
                        
                        DispatchQueue.main.async {
                            UIView.transition(with: self.userImageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                                self.userImageView.image = userImage
                            }, completion: nil)
                        }
                    }
                }.resume()
            }
        }
    }
}
