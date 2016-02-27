//
//  CombinationListBaseTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class CombinationListBaseTableViewController: UITableViewController, CombinationEditTableViewControllerDelegate {
    
    struct Constants {
        struct Nib {
            static let name = "CombinationListTableViewCell"
        }
        
        struct TableViewCell {
            static let identifier = "combinationListTableViewCell"
        }
    }
    
    var folderName = ""
    var folderUUID : String?
    var combinations : [Combination] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        let nib = UINib(nibName: Constants.Nib.name, bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: Constants.TableViewCell.identifier)
        self.tableView.estimatedRowHeight = 132
        
        self.navigationItem.title = self.folderName
        
        // 余分な罫線を消す
        self.hideExtraFooterLine()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.combinations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.TableViewCell.identifier, forIndexPath: indexPath) as! CombinationListTableViewCell

        // Configure the cell...
        cell.configure(self.combinations[indexPath.row])

        return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 132
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //self.performSegueWithIdentifier("showCombinationEditTableViewControllerSegue", sender: self)
        self.pushCombinationEditTableViewControllerOnCellSelected(self.combinations[indexPath.row])
    }
    
    func pushCombinationEditTableViewControllerOnCellSelected(combination : Combination) {
        
        // Set up the detail view controller to show.
        let detailViewController = CombinationEditTableViewController.forCombination(combination)
        detailViewController.delegate = self
        detailViewController.folderUUID = self.folderUUID
        
        // Note: Should not be necessary but current iOS 8.0 bug requires it.
        self.tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: false)
        
        let newNV = UINavigationController(rootViewController: detailViewController)
        newNV.toolbarHidden = false
        self.presentViewController(newNV, animated: true, completion: nil)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let editorVC = segue.destinationViewController as? CombinationEditTableViewController {
            editorVC.delegate = self
            editorVC.folderUUID = self.folderUUID
        }
    }
    
    func didSaveCombination(combination : Combination){
        
    }
    
    func didCancelCombination(combination : Combination){
        
    }
}
