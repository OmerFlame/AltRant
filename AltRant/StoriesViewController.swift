//
//  StoriesViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 2/8/21.
//

import UIKit

class StoriesViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // d55161
        //navigationController!.navigationBar.setBackgroundImage(UIImage(named: "IMG_4370"), for: .top, barMetrics: .default)
        //navigationController!.navigationBar.barTintColor = UIColor(hex: "d55161")!
        
        let image = UIImage(named: "IMG_4370")!
        let imageView = UIImageView(image: image)
        
        let appearance = UINavigationBarAppearance()
        
        appearance.largeTitleTextAttributes = [.baselineOffset: 400]
        
        appearance.configureWithOpaqueBackground()
        appearance.backgroundImage = image
        
        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        
        //navigationController!.navigationItem.titleView = imageView
        
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1000
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = "bruh \(indexPath.row)"
        
        return cell
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
