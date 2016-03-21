//
//  MyCategoryListTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift
import Photos

class MyCategoryListTableViewController: UITableViewController {
    
    var myCategories : [Category] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "My カテゴリー"
        
        // サムネイル画像のサイズによって、罫線の始点にばらつきが出るので、左端に揃え、色を薄めにする
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.separatorColor = UIColor(colorLiteralRed: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
        
        self.loadMyCategory()
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
        return self.myCategories.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCategoryTableViewCell", forIndexPath: indexPath)

        // Configure the cell...
        let category = self.myCategories[indexPath.row]
        cell.textLabel?.text = category.name
        cell.detailTextLabel?.text = "\(category.combinationItems.count)"
        cell.imageView?.image = UIImage()
        if let img = category.combinationItems.first?.localFileURL {
            PhotosUtility.requestImageForLocalIdentifier(img, targetSize: CGSizeMake(cell.frame.height*3, cell.frame.height*3), contentMode: .AspectFit, options: nil, resultHandler: { (image, info) -> Void in
                if let degradedKey = info![PHImageResultIsDegradedKey] where degradedKey as! NSNumber == 0, let image = image {
                    cell.imageView?.image = image
                }
            })
        }
        cell.imageView?.image = ImageUtility.blankImage(CGSizeMake(cell.frame.height, cell.frame.height))

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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let vc = segue.destinationViewController as? CombinationItemsOfMyCategoryCollectionViewController {
            if let selected = self.tableView.indexPathForSelectedRow {
                vc.myCategory = self.myCategories[selected.row]
            }
        }
    }
    
    private func loadMyCategory() {
        if let realm = try? Realm() {
            self.myCategories = realm.objects(Category).filter("\(categoryCreatorTypeKey) = %@", categoryCreatorTypeUser).map{$0}
        }
    }
}
