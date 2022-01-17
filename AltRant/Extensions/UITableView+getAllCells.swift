//
//  UITableView+getAllCells.swift
//  AltRant
//
//  Created by Omer Shamai on 24/12/2020.
//

import UIKit

extension UITableView {
    func getAllCells() -> [UITableViewCell] {
        var cells = [UITableViewCell]()
        
        for i in 0...self.numberOfSections - 1 {
            for j in 0...self.numberOfRows(inSection: i) - 1 {
                if let cell = self.cellForRow(at: IndexPath(row: j, section: i)) {
                    cells.append(cell)
                }
            }
        }
        
        return cells
    }
    
    func getAllCells(at section: Int) -> [UITableViewCell] {
        var cells = [UITableViewCell]()
        
        for i in 0...self.numberOfRows(inSection: section) - 1 {
            if let cell = self.cellForRow(at: IndexPath(row: i, section: section)) {
                cells.append(cell)
            }
        }
        
        return cells
    }
    
    func reloadData(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() }) { _ in completion() }
    }
}
