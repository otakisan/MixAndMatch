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

class CombinationEditTableViewController: UITableViewController, CombinationItemCombinationEditTableViewCellDelegate, CategoryPickerTableViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CombinationEditTableViewCellDelegate, RearrangeTableViewControllerDelegate {

    struct StoryboardConstants {
        static let storyboardName = "Main"
        static let viewControllerIdentifier = "CombinationEditTableViewController"
    }
    
    var categoriesForEdit : [Category] = []
    var combination : Combination?
    var folderUUID : String?
    var delegate : CombinationEditTableViewControllerDelegate?
    
    @IBOutlet weak var rearrangeBarButtonItem: UIBarButtonItem!
    @IBAction func onTapRearrangeBarButtonItem(sender: UIBarButtonItem) {
        if self.categoriesForEdit.count == self.combination?.combinationItems.count {
            self.showRearrangeTableViewController()
        } else {
            self.showAlertMessage("カテゴリーにアイテムを追加してください。", message: "並び替えの前に、カテゴリーにアイテムを追加してください。", okHandler: nil)
        }
    }
    
    @IBAction func onTapAddCategory(sender: UIBarButtonItem) {
        self.showCategoryPickerViewControllerIfPossible()
    }
    
    private func showRearrangeTableViewController() {
        let rearrangeVC = RearrangeTableViewController.forTargets(self.categoriesForEdit.map{$0.name})
        rearrangeVC.delegate = self
        
        let nv = UINavigationController(rootViewController: rearrangeVC)
        self.presentViewController(nv, animated: true, completion: nil)
    }
    
    private func showCategoryPickerViewControllerIfPossible() {
        guard let combination = self.combination else {
            self.showAlertMessage("有効な組み合わせ情報が存在しません。", message: nil, okHandler: nil)
            return
        }
        
        let maxCountOfCombinationItems = AppContext.sharedInstance.maxCountOfCombinationItems
        let currentCountOfCombinationItems = combination.combinationItems.count
        if currentCountOfCombinationItems < maxCountOfCombinationItems {
            self.performSegueWithIdentifier("showCategoryPickerTableViewControllerSegue", sender: self)
        } else {
            self.showOkCancelAlertMessage("組み合わせアイテムの上限に達しています。", message: "１つの組み合わせ内に保存できる、組み合わせアイテムの数の上限[\(maxCountOfCombinationItems)]に達しているため、新規で追加できません。", okCaption: "機能追加する", cancelCaption: "キャンセル", okHandler: {action in
                self.showViewControllerByStoryboardId(AppContext.sharedInstance.storyboardIdInAppPurchaseProductsListTableViewController, storyboardName: AppContext.sharedInstance.storyboardName, initialize: nil)
                }, cancelHandler: nil)
        }
    }

    @IBAction func onTapAddNewItem(sender: UIBarButtonItem) {
        //self.pickImage()
    }
    
    @IBAction func onTapSaveBarButtonItem(sender: UIBarButtonItem) {
        self.addOrUpdateCombination()
        self.delegate?.didSaveCombination(self.combination!)
        
        self.showAlertMessage("保存しました。", message: nil, okHandler: {action in self.closeForCancel()})
    }
    
    func onTapCancelBarButtonItem(sender: UIBarButtonItem) {
        self.closeForCancel()
    }
    
    func onTapCancelOnCreateNewBarButtonItem(sender: UIBarButtonItem) {
        // 離れるときに未保存であれば、注意を促す
        if self.combination?.realm == nil {
            self.showOkCancelAlertMessage("まだ保存されていません。", message: "編集内容が保存されていませんが、前の画面に戻りますか？",
                okHandler: {action in
                    self.closeForCancel()
                }, cancelHandler: nil)
        } else {
            self.closeForCancel()
        }
    }
    
    private func closeForCancel() {
        self.delegate?.didCancelCombination(self.combination!)
        self.close()
    }
    
    private func close() {
        if self.navigationController?.viewControllers.first == self {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
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
        
        // 余分な罫線を消す
        self.hideExtraFooterLine()

        // 存在しない時は新規
        if self.combination == nil {
            // 新規の場合は、右に保存ボタンあり（IB上で定義）
            // 左ボタンはカスタムに差し替え、未保存時の処理を実施可能とする
            // 新規時のキャンセルボタン
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "戻る", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(CombinationEditTableViewController.onTapCancelOnCreateNewBarButtonItem(_:)))

            // 空データを設定
            self.combination = Combination()
        } else {
            // 更新の場合は、保存ボタンは不要
            self.navigationItem.rightBarButtonItem = nil
            // 更新時のキャンセルボタン
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "閉じる", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(CombinationEditTableViewController.onTapCancelBarButtonItem(_:)))

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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initAnalysisTracker("組み合わせ編集（CombinationEditTableViewController）")

        self.encourageAddNewCombinationItem()
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
        self.rearrangeBarButtonItem.enabled = self.categoriesForEdit.count > 0
        return 1 + self.categoriesForEdit.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "タイトル" : self.categoriesForEdit[section - 1].name
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section > 0 ? 132 : 44
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseId = indexPath.section == 0 ? "combinationEditTableViewCell" : "combinationItemCombinationEditTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath)

        // Configure the cell...
        if indexPath.section == 0, let nameCell = cell as? CombinationEditTableViewCell {
            nameCell.delegate = self
            nameCell.configure(self.combination!)
        } else if indexPath.section > 0, let itemCell = cell as? CombinationItemCombinationEditTableViewCell {
            itemCell.clear()
            itemCell.delegate = self
            if self.categoriesForEdit[indexPath.section - 1].combinationItems.count == 0 {
                cell.textLabel?.font = UIFont.systemFontOfSize(14.0)
                cell.textLabel?.textColor = UIColor.darkTextColor()
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.lineBreakMode = .ByWordWrapping
                cell.textLabel?.text = "左へスワイプして、「アイテムを追加」を押し、カテゴリーにアイテムを追加してください。追加したアイテムは、長押しすることで削除できます。"
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

        let addCombinationItemAction = UITableViewRowAction(style: .Normal, title: "アイテム\nを追加"){(action, indexPath) in
            self.showImagePickerViewControllerIfPossible(indexPath)
        }
        addCombinationItemAction.backgroundColor = UIColor.lightGrayColor()
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "カテゴリーを\n組合せから削除"){(action, indexPath) in
            let removed = self.categoriesForEdit.removeAtIndex(indexPath.section - 1)
            if let removingIndex = self.combination?.combinationItems.indexOf({$0.category?.uuid == removed.uuid}) {
                // Combinationg側から削除する
                // CombinationItem側からdeleteすると、それ自体が削除されてしまう
                if let realm = try? Realm() {
                    let _ = try? realm.write {
                        self.combination?.combinationItems.removeAtIndex(removingIndex)
                        self.combination?.updatedAt = NSDate()
                    }
                }
            }
            tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: .Fade)
            self.tableView.setEditing(false, animated: true)
        }
        deleteAction.backgroundColor = UIColor.redColor()
        
        // 詳細情報は一旦非表示
        return [/*detailAction,*/ deleteAction, addCombinationItemAction]
    }
    
    private func showImagePickerViewControllerIfPossible(indexPath : NSIndexPath) {
        
        let maxCountOfCombinationItemsInCategory = AppContext.sharedInstance.maxCountOfCombinationItemsInCategory
        let currentCountOfCombinationItemsInCategory = self.categoriesForEdit[indexPath.section - 1].combinationItems.count
        if currentCountOfCombinationItemsInCategory < maxCountOfCombinationItemsInCategory {
            self.showImagePickerViewController(.PhotoLibrary)
            self.targetCategoryNameForAddItem = self.categoriesForEdit[indexPath.section - 1].name
            self.tableView.setEditing(false, animated: true)
        } else {
            self.showOkCancelAlertMessage("カテゴリー内の組み合わせアイテムの上限に達しています。", message: "カテゴリーに追加できる、組み合わせアイテムの数の上限[\(maxCountOfCombinationItemsInCategory)]に達しているため、新規で追加できません。", okCaption: "機能追加する", cancelCaption: "キャンセル", okHandler: {action in
                self.showViewControllerByStoryboardId(AppContext.sharedInstance.storyboardIdInAppPurchaseProductsListTableViewController, storyboardName: AppContext.sharedInstance.storyboardName, initialize: nil)
                }, cancelHandler: nil)
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
            categoryPickerVC.notIncludeFolderUUIDs = self.categoriesForEdit.map{$0.uuid}
        }
    }
    
    func didSelectCombinationItem(combinationItem : CombinationItem){
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                if let index = self.combination?.combinationItems.indexOf({ (comboItem) -> Bool in comboItem.category?.uuid == combinationItem.category?.uuid}) {
                    if combinationItem.uuid != self.combination?.combinationItems[index].uuid {
                        self.combination?.updatedAt = NSDate()
                    }
                    self.combination?.combinationItems.replace(index, object: combinationItem)
                } else {
                    // 画面上のカテゴリーの順番と、組み合わせが持つ組み合わせアイテムの順番を揃える
                    if let index = self.categoriesForEdit.indexOf({$0.uuid == combinationItem.category?.uuid}) {
                        var existingCount = 0
                        for innerIndex in 0..<index {
                            if self.combination?.combinationItems.filter({$0.category?.uuid == self.categoriesForEdit[innerIndex].uuid}).count > 0 {
                                existingCount += 1
                            }
                        }
                        
                        self.combination?.combinationItems.insert(combinationItem, atIndex: existingCount)
                        self.combination?.updatedAt = NSDate()
                    }
                }
            })
        }
    }
    
    func didDeselectCombinationItem(combinationItem : CombinationItem){
        if let removingIndex = self.combination?.combinationItems.indexOf({$0.uuid == combinationItem.uuid}) {
            // 新規作成の場合もあるため、Realmオブジェクトを明示的に生成する
            if let realm = try? Realm() {
                let _ = try? realm.write {
                    self.combination?.combinationItems.removeAtIndex(removingIndex)
                    self.combination?.updatedAt = NSDate()
                }
            }
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
        imageViewController.allowsEditing = false
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
            
            // アプリのアルバムは作成せず、指定画像のlocalIdentifierをそのまま保存する
            if let phAsset = PHAsset.fetchAssetsWithALAssetURLs([selectedImageUrl], options: nil).firstObject as? PHAsset {
                self.createCombinationItem(categoryName, itemName: itemNameByExif, photoLocalId: phAsset.localIdentifier)
                self.reloadCategory(categoryName)
                self.tableView.reloadData()
            }
            
            /*
            // 元画像が複製されて、その複製されたものへのリンクがアプリのアルバムに追加される。
            // 追加するたびに画像が増えてしまうので、一旦元画像のリンクをそのまま扱い、アルバムへの追加は行わない
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
            */
        }
        
        self.targetCategoryNameForAddItem = nil
    }
    
    func didCancelRearrange(){
        
    }
    
    func didDoneRearrange(rearrangeActions : [(from : Int, to : Int)]){
        rearrangeActions.forEach { (from, to) -> () in
            if let realm = self.combination?.realm {
                let _ = try? realm.write({
                    self.combination?.combinationItems.move(from: from, to: to)
                    self.combination?.updatedAt = NSDate()
                })
            } else {
                self.combination?.combinationItems.move(from: from, to: to)
                self.combination?.updatedAt = NSDate()
            }
        }
        
        self.categoriesForEdit = self.combination?.combinationItems.filter{$0.category != nil}.map{$0.category!} ?? []
        self.tableView.reloadData()
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
                combinationItem.createdAt = NSDate()
                combinationItem.updatedAt = combinationItem.createdAt
                realm.add(combinationItem)
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
            album = albums[0] as? PHAssetCollection
        } else {
            if let _ = try? PHPhotoLibrary.sharedPhotoLibrary().performChangesAndWait({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumName)
            }) {
                album = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: options)[0] as? PHAssetCollection
            }
        }
        
        return album
    }
    
    func addAsset(album : PHAssetCollection, imageUrl : NSURL, completion : ((localId : String?) -> Void)?) {
        print("add asset : album \(album.localizedTitle)")
        var assetLocalId : String?
        
        if let phAsset = PHAsset.fetchAssetsWithALAssetURLs([imageUrl], options: nil).firstObject as? PHAsset {

            /* requestImageDataForAssetだと複数回コールバックされない
            PHImageManager.defaultManager().requestImageDataForAsset(phAsset, options: nil, resultHandler: { (imageData, dataUTI, orientation, info) -> Void in
                print(info)
                if let fileUrl = info?["PHImageFileURLKey"] as? NSURL {
                    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                    dispatch_async(dispatch_get_global_queue(priority, 0), {
                        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                            if let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(fileUrl) {
                                let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
                                assetLocalId = assetPlaceholder?.localIdentifier
                                if let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album) {
                                    albumChangeRequest.addAssets([assetPlaceholder!])
                                }
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
            */
            
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
                    self.combination?.updatedAt = self.combination?.createdAt ?? NSDate()
                }
                self.combination?.folder = realm.objects(Folder).filter("uuid = %@", self.folderUUID ?? "").first
                self.combination?.folder?.updatedAt = self.combination?.updatedAt ?? NSDate()
                
                print("save combination : \(self.combination)")
                
                realm.add(self.combination!, update: true)
            })
        }
    }
    
    func nameTextChanged(changedText : String){
        if let realm = try? Realm() {
            let _ = try? realm.write({ () -> Void in
                self.combination?.name = changedText
                self.combination?.updatedAt = NSDate()
            })
        }
    }
    
    private func encourageAddNewCombinationItem() {
        if let realm = try? Realm() {
            if self.categoriesForEdit.count == 0 && realm.objects(Combination).filter("combinationItems.@count > 0").count == 0 {
                self.showAlertMessage("アイテムを追加しましょう！", message: "右下のボタンを押して、カテゴリーを選択してください。追加後、組み合わせに含めるアイテムをタップします。カテゴリーを左へスワイプすることで、そのカテゴリーにアイテムを追加することもできます。", okHandler: nil)
            }
        }
    }
}

protocol CombinationEditTableViewControllerDelegate {
    func didSaveCombination(combination : Combination)
    func didCancelCombination(combination : Combination)
}