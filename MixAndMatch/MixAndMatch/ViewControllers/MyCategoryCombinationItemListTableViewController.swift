//
//  MyCategoryCombinationItemListTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/27.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift
import Photos

class MyCategoryCombinationItemListTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MyCategoryCombinationItemViewControllerDelegate {

    var myCategory : Category?
    var delegate : MyCategoryViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // サムネイル画像のサイズによって、罫線の始点にばらつきが出るので、左端に揃え、色を薄めにする
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.separatorColor = UIColor(colorLiteralRed: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let myCategoryContainerVc = parent as? MyCategoryContainerViewController {
            self.myCategory = myCategoryContainerVc.myCategory
            self.delegate = myCategoryContainerVc
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.myCategory?.combinationItems.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MyCategoryCombinationItemListTableViewCell", forIndexPath: indexPath)

        // Configure the cell...
        if let combinationItem = self.myCategory?.combinationItems[indexPath.row] {
            cell.textLabel?.text = combinationItem.name
            cell.detailTextLabel?.text = combinationItem.memo
            cell.imageView?.image = UIImage()
            
            PhotosUtility.requestImageForLocalIdentifier(combinationItem.localFileURL, targetSize: CGSizeMake(cell.frame.height*3, cell.frame.height*3), contentMode: .AspectFit, options: nil, resultHandler: { (image, info) -> Void in
                if let degradedKey = info![PHImageResultIsDegradedKey] where degradedKey as! NSNumber == 0, let image = image {
                    cell.imageView?.image = image
                }
            })
            
            cell.imageView?.image = ImageUtility.blankImage(CGSizeMake(cell.frame.height, cell.frame.height))
        }
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            showAlertAndDeleteCombinationItemWithCompletionBlock(indexPath) {
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                if let category = self.myCategory {
                    self.delegate?.didSaveMyCategory(category)
                }
            }
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    }
    
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
        if let vc = segue.destinationViewController as? MyCategoryCombinationItemViewController {
            if let indexPath = self.tableView.indexPathForSelectedRow, let combinationItem = self.myCategory?.combinationItems[indexPath.row] {
                vc.combinationItem = combinationItem
                vc.delegate = self
            }
        }
    }
    
    func didSaveCombinationItem(combinationItem: CombinationItem) {
        self.tableView.reloadData()
        if let category = self.myCategory {
            self.delegate?.didSaveMyCategory(category)
        }
    }

    func showAlertAndDeleteCombinationItemWithCompletionBlock(indexPath : NSIndexPath, completion : (() -> Void)?) {
        let alert = UIAlertController(title: "アイテムを削除しますか？", message: "保存済みの組み合わせで使用している場合、その組み合わせの中からも削除されます。", preferredStyle: .Alert)
        let yesAction = UIAlertAction(title: "削除します", style: .Default) { (action) -> Void in
            if let removingCombinationItem = self.myCategory?.combinationItems[indexPath.row] {
                print("removing item from the category : \(removingCombinationItem)")
                
                // 既に使用されていれば、組み合わせの中から削除する
                if let realm = removingCombinationItem.realm {
                    let _ = try? realm.write({ () -> Void in
                        // TODO: 削除対象を、親モデルから一括で削除するというのは、なんか一発で書けそうだけど…
                        // 現在編集中の組み合わせ以外で、当該アイテムを選択したら削除する
                        let combinations = realm.objects(Combination).filter("ANY combinationItems.uuid = %@", removingCombinationItem.uuid)
                        combinations.forEach({ (combi) -> () in
                            if let index = combi.combinationItems.indexOf({$0.uuid == removingCombinationItem.uuid}) {
                                combi.combinationItems.removeAtIndex(index)
                                combi.updatedAt = NSDate()
                            }
                        })
                        removingCombinationItem.category = nil
                        realm.delete(removingCombinationItem)
                        completion?()
                    })
                }
            }
        }
        let noAction = UIAlertAction(title: "キャンセルします", style: .Default) { (action) -> Void in
            
        }
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func addCombinationItem() {
        self.showImagePickerViewControllerIfPossible()
    }
    
    private func showImagePickerViewControllerIfPossible() {
        
        let maxCountOfCombinationItemsInCategory = AppContext.sharedInstance.maxCountOfCombinationItemsInCategory
        let currentCountOfCombinationItemsInCategory = self.myCategory?.combinationItems.count
        if currentCountOfCombinationItemsInCategory < maxCountOfCombinationItemsInCategory {
            self.showImagePickerViewController(.PhotoLibrary)
        } else {
            self.showAlertMessage("カテゴリー内の組み合わせアイテムの上限に達しています。", message: "カテゴリーに追加できる、組み合わせアイテムの数の上限[\(maxCountOfCombinationItemsInCategory)]に達しているため、新規で追加できません。", okHandler: nil)
        }
    }

    private func showImagePickerViewController(sourceType : UIImagePickerControllerSourceType) -> UIImagePickerController {
        let imageViewController = UIImagePickerController()
        imageViewController.sourceType = sourceType
        imageViewController.delegate = self
        imageViewController.allowsEditing = true
        self.presentViewController(imageViewController, animated: true, completion: nil)
        
        return imageViewController
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        // TODO: 動画の場合は、サイズチェック、静止画表示、データは別途保持する
        if let selectedImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
            print("selectedImageUrl : \(selectedImageUrl)")
            
            // アプリのアルバムは作成せず、指定画像のlocalIdentifierをそのまま保存する
            if let phAsset = PHAsset.fetchAssetsWithALAssetURLs([selectedImageUrl], options: nil).firstObject as? PHAsset {
                self.createCombinationItemWithCompletionBlock(phAsset.localIdentifier) { combinationItem in
                    if let category = self.myCategory {
                        self.delegate?.didSaveMyCategory(category)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func createCombinationItemWithCompletionBlock(photoLocalId : String, completion : ((combinationItem : CombinationItem) -> Void)?) {
        if let realm = try? Realm(), let category = self.myCategory {
            let _ = try? realm.write({ () -> Void in
                let combinationItem = CombinationItem()
                let createdAt = NSDate()
                combinationItem.uuid = NSUUID().UUIDString
                combinationItem.name = "新規アイテム"
                combinationItem.memo = "\(DateUtility.localDateString(createdAt)) \(DateUtility.localTimeString(createdAt))"
                combinationItem.localFileURL = photoLocalId
                combinationItem.category = category
                combinationItem.createdAt = createdAt
                combinationItem.updatedAt = combinationItem.createdAt
                realm.add(combinationItem)
                realm.add(category, update: true)
                
                completion?(combinationItem: combinationItem)
            })
        }
    }

}
