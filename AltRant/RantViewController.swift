//
//  RantViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 12/3/20.
//

import UIKit

class RantViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    var rantID: Int?
    
    init(rantID: Int?) {
        self.rantID = rantID
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init() {
        self.init(rantID: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadingIndicator.startAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadingIndicator.stopAnimating()
            self.tableView.isHidden = false
            
            //let headerRant = RantCell.loadFromXIB() as! RantCell
            //headerRant.testConfigure()
            
            //self.tableView.tableHeaderView = headerRant
            
            self.tableView.dataSource = self
            self.tableView.register(RantCell.self, forCellReuseIdentifier: "RantCell")
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "RantCell") as! RantCell
        
        cell = RantCell.loadFromXIB() as! RantCell
        cell.testConfigure()
        
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
