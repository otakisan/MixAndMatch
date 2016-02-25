//
//  UIViewControllerExtensions.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlertMessage(title : String?, message : String?, okHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: okHandler))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showOkCancelAlertMessage(title : String?, message : String?, okHandler: ((UIAlertAction) -> Void)?, cancelHandler: ((UIAlertAction) -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: okHandler))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .Cancel, handler: cancelHandler))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension UITableViewController {
    func forEachCells( block : ((indexPath : NSIndexPath, cell : UITableViewCell) -> Void) ) {
        for sectionIndex in 0..<self.tableView.numberOfSections {
            for rowIndex in 0..<self.tableView.numberOfRowsInSection(sectionIndex){
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowIndex, inSection: sectionIndex)){
                    block(indexPath: NSIndexPath(forRow: rowIndex, inSection: sectionIndex), cell: cell)
                }
            }
        }
    }
}