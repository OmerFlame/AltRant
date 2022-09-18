//
//  WeeksViewController.swift
//  AltRant
//
//  Created by Omer Shamai on 15/09/2022.
//

import UIKit
import SwiftRant

class WeeksTableViewController: UITableViewController {
    var weekList: WeeklyList!
    //var isLoading = false
    
    var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        
        //tableView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellReuseIdentifier: "LoadingCell")
        
        //isLoading = true
        
        
        loadingIndicator = UIActivityIndicatorView()
        
        loadingIndicator?.hidesWhenStopped = true
        
        tableView.addSubview(loadingIndicator!)
        
        loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator?.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        loadingIndicator?.centerYAnchor.constraint(equalTo: tableView.centerYAnchor).isActive = true
        
        loadingIndicator?.startAnimating()
        
        performFetch(nil)
    }
    
    fileprivate func performFetch(_ completionHandler: (() -> Void)?) {
        SwiftRant.shared.getWeekList(token: nil) { [weak self] result in
            defer { completionHandler?() }
            
            if case .success(let list) = result {
                self?.weekList = list
                
                let (start, end) = (0, list.weeks.count)
                let indexPaths = (start..<end).map { return IndexPath(row: $0, section: 0) }
                
                DispatchQueue.main.async {
                    self?.loadingIndicator?.stopAnimating()
                    //self?.isLoading = false
                    
                    CATransaction.begin()
                    
                    CATransaction.setCompletionBlock {
                        self?.tableView.reloadData()
                    }
                    
                    self?.tableView.beginUpdates()
                    self?.tableView.insertRows(at: indexPaths, with: .automatic)
                    self?.tableView.endUpdates()
                    
                    CATransaction.commit()
                }
            } else if case .failure(let failure) = result {
                DispatchQueue.main.async {
                    self?.showAlertWithError(failure.message)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weekList?.weeks.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeekCell") as! WeekCell
        
        cell.subjectLabel.text = weekList.weeks[indexPath.row].prompt
        cell.weekLabel.text = "Week \(weekList.weeks[indexPath.row].week) - \(weekList.weeks[indexPath.row].date)"
        
        var attributedTitle = NSMutableAttributedString(string: "\(weekList.weeks[indexPath.row].rantCount)")
        
        let attributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
        ]
        
        attributedTitle.addAttributes(attributes, range: NSRange(location: 0, length: attributedTitle.length))
        
        cell.rantCountLabel.setAttributedTitle(attributedTitle, for: .normal)
        
        
        cell.layoutSubviews()
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "WeeklyRant", let weeklyRantFeedViewController = segue.destination as? WeeklyRantFeedViewController {
            let idxPath = tableView.indexPath(for: sender as! UITableViewCell)!
            
            let weekly = weekList.weeks[idxPath.row]
            
            weeklyRantFeedViewController.week = weekly.week
        }
    }
    
    fileprivate func showAlertWithError(_ error: String) {
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.performFetch(nil) }))
        present(alert, animated: true, completion: nil)
    }
}
