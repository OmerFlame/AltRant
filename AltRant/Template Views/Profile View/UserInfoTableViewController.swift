//
//  UserInfoTableViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 10/11/2022.
//

import UIKit

class UserInfoTableViewController: UITableViewController {
    
    @IBOutlet weak var aboutTitleCell: UITableViewCell!
    @IBOutlet weak var aboutContentCell: UITableViewCell!
    
    @IBOutlet weak var skillsTitleCell: UITableViewCell!
    @IBOutlet weak var skillsContentCell: UITableViewCell!
    
    @IBOutlet weak var locationTItleCell: UITableViewCell!
    @IBOutlet weak var locationContentCell: UITableViewCell!
    
    @IBOutlet weak var websiteTitleCell: UITableViewCell!
    @IBOutlet weak var websiteContentCell: UITableViewCell!
    
    @IBOutlet weak var githubTitleCell: UITableViewCell!
    @IBOutlet weak var githubContentCell: UITableViewCell!
    
    @IBOutlet weak var aboutTextView: UITextView!
    @IBOutlet weak var skillsTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var githubLabel: UILabel!
    
    var methodForRunningAfterLoad: ((UserInfoTableViewController) -> Void)?
    
    var indexPathsToHide = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 245
        
        aboutTextView.textContainer.lineFragmentPadding = 0
        aboutTextView.textContainerInset = .zero
        
        skillsTextView.textContainer.lineFragmentPadding = 0
        skillsTextView.textContainerInset = .zero
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(close))
        
        methodForRunningAfterLoad?(self)
        
        var sectionsToHide = [Int]()
        indexPathsToHide.forEach { if !sectionsToHide.contains($0.section) { sectionsToHide.append($0.section) } }
        
        let set = IndexSet(sectionsToHide)
        
        tableView.deleteSections(set, with: .none)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //UITableView.automaticDimension
        
        /*switch indexPath.section {
        case 0:
            if about
        }*/
        
        if indexPathsToHide.contains(where: { $0.section == indexPath.section }) {
            return .leastNonzeroMagnitude
        } else {
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if indexPathsToHide.contains(where: { $0.section == section }) {
            return .leastNonzeroMagnitude
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if indexPathsToHide.contains(where: { $0.section == section }) {
            return .leastNonzeroMagnitude
        } else {
            return super.tableView(tableView, heightForFooterInSection: section)
        }
    }
    
    /*override func numberOfSections(in tableView: UITableView) -> Int {
        var sectionsToHide = [Int]()
        
        indexPathsToHide.forEach { if !sectionsToHide.contains($0.section) { sectionsToHide.append($0.section) } }
        
        return 5 - sectionsToHide.count
    }*/
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if indexPathsToHide.contains(where: { $0.section == section }) {
            /*if section >= 4 {
                return 0
            } else {
                return self.tableView(tableView, numberOfRowsInSection: section + 1)
            }*/
            
            return 0
        } else {
            return 2
        }
    }
    
    @objc func close() {
        dismiss(animated: true)
    }
}
