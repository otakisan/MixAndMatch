//
//  CategoryPickerTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift
import Photos

class CategoryPickerTableViewController: UITableViewController, UITextFieldDelegate {
    
    var categories : [Category] = []
    var notIncludeFolderUUIDs : [String] = []

    var delegate : CategoryPickerTableViewControllerDelegate?
    
    @IBAction func onTapCreateNewCategoryBarButtonItem(sender: UIBarButtonItem) {
        self.showCreateNewCategoryPromptIfPossible()
    }
    
    @IBAction func onTapDoneBarButtonItem(sender: UIBarButtonItem) {
        if let selectedRows = self.tableView.indexPathsForSelectedRows where selectedRows.count > 0 {
            var categoryNames : [String] = []
            selectedRows.forEach({ (indexPath) -> () in
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath), let categoryName = cell.textLabel?.text {
                    categoryNames.append(categoryName)
                }
            })
            
            self.delegate?.doneSelectCategories(categoryNames)
            if let nv = self.navigationController {
                nv.popViewControllerAnimated(true)
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // カテゴリの削除は、まだ有効化しないでおく
        //self.navigationItem.rightBarButtonItems?.append(self.editButtonItem())
        
        // サムネイル画像のサイズによって、罫線の始点にばらつきが出るので、左端に揃え、色を薄めにする
        self.tableView.separatorInset = UIEdgeInsetsZero
        self.tableView.separatorColor = UIColor(colorLiteralRed: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
        
        // 余分な罫線を消す
        self.hideExtraFooterLine()

        self.loadCategories()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initAnalysisTracker("カテゴリピッカー（CategoryPickerTableViewController）")
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.categories.count
    }

    private func showCreateNewCategoryPromptIfPossible() {
        
        let maxCountOfCategory = AppContext.sharedInstance.maxCountOfCategory
        let currentCountOfCategory = self.categories.count
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
        self.loadCategories()
        self.tableView.reloadData()
    }
    
    func loadCategories() {
        if let realm = try? Realm() {
            self.categories = realm.objects(Category).filter("NOT (uuid IN %@)", self.notIncludeFolderUUIDs).map{$0}
        }
    }

    private func setSelectedBackgroundView(cell : UITableViewCell) {
        let selectedBgView = UIView()
        selectedBgView.backgroundColor = UIColor(colorLiteralRed: (227.0/255.0), green: (236.0/255.0), blue: (248.0/255.0), alpha: 1.0)
        selectedBgView.layer.masksToBounds = true
        cell.selectedBackgroundView = selectedBgView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("categoryPickerTableViewCell", forIndexPath: indexPath)

        // Configure the cell...
        //cell.textLabel?.text = self.categories[indexPath.row].name
        // Configure the cell...
        let category = self.self.categories[indexPath.row]
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

        self.setSelectedBackgroundView(cell)
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.accessoryType = self.tableView.indexPathsForSelectedRows?.filter{$0 == indexPath}.count > 0 ? .Checkmark : .None
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            self.forEachCells{ $1.accessoryType = UITableViewCellAccessoryType.None }
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let modifyAction = UITableViewRowAction(style: .Normal, title: "名称変更"){(action, indexPath) in
            self.showRenameFolderPrompt(self.categories[indexPath.row])
            self.tableView.setEditing(false, animated: true)
        }
        modifyAction.backgroundColor = UIColor.lightGrayColor()
        let deleteAction = UITableViewRowAction(style: .Normal, title: "削除"){(action, indexPath) in
            self.deleteCategoryIfNotUsed(indexPath)
            self.tableView.setEditing(false, animated: true)
        }
        deleteAction.backgroundColor = UIColor.redColor()

        return [deleteAction, modifyAction]
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
        /*
        if editingStyle == .Delete {
            // Delete the row from the data source
            self.deleteCategoryAtIndexPath(indexPath)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        */
    }
    
    func deleteCategoryAtIndexPath(indexPath : NSIndexPath) {
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                let removed = self.categories.removeAtIndex(indexPath.row)
                print("removing folder : \(removed)")
                realm.delete(removed)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
    }

    private func deleteCategoryIfNotUsed(indexPath: NSIndexPath) {
        if self.categories[indexPath.row].combinationItems.count == 0 {
            self.showOkCancelAlertMessage("削除しますか？", message: "\(self.categories[indexPath.row].name)を削除します。", okHandler: {action in
                let removed = self.categories.removeAtIndex(indexPath.row)
                let _ = try? removed.realm?.write({ () -> Void in
                    removed.realm?.delete(removed)
                })
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }, cancelHandler: nil)
        } else {
            self.showAlertMessage("削除できません。", message: "\(self.categories[indexPath.row].name)は使用されているため、削除できません。", okHandler: nil)
        }
    }
    
    // アラート表示は共通化したいけど、呼び出し元との依存を切り離せる？
    // それと、UIAlertControllerがメモリーリークするらしい（すでに直った？）
    func showRenameFolderPrompt(currentCategory : Category) {
        let alertController = UIAlertController(title: "カテゴリーの名前を変更", message: "このカテゴリーの名前を入力してください。", preferredStyle: .Alert)
        
        let alertActionSave = UIAlertAction(title: "保存", style: UIAlertActionStyle.Default) { (action) -> Void in
            if let newCategoryNameText = alertController.textFields?.first?.text, let realm = try? Realm() {
                let _ = try? realm.write {
                    currentCategory.name = newCategoryNameText
                    currentCategory.updatedAt = NSDate()
                }
            }
            
            self.alertActionSave = nil
            self.refreshData()
        }
        
        alertActionSave.enabled = currentCategory.name != ""
        self.alertActionSave = alertActionSave
        
        let alertActionCancel = UIAlertAction(title: "キャンセル", style: .Cancel, handler: nil)
        
        //textfiledの追加
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.text = currentCategory.name
            textField.placeholder = "名前"
            textField.delegate = self
            textField.returnKeyType = .Done
        }
        
        alertController.addAction(alertActionSave)
        alertController.addAction(alertActionCancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol CategoryPickerTableViewControllerDelegate {
    func doneSelectCategories(categoryNamesSelected : [String])
}
