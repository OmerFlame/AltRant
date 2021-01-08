//
//  NotificationsNavigationViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 1/6/21.
//

import UIKit

class NotificationsNavigationViewController: UINavigationController {
    var navbarExtender: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("NAVIGATION BAR HEIGHT: \(navigationBar.frame.height)")
        
        /*navbarExtender = UIView(frame: CGRect(origin: CGPoint(x: 0, y: navigationBar.frame.height), size: CGSize(width: view.bounds.size.width, height: 50)))
        let testLabel = UILabel(frame: CGRect(x: 115.5, y: 10.5, width: 183, height: 29))
        
        testLabel.font = .systemFont(ofSize: 12)
        testLabel.text = "This label appears as part of the navigation bar."
        testLabel.numberOfLines = 0
        testLabel.preferredMaxLayoutWidth = 183
        
        navbarExtender.addSubview(testLabel)
        
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        testLabel.centerXAnchor.constraint(equalTo: navbarExtender.centerXAnchor).isActive = true
        testLabel.centerYAnchor.constraint(equalTo: navbarExtender.centerYAnchor).isActive = true
        
        view.addSubview(navbarExtender)
        navbarExtender.translatesAutoresizingMaskIntoConstraints = false
        //navbarExtender.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        topLayoutGuide.bottomAnchor.constraint(equalTo: navbarExtender.topAnchor, constant: -2 * navigationBar.frame.size.height).isActive = true
        navbarExtender.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navbarExtender.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navbarExtender.heightAnchor.constraint(equalToConstant: 50).isActive = true*/
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        children[0].additionalSafeAreaInsets = UIEdgeInsets(top: 50)
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
