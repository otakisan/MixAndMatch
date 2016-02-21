//
//  FolderListTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class FolderListTableViewController: FolderListBaseTableViewController, UITextFieldDelegate {

    @IBAction func onTouchNewFolderBarButtonItem(sender: UIBarButtonItem) {
        self.showCreateNewFolderPromptIfPossible()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // 編集時の選択を可能とする
        self.tableView.allowsSelectionDuringEditing = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var alertActionSave : UIAlertAction?
    func showCreateNewFolderPrompt() {
        let alertController = UIAlertController(title: "新規フォルダ", message: "このフォルダの名前を入力してください。", preferredStyle: .Alert)
        
        let alertActionSave = UIAlertAction(title: "保存", style: UIAlertActionStyle.Default) { (action) -> Void in
            if let newFolderNameText = alertController.textFields?.first?.text {
                self.createNewFolder(newFolderNameText)
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
    
    func showCreateNewFolderPromptIfPossible() {
        let maxCountOfLocalSaveFolder = AppContext.sharedInstance.maxCountOfLocalSaveFolder
        let currentCountOfFolder = try? Realm().objects(Folder).count
        if currentCountOfFolder < maxCountOfLocalSaveFolder {
            self.showCreateNewFolderPrompt()
        }else{
            self.showAlertMessage("保存数の上限に達しています。", message: "保存数の上限[\(maxCountOfLocalSaveFolder)]に達しているため、新規で追加できません。")
        }
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
    
    func createNewFolder(folderName : String) {
        print("create new folder. name : \(folderName)")
        if let realm = try? Realm() {
            
            guard realm.objects(Folder).filter("name = '\(folderName)'").count == 0 else {
                let alert = UIAlertController(title: "既に存在します。", message: "フォルダ名：\(folderName)", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            let newFolder = Folder()
            newFolder.uuid = NSUUID().UUIDString
            newFolder.name = folderName
            print("NSUUID().UUIDString : \(NSUUID().UUIDString)")
            print("uuid : \(newFolder.uuid)")
            
            let _ = try? realm.write({ () -> Void in
                realm.add(newFolder)
            })
        }
    }
    
    func showRenameFolderPrompt(currentFolder: Folder) {
        let alertController = UIAlertController(title: "フォルダの名前を変更", message: "このフォルダの新しい名前を入力してください。", preferredStyle: .Alert)
        
        let alertActionSave = UIAlertAction(title: "保存", style: UIAlertActionStyle.Default) { (action) -> Void in
            if let newFolderNameText = alertController.textFields?.first?.text, let realm = try? Realm() {
                let _ = try? realm.write { currentFolder.name = newFolderNameText }
            }
            
            self.alertActionSave = nil
            self.refreshData()
        }
        alertActionSave.enabled = currentFolder.name != ""
        self.alertActionSave = alertActionSave
        
        let alertActionCancel = UIAlertAction(title: "キャンセル", style: .Cancel, handler: nil)
        
        //textfiledの追加
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.text = currentFolder.name
            textField.placeholder = "名前"
            textField.delegate = self
        }
        
        alertController.addAction(alertActionSave)
        alertController.addAction(alertActionCancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: - Table view data source

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("folderListTableViewCell", forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = self.folders[indexPath.row].name
        cell.detailTextLabel?.text = "\(self.folders[indexPath.row].combinations.count)"

        return cell
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            // 編集モード時に下線を引くことにより、タップによるアクションが存在することを示唆する
            self.forEachCells({ (indexPath, cell) -> Void in
                cell.textLabel?.attributedText = NSAttributedString(string: self.folders[indexPath.row].name, attributes: [
                    NSForegroundColorAttributeName : UIColor.blueColor(),
                    NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue
                    ])
            })
        } else {
            self.forEachCells({ (indexPath, cell) -> Void in
                cell.textLabel?.attributedText = nil
                cell.textLabel?.text = self.folders[indexPath.row].name
            })
        }
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
            // Delete the row from the data source
            self.showOkCancelAlertMessage("本当に削除しますか？", message: "完全に削除され、元に戻せません。",
                okHandler: { alertAction in self.deleteCombinationAtIndexPath(indexPath) },
                cancelHandler: { alertAction in self.tableView.setEditing(false, animated: false) }
            )
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    func deleteCombinationAtIndexPath(indexPath : NSIndexPath) {
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                let removed = self.folders.removeAtIndex(indexPath.row)
                print("removing folder : \(removed)")
                realm.delete(removed)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
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

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.tableView.editing {
            // 編集時は、リネームダイアログを表示する
            self.showRenameFolderPrompt(self.folders[indexPath.row])
        }else{
            // 通常時は、組み合わせ一覧に遷移する
            self.performSegueWithIdentifier("showCombinationListTableViewControllerSegue", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let combinationVC = segue.destinationViewController as? CombinationListTableViewController {
            if let index = self.tableView.indexPathForSelectedRow?.row {
                combinationVC.folderUUID = self.folders[index].uuid
                combinationVC.folderName = self.folders[index].name
            }
        }
    }
    

}
