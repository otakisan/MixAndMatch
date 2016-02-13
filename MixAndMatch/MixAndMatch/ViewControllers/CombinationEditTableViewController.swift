//
//  CombinationEditTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift
import Photos

class CombinationEditTableViewController: UITableViewController, CombinationItemCombinationEditTableViewCellDelegate, CategoryPickerTableViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CombinationEditTableViewCellDelegate {

    struct StoryboardConstants {
        static let storyboardName = "Main"
        static let viewControllerIdentifier = "CombinationEditTableViewController"
    }
    
    var categoriesForEdit : [Category] = []
    var combination : Combination?
    var folderUUID : String?
    var delegate : CombinationEditTableViewControllerDelegate?
    
    @IBAction func onTapAddCategory(sender: UIBarButtonItem) {
        self.showCategoryPickerViewControllerIfPossible()
    }
    
    private func showCategoryPickerViewControllerIfPossible() {
        guard let combination = self.combination else {
            self.showAlertMessage("有効な組み合わせ情報が存在しません。", message: nil)
            return
        }
        
        let maxCountOfCombinationItems = AppContext.sharedInstance.maxCountOfCombinationItems
        let currentCountOfCombinationItems = combination.combinationItems.count
        if currentCountOfCombinationItems < maxCountOfCombinationItems {
            self.performSegueWithIdentifier("showCategoryPickerTableViewControllerSegue", sender: self)
        } else {
            self.showAlertMessage("組み合わせアイテムの上限に達しています。", message: "１つの組み合わせ内に保存できる、組み合わせアイテムの数の上限[\(maxCountOfCombinationItems)]に達しているため、新規で追加できません。")
        }
    }

    @IBAction func onTapAddNewItem(sender: UIBarButtonItem) {
        //self.pickImage()
    }
    
    @IBAction func onTapSaveBarButtonItem(sender: UIBarButtonItem) {
        self.addOrUpdateCombination()
        self.delegate?.didSaveCombination(self.combination!)
        
        self.showAlertMessage("保存しました。", message: nil)
        
        if self.navigationController?.viewControllers.first == self {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func onTapCancelBarButtonItem(sender: UIBarButtonItem) {
        self.delegate?.didCancelCombination(self.combination!)
        if self.navigationController?.viewControllers.first == self {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    class func forCombination(combination: Combination) -> CombinationEditTableViewController {
        let storyboard = UIStoryboard(name: StoryboardConstants.storyboardName, bundle: nil)
        
        let viewController = storyboard.instantiateViewControllerWithIdentifier(StoryboardConstants.viewControllerIdentifier) as! CombinationEditTableViewController
        
        viewController.combination = combination
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        if self.navigationController?.viewControllers.first == self {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "閉じる", style: UIBarButtonItemStyle.Plain, target: self, action: "onTapCancelBarButtonItem:")
        }
        
        // 存在しない時は新規
        if self.combination == nil {
            // 新規の場合は、編集ボタン＋保存ボタン
            self.navigationItem.rightBarButtonItems?.append(self.editButtonItem())

            // 空データを設定
            self.combination = Combination()
        } else {
            // 更新の場合は、保存ボタンは不要
            self.navigationItem.rightBarButtonItem = self.editButtonItem()

            // 存在する場合は、設定済みアイテムからカテゴリを洗い出す
            self.combination?.combinationItems.forEach{print("category : \($0.category)")}
            
            // 存在するカテゴリのみ表示
            self.categoriesForEdit = self.combination?.combinationItems.filter{$0.category != nil}.map{$0.category!} ?? []
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // TODO: 初回だけに限定したほうがよい？？
        //self.selectCombinationItems()
    }
    
    func selectCombinationItems() {
        for index in 0..<self.categoriesForEdit.count {
            let indexPath = NSIndexPath(forRow: 0, inSection: index + 1)
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? CombinationItemCombinationEditTableViewCell {
                cell.selectCurrentCombinationItem()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1 + self.categoriesForEdit.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "基本情報" : self.categoriesForEdit[section - 1].name
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section > 0 ? 132 : 44
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseId = indexPath.section == 0 ? "combinationEditTableViewCell" : "combinationItemCombinationEditTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath)

        // Configure the cell...
        //if let basicInfoCell = cell as?
        if indexPath.section == 0, let nameCell = cell as? CombinationEditTableViewCell {
            nameCell.delegate = self
            nameCell.configure(self.combination!)
        } else if indexPath.section > 0, let itemCell = cell as? CombinationItemCombinationEditTableViewCell {
            itemCell.delegate = self
            if self.categoriesForEdit[indexPath.section - 1].combinationItems.count == 0 {
                cell.textLabel?.text = "(アイテムがありません。)"
            } else {
                let comboItems = self.categoriesForEdit[indexPath.section - 1].combinationItems.filter({ (item) -> Bool in
                    true
                })
                itemCell.textLabel?.text = nil
                // 保存されているものがあればそれを、新規なら、カテゴリーにぶら下がるものの中から先頭を渡す
                itemCell.configure(self.combination?.combinationItems.filter{$0.category?.uuid == self.categoriesForEdit[indexPath.section - 1].uuid}.first ?? comboItems.first!)
            }
        }

        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section > 0
    }

    private var targetCategoryNameForAddItem : String?

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let detailAction = UITableViewRowAction(style: .Normal, title: "ℹ️"){(action, indexPath) in
            self.showDetailActionSheet()
            self.tableView.setEditing(false, animated: true)
        }
        detailAction.backgroundColor = UIColor.lightGrayColor()

        let addCombinationItemAction = UITableViewRowAction(style: .Normal, title: "追加"){(action, indexPath) in
            self.showImagePickerViewControllerIfPossible(indexPath)
//            self.showImagePickerViewController(.PhotoLibrary)
//            self.targetCategoryNameForAddItem = self.categoriesForEdit[indexPath.section - 1].name
//            self.tableView.setEditing(false, animated: true)
        }
        addCombinationItemAction.backgroundColor = UIColor.greenColor()
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "削除"){(action, indexPath) in
            self.categoriesForEdit.removeAtIndex(indexPath.section - 1)
            tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Fade)
            self.tableView.setEditing(false, animated: true)
        }
        deleteAction.backgroundColor = UIColor.redColor()
        
        // 詳細情報は一旦非表示
        return [/*detailAction,*/ addCombinationItemAction, deleteAction]
    }
    
    private func showImagePickerViewControllerIfPossible(indexPath : NSIndexPath) {
        
        let maxCountOfCombinationItemsInCategory = AppContext.sharedInstance.maxCountOfCombinationItemsInCategory
        let currentCountOfCombinationItemsInCategory = self.categoriesForEdit[indexPath.section - 1].combinationItems.count
        if currentCountOfCombinationItemsInCategory < maxCountOfCombinationItemsInCategory {
            self.showImagePickerViewController(.PhotoLibrary)
            self.targetCategoryNameForAddItem = self.categoriesForEdit[indexPath.section - 1].name
            self.tableView.setEditing(false, animated: true)
        } else {
            self.showAlertMessage("カテゴリー内の組み合わせアイテムの上限に達しています。", message: "カテゴリーに追加できる、組み合わせアイテムの数の上限[\(maxCountOfCombinationItemsInCategory)]に達しているため、新規で追加できません。")
        }
    }

    func showDetailActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel) {
            action in
        }
        let deleteCombinationItemAction = UIAlertAction(title: "カテゴリからアイテムを削除", style: .Default) {
            action in
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteCombinationItemAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            // Delete the row from the data source
//            self.categoriesForEdit.removeAtIndex(indexPath.section - 1)
//            //self.tableView.reloadData()
//            tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Fade)
//            self.tableView.setEditing(false, animated: true)
//            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        } else if editingStyle == .Insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }    
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
        if let categoryPickerVC = segue.destinationViewController as? CategoryPickerTableViewController {
            categoryPickerVC.delegate = self
        }
    }
    
    func didSelectCombinationItem(combinationItem : CombinationItem){
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                if let index = self.combination?.combinationItems.indexOf({ (comboItem) -> Bool in comboItem.category?.uuid == combinationItem.category?.uuid}) {
                    self.combination?.combinationItems.replace(index, object: combinationItem)
                } else {
                    self.combination?.combinationItems.append(combinationItem)
                }
            })
        }
    }
    
    func requestForPresentViewController(viewController : UIViewController){
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    func doneSelectCategories(categoryNamesSelected : [String]){
        if let realm = try? Realm() {
            // 新規作成はカテゴリーピッカーで実施済み
            let existings = self.categoriesForEdit.map{$0.name}
            let addedCategories = categoryNamesSelected.filter({ (categoryName) -> Bool in
                return existings.filter{$0 == categoryName}.count == 0
            })
            self.categoriesForEdit += realm.objects(Category).filter("name IN %@", addedCategories)
            self.tableView.reloadData()
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
        if let categoryName = self.targetCategoryNameForAddItem, let selectedImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
            print("selectedImageUrl : \(selectedImageUrl)")
            
            var itemNameByExif = ""
            if let metadata = info[UIImagePickerControllerMediaMetadata] as? NSDictionary {
                print("metadata : \(metadata)")
                if let exif = metadata[kCGImagePropertyExifDictionary as NSString] as? NSMutableDictionary {
                    print("exif : \(exif)")
                    if let originalDateTime = exif[kCGImagePropertyExifDateTimeOriginal as NSString] as? NSDate {
                        itemNameByExif = "\(DateUtility.localDateString(originalDateTime))_\(DateUtility.localTimeString(originalDateTime))"
                    }
                }
            }
            print("itemName : \(itemNameByExif)")
            
            // 選択したものをアプリ用のアルバムに追加
            if let appAlbum = self.createOrFetchAlbum("MixAndMatch") {
                self.addAsset(appAlbum, imageUrl: selectedImageUrl, completion: { (localId) -> Void in
                    print("localId : \(localId)")
                    if let localId = localId {
                        self.createCombinationItem(categoryName, itemName: itemNameByExif, photoLocalId: localId)
                        self.reloadCategory(categoryName)
                        self.tableView.reloadData()
                    }
                })
            }
        }
        
        self.targetCategoryNameForAddItem = nil
    }
    
    func reloadCategory(categoryName : String) {
        if self.categoriesForEdit.filter({$0.name == categoryName}).count > 0 {
            if let realm = try? Realm() {
                if let nowCategory = realm.objects(Category).filter("name = %@", categoryName).first {
                    if let index = self.categoriesForEdit.indexOf({$0.name == categoryName}) {
                        self.categoriesForEdit[index] = nowCategory
                    }
                }
            }
        }
    }
    
    func createCombinationItem(categoryName : String, itemName : String, photoLocalId : String) {
        if let realm = try? Realm(), let category = realm.objects(Category).filter("name = %@", categoryName).first {
            let _ = try? realm.write({ () -> Void in
                let combinationItem = CombinationItem()
                combinationItem.uuid = NSUUID().UUIDString
                combinationItem.name = itemName
                combinationItem.localFileURL = photoLocalId
                combinationItem.category = category
                realm.add(combinationItem)
                category.combinationItems.append(combinationItem)
                realm.add(category, update: true)
            })
        }
    }
    
    func pickImage() {
        self.showImagePickerViewController(.PhotoLibrary)
    }
    
    func getPhotoAlbum(albumName : String) -> PHAssetCollection? {
    
        // ユーザ作成のアルバム一覧を指定して、PHAssetCollection をフェッチします
        let assetCollections : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumRegular, options: nil)
        // [My Album]の AssetCollection を取得します
        var myAlbum : PHAssetCollection?
        assetCollections.enumerateObjectsUsingBlock { (assetCollection, index, stop) -> Void in
            if assetCollection.localizedTitle == albumName {
                myAlbum = assetCollection as? PHAssetCollection
                stop.memory = true
            }
        }
        
        return myAlbum
    }
    
    func createOrFetchAlbum(albumName : String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localizedTitle == %@", albumName)
        let albums : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: options)
        
        var album : PHAssetCollection?
        if albums.count > 0 {
            album = albums[0] as! PHAssetCollection
        } else {
            if let _ = try? PHPhotoLibrary.sharedPhotoLibrary().performChangesAndWait({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
            }) {
                album = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: options)[0] as! PHAssetCollection
            }
        }
        
        return album
    }
    
    func addAsset(album : PHAssetCollection, imageUrl : NSURL, completion : ((localId : String?) -> Void)?) {
        print("add asset : album \(album.localizedTitle)")
        var assetLocalId : String?
        
        if let phAsset = PHAsset.fetchAssetsWithALAssetURLs([imageUrl], options: nil).firstObject as? PHAsset {
            // 同期で取得したい場合、optionsに指定 -> PHImageRequestOptions().synchronous = true
            PHImageManager.defaultManager().requestImageForAsset(phAsset, targetSize: CGSizeMake(300, 300), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info) -> Void in
                print(info)
                // 解像度の低いのと元画像と２回コールバックされる。
                //　PHImageResultIsDegradedKeyと対応する値がゼロ以外のときの画像をaddAssetsしても失敗する
                // 多分、メモリ上にしか存在しない一時的なデータだから？？
                if let degradedKey = info![PHImageResultIsDegradedKey] where degradedKey as! NSNumber == 0, let image = image {
                    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                    dispatch_async(dispatch_get_global_queue(priority, 0), {
                        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                            let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
                            assetLocalId = assetPlaceholder?.localIdentifier
                            if let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album) {
                                albumChangeRequest.addAssets([assetPlaceholder!])
                            }
                            }, completionHandler: { (success, error) in
                                print(success)
                                print(error)
                                dispatch_async(dispatch_get_main_queue(), {
                                    NSLog("Adding Image to Library -> %@", (success ? "Sucess":"Error!"))
                                    completion?(localId: assetLocalId)
                                })
                        })
                    })
                }
            })
        }
    }
    
    func addAsset(album : PHAssetCollection, imageUrl : NSURL) -> String? {
        print("add asset : album \(album.localizedTitle)")
        var assetLocalId : String?
        if let _ = try? PHPhotoLibrary.sharedPhotoLibrary().performChangesAndWait ({ () -> Void in
            if let request = PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(imageUrl) {
                if let placeholder = request.placeholderForCreatedAsset {
                    let localIdentier = placeholder.localIdentifier
                    if let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album) {
                        // アルバムに追加されない。なぜ？
                        // 新規のイメージしか追加できない？？
                        assetCollectionChangeRequest.addAssets([placeholder])
                        assetLocalId = localIdentier
                    }
                }
            }
        }){
            
        }
        
        return assetLocalId
    }
    
    func addOrUpdateCombination(){
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                // name, combinationItemsは設定済み
                if self.combination?.uuid == "" {
                    self.combination?.uuid = NSUUID().UUIDString
                    self.combination?.createdAt = NSDate(timeIntervalSinceNow: 0)
                }
                self.combination?.folder = realm.objects(Folder).filter("uuid = %@", self.folderUUID ?? "").first
                if let index = self.combination?.folder?.combinations.indexOf({$0.uuid == self.combination?.uuid}) {
                    self.combination?.folder?.combinations.replace(index, object: self.combination!)
                } else {
                    self.combination?.folder?.combinations.append(self.combination!)
                }
                
                print("save combination : \(self.combination)")
                
                realm.add(self.combination!, update: true)
            })
        }
    }
    
    func nameTextChanged(changedText : String){
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                self.combination?.name = changedText
            })
        }
    }
}

protocol CombinationEditTableViewControllerDelegate {
    func didSaveCombination(combination : Combination)
    func didCancelCombination(combination : Combination)
}