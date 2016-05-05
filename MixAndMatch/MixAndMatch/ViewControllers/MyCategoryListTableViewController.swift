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

class MyCategoryListTableViewController: UITableViewController, UITextFieldDelegate {
    
    var myCategories : [Category] = []

    @IBAction func onTapCreateNewCategoryBarButtonItem(sender: UIBarButtonItem) {
        self.showCreateNewCategoryPromptIfPossible()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initAnalysisTracker("マイカテゴリ一覧（MyCategoryListTableViewController）")

        self.encourageCreateNewCategory()
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

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.deleteCategoryIfNotUsed(indexPath)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
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
        if let myCategoryContainerVc = segue.destinationViewController as? MyCategoryContainerViewController {
            if let selected = self.tableView.indexPathForSelectedRow {
                myCategoryContainerVc.myCategory = self.myCategories[selected.row]
                myCategoryContainerVc.delegate = self
            }
        } else if let vc = segue.destinationViewController as? CombinationItemsOfMyCategoryCollectionViewController {
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
    
    // ↓↓↓ カテゴリーピッカーとの共通化候補 ↓↓↓
    private func deleteCategoryIfNotUsed(indexPath: NSIndexPath) {
        if self.myCategories[indexPath.row].combinationItems.count == 0 {
            self.showOkCancelAlertMessage("削除しますか？", message: "\(self.myCategories[indexPath.row].name)を削除します。", okHandler: {action in
                let removed = self.myCategories.removeAtIndex(indexPath.row)
                let _ = try? removed.realm?.write({ () -> Void in
                    removed.realm?.delete(removed)
                })
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }, cancelHandler: nil)
        } else {
            self.showAlertMessage("削除できません。", message: "\(self.myCategories[indexPath.row].name)は使用されているため、削除できません。", okHandler: nil)
        }
    }
    
    private func showCreateNewCategoryPromptIfPossible() {
        
        let maxCountOfCategory = AppContext.sharedInstance.maxCountOfCategory
        let currentCountOfCategory = self.myCategories.count
        if currentCountOfCategory < maxCountOfCategory {
            self.showCreateNewCategoryPrompt()
        } else {
            self.showOkCancelAlertMessage("カテゴリー数の上限に達しています。", message: "カテゴリーの数の上限[\(maxCountOfCategory)]に達しているため、新規で追加できません。", okCaption: "機能追加する", cancelCaption: "キャンセル", okHandler: {action in
                self.showViewControllerByStoryboardId(AppContext.sharedInstance.storyboardIdInAppPurchaseProductsListTableViewController, storyboardName: AppContext.sharedInstance.storyboardName, initialize: nil)
                }, cancelHandler: nil)
        }
    }
    
    var alertActionSave : UIAlertAction?
    private func showCreateNewCategoryPrompt() {
        let alertController = UIAlertController(title: "新規カテゴリー", message: "このカテゴリーの名前を入力してください。", preferredStyle: .Alert)
        
        let alertActionSave = UIAlertAction(title: "保存", style: UIAlertActionStyle.Default) { (action) -> Void in
            if let newCategoryNameText = alertController.textFields?.first?.text {
                self.createNewCategory(newCategoryNameText)
            }
            
            self.alertActionSave = nil
            self.refreshData()
        }
        
        alertActionSave.enabled = false
        self.alertActionSave = alertActionSave
        
        let alertActionCancel = UIAlertAction(title: "キャンセル", style: .Cancel, handler: nil)
        
        //textfiledの追加
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "名前"
            textField.delegate = self
            textField.returnKeyType = .Done
        }
        
        alertController.addAction(alertActionSave)
        alertController.addAction(alertActionCancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool{
        
        let replacedText = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        print("textField : \(textField.text)")
        print("range : \(range)")
        print("replacementString : \(string)")
        print("replacedText : \(replacedText)")
        
        self.alertActionSave?.enabled = replacedText != ""
        return true
    }

    func createNewCategory(categoryName : String) {
        print("create new category. name : \(categoryName)")
        if let realm = try? Realm() {
            
            guard realm.objects(Folder).filter("name = '\(categoryName)'").count == 0 else {
                let alert = UIAlertController(title: "既に存在します。", message: "カテゴリー名：\(categoryName)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            let newCategory = Category()
            newCategory.uuid = NSUUID().UUIDString
            newCategory.name = categoryName
            newCategory.creatorType = categoryCreatorTypeUser
            newCategory.createdAt = NSDate()
            newCategory.updatedAt = newCategory.createdAt
            print("NSUUID().UUIDString : \(NSUUID().UUIDString)")
            print("uuid : \(newCategory.uuid)")
            
            let _ = try? realm.write({ () -> Void in
                realm.add(newCategory)
            })
        }
    }
    
    func refreshData() {
        self.loadMyCategory()
        self.tableView.reloadData()
    }

    private func encourageCreateNewCategory() {
        if self.myCategories.count == 0 {
            self.showAlertMessage("カテゴリーを作りましょう！", message: "右下のボタンを押して、カテゴリーを作成してください。作成後、カテゴリーをタップし、アイテムを追加します。", okHandler: nil)
        }
    }
    // ↑↑↑ カテゴリーピッカーとの共通化候補 ↑↑↑
}

extension MyCategoryListTableViewController : MyCategoryViewControllerDelegate {
    func didSaveMyCategory(myCategory: Category) {
        self.refreshData()
    }
}
