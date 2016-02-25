//
//  CategoryPickerTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryPickerTableViewController: UITableViewController, UITextFieldDelegate {
    
    var categories : [Category] = []

    var delegate : CategoryPickerTableViewControllerDelegate?
    
    @IBAction func onTapCreateNewCategoryBarButtonItem(sender: UIBarButtonItem) {
        self.showCreateNewCategoryPrompt()
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
        
        self.loadCategories()
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
        return self.categories.count
    }

    var alertActionSave : UIAlertAction?
    func showCreateNewCategoryPrompt() {
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
            print(realm.path)
            self.categories = realm.objects(Category).filter({ (dir) -> Bool in true})
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
        cell.textLabel?.text = self.categories[indexPath.row].name
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
        let modifyAction = UITableViewRowAction(style: .Normal, title: "変更"){(action, indexPath) in
            self.showRenameFolderPrompt(self.categories[indexPath.row])
            self.tableView.setEditing(false, animated: true)
        }
        modifyAction.backgroundColor = UIColor.lightGrayColor()

        return [modifyAction]
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

    // アラート表示は共通化したいけど、呼び出し元との依存を切り離せる？
    // それと、UIAlertControllerがメモリーリークするらしい（すでに直った？）
    func showRenameFolderPrompt(currentCategory : Category) {
        let alertController = UIAlertController(title: "カテゴリーの名前を変更", message: "このカテゴリーの名前を入力してください。", preferredStyle: .Alert)
        
        let alertActionSave = UIAlertAction(title: "保存", style: UIAlertActionStyle.Default) { (action) -> Void in
            if let newCategoryNameText = alertController.textFields?.first?.text, let realm = try? Realm() {
                let _ = try? realm.write {currentCategory.name = newCategoryNameText}
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
