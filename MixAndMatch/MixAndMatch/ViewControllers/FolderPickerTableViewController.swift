//
//  FolderPickerTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/21.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class FolderPickerTableViewController: FolderListBaseTableViewController {

    struct StoryboardConstants {
        static let storyboardName = "Main"
        static let viewControllerIdentifier = "FolderPickerTableViewController"
    }
    
    var combinations : [Combination] = []
    var delegate : FolderPickerTableViewControllerDelegate?
    
    class func forCombinations(combinations : [Combination]) -> FolderPickerTableViewController {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboardName, bundle: nil)
        
        let viewController = storyboard.instantiateViewControllerWithIdentifier(StoryboardConstants.viewControllerIdentifier) as! FolderPickerTableViewController
        viewController.combinations = combinations
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.addBarButtonItemToNavigationItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addBarButtonItemToNavigationItem() {
        self.configureRightBarButtonItem()
    }

    private func configureRightBarButtonItem() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(FolderPickerTableViewController.onTapCancelBarButtonItem(_:)))
    }
    
    func onTapCancelBarButtonItem(sender: UIBarButtonItem) {
        if self.navigationController?.viewControllers.first == self {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.didSelectFolder(self.combinations, folder: self.folders[indexPath.row])
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("folderPickerTableViewCell", forIndexPath: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = self.folders[indexPath.row].name
        cell.detailTextLabel?.text = "\(self.folders[indexPath.row].combinations.count)"
        
        return cell
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol FolderPickerTableViewControllerDelegate {
    func didSelectFolder(combinations : [Combination], folder : Folder)
}