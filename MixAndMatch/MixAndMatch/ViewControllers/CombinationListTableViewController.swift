//
//  CombinationListTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class CombinationListTableViewController: CombinationListBaseTableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, CombinationListFilteredTableViewControllerDelegate, FolderPickerTableViewControllerDelegate {

    struct ToolBarItemId {
        static let moveBarButtonItem = 101
        static let deleteBarButtonItem = 102
    }
    
    var sourceViewController : UIViewController?
    
    @IBAction func onTapNewCombinationBarButtonItem(sender: UIBarButtonItem) {
        self.showCombinationEditViewControllerIfPossible()
    }
    
    func showCombinationEditViewControllerIfPossible() {
        guard let folderUUID = self.folderUUID else {
            self.showAlertMessage("有効なフォルダに紐付いていません", message: nil, okHandler: nil)
            return
        }
        
        let maxCountOfLocalSaveCombinationInFolder = AppContext.sharedInstance.maxCountOfLocalSaveCombinationInFolder
        let currentCountOfCombinationsInFolder = try? Realm().objects(Combination).filter("folder.uuid = '\(folderUUID)'").count
        if currentCountOfCombinationsInFolder < maxCountOfLocalSaveCombinationInFolder {
            self.performSegueWithIdentifier("showCombinationEditTableViewControllerSegue", sender: self)
        } else {
            self.showAlertMaxLimitSaveCount(maxCountOfLocalSaveCombinationInFolder)
        }
    }
    
    private func showAlertMaxLimitSaveCount(maxCountOfLocalSaveCombinationInFolder : Int) {
        self.showOkCancelAlertMessage("保存数の上限に達しています。", message: "フォルダ内に保存できる数の上限[\(maxCountOfLocalSaveCombinationInFolder)]に達しているため、新規で追加できません。", okCaption: "機能追加する", cancelCaption: "キャンセル", okHandler: {action in
            self.showViewControllerByStoryboardId(AppContext.sharedInstance.storyboardIdInAppPurchaseProductsListTableViewController, storyboardName: AppContext.sharedInstance.storyboardName, initialize: nil)
            }, cancelHandler: nil)
    }
    
    // Search controller to help us with filtering.
    var searchController: UISearchController!
    
    // Secondary search results table view.
    var filteredCombinationsTableViewController: CombinationListFilteredTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.editButtonItem().action = #selector(CombinationListTableViewController.overrideToggleEditing(_:))
        self.initializeSearchController()
        
        self.loadCombinations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.initAnalysisTracker("組み合わせ一覧（CombinationListTableViewController）")

        self.encourageCreateNewCombination()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        (self.sourceViewController as? FolderListTableViewController)?.isShowAd = true
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        
        // 自分自身が最後尾なので、一階層前は、最後尾のひとつ前
        if let count = parent?.childViewControllers.count where count > 1 {
            self.sourceViewController = parent?.childViewControllers[count - 2]
        } else {
            self.sourceViewController = nil
        }
    }

    override func setEditing(editing: Bool, animated: Bool) {
        
        self.toolbarItems?.last?.enabled = !editing
        self.searchController.searchBar.userInteractionEnabled = !editing
        self.tableView.allowsMultipleSelectionDuringEditing = editing
        self.tableView.setEditing(editing, animated: animated)
        super.setEditing(editing, animated: animated)
    }

    func overrideToggleEditing(barButtonItem : UIBarButtonItem) {
        //self.performSelector("_toggleEditing:")
        self.setEditing(!self.editing, animated: true)
        
        self.confiureEditingBarButtonItem(self.editing)
    }

    weak var moveBarButtonItem : UIBarButtonItem?
    private func confiureEditingBarButtonItem(editing : Bool) {
        if editing {
            self.addEditingBarButtonItem()
        } else {
            self.removeEditingBarButtonItem()
        }
    }
    
    private func addEditingBarButtonItem() {
        // 最初はdisableで。選択したらenable。選択を外して選択数ゼロになったらdisable（メモアプリだと、全件対象で実行）
        let moveBarButtonItem = UIBarButtonItem(title: "移動...", style: .Plain, target: self, action: #selector(CombinationListTableViewController.onTapMoveBarButtonItem(_:)))
        let deleteBarButtonItem = UIBarButtonItem(title: "削除", style: .Plain, target: self, action: #selector(CombinationListTableViewController.onTapDeleteBarButtonItem(_:)))
        moveBarButtonItem.enabled = false
        deleteBarButtonItem.enabled = false
        moveBarButtonItem.tag = ToolBarItemId.moveBarButtonItem
        deleteBarButtonItem.tag = ToolBarItemId.deleteBarButtonItem
        self.toolbarItems?.insert(moveBarButtonItem, atIndex: 0)
        self.toolbarItems?.insert(deleteBarButtonItem, atIndex: (self.toolbarItems?.count ?? 1) - 1)
    }
    
    private func removeEditingBarButtonItem() {
        // TODO: 削除すべきものがあったら、削除するのロジックに置き換える
        if self.toolbarItems?.count == 4 {
            self.toolbarItems?.removeFirst()
            self.toolbarItems?.removeAtIndex((self.toolbarItems?.count ?? 2) - 2)
        }
    }
    
    func onTapMoveBarButtonItem(barButtonItem : UIBarButtonItem) {
        if let selectRows = self.tableView.indexPathsForSelectedRows {
            let selectItems = selectRows.map{self.combinations[$0.row]}
            self.pushFolderPickerTableViewController(selectItems)
        }
    }
    
    func onTapDeleteBarButtonItem(barButtonItem : UIBarButtonItem) {
        
        self.showOkCancelAlertMessage("本当に削除しますか？", message: "完全に削除され、元に戻せません。",
            okHandler: { alertAction in
                if let deletingPaths = self.tableView.indexPathsForSelectedRows {
                    deletingPaths.reverse().forEach {
                        let removed = self.combinations.removeAtIndex($0.row)
                        let _ = try? removed.realm?.write{
                            removed.realm?.delete(removed)
                        }
                    }
                    self.tableView.deleteRowsAtIndexPaths(deletingPaths, withRowAnimation: .Automatic)
                }
                
                self.tableView.endEditing(false)
            },
            cancelHandler: nil
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadCombinations() {
        guard let folderUUID = self.folderUUID else {
            self.showAlertMessage("有効なフォルダに紐付いていません", message: nil, okHandler: nil)
            return
        }

        if let realm = try? Realm() {
            // TODO: Results<Combination>のまま保持するのが、よい？
            let results = realm.objects(Combination).filter("folder.uuid = '\(folderUUID)'").sorted("updatedAt", ascending: false)
            self.combinations = results.map{$0}
            let _ = self.combinations.forEach({ (combo) -> () in
                let _ = combo.combinationItems.map{print($0.name)}
                print(combo.combinationItems.count)
            })
        }
    }

    func initializeSearchController(){
        // サーチ後の結果
        self.filteredCombinationsTableViewController = CombinationListFilteredTableViewController()
        
        // We want to be the delegate for our filtered table so didSelectRowAtIndexPath(_:) is called for both tables.
        self.filteredCombinationsTableViewController.tableView.delegate = self.filteredCombinationsTableViewController
        self.filteredCombinationsTableViewController.tableView.dataSource = self.filteredCombinationsTableViewController
        self.filteredCombinationsTableViewController.navigationControllerOfOriginalViewController = self.navigationController
        self.filteredCombinationsTableViewController.delegate = self
        // TODO: 引き継がなければならない情報を忘れずに引き渡す仕組み
        self.filteredCombinationsTableViewController.folderName = self.folderName
        self.filteredCombinationsTableViewController.folderUUID = self.folderUUID
        
        self.searchController = UISearchController(searchResultsController: self.filteredCombinationsTableViewController)
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar
        
        self.searchController.delegate = self
        self.searchController.dimsBackgroundDuringPresentation = false // default is YES
        self.searchController.searchBar.delegate = self    // so we can monitor text changes + others
        
        // Search is now just presenting a view controller. As such, normal view controller
        // presentation semantics apply. Namely that presentation will walk up the view controller
        // hierarchy until it finds the root view controller or one that defines a presentation context.
        self.definesPresentationContext = true
        
    }

    func updateSearchResultsForSearchController(searchController: UISearchController){
        // Update the filtered array based on the search text.
        let searchResults = self.combinations
        
        // サーチバーに入力されたテキストをトリム後に単語単位に分割
        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
        let strippedString = searchController.searchBar.text!.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
        let searchItems = strippedString.componentsSeparatedByString(" ") as [String]
        
        // Build all the "AND" expressions for each value in the searchString.
        var andMatchPredicates = [NSPredicate]()
        
        for searchString in searchItems {
            // Each searchString creates an OR predicate for: name, yearIntroduced, introPrice.
            //
            // Example if searchItems contains "iphone 599 2007":
            //      name CONTAINS[c] "iphone"
            //      name CONTAINS[c] "599", yearIntroduced ==[c] 599, introPrice ==[c] 599
            //      name CONTAINS[c] "2007", yearIntroduced ==[c] 2007, introPrice ==[c] 2007
            //
            var searchItemsPredicate = [NSPredicate]()
            
            // Below we use NSExpression represent expressions in our predicates.
            // NSPredicate is mmiade up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value).
            
            // 通常のオブジェクトの場合は下記
            // Name field matching.
            // タイトル
            let lhs = NSExpression(forKeyPath: "name")
            let rhs = NSExpression(forConstantValue: searchString)
            
            let namePredicate = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .DirectPredicateModifier, type: .ContainsPredicateOperatorType, options: .CaseInsensitivePredicateOption)
            searchItemsPredicate.append(namePredicate)
            
            // 組み合わせアイテム - 名称
            let lhsItemName = NSExpression(forKeyPath: "combinationItems.name")
            let rhsItemName = NSExpression(forConstantValue: searchString)
            
            let itemNamePredicate = NSComparisonPredicate(leftExpression: lhsItemName, rightExpression: rhsItemName, modifier: .AnyPredicateModifier, type: .ContainsPredicateOperatorType, options: .CaseInsensitivePredicateOption)
            searchItemsPredicate.append(itemNamePredicate)
            
            // 組み合わせアイテム - メモ
            let lhsItemMemo = NSExpression(forKeyPath: "combinationItems.memo")
            let rhsItemMemo = NSExpression(forConstantValue: searchString)
            
            let itemMemoPredicate = NSComparisonPredicate(leftExpression: lhsItemMemo, rightExpression: rhsItemMemo, modifier: .AnyPredicateModifier, type: .ContainsPredicateOperatorType, options: .CaseInsensitivePredicateOption)
            searchItemsPredicate.append(itemMemoPredicate)
            
            // Add this OR predicate to our master AND predicate.
            let orMatchPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: searchItemsPredicate)
            andMatchPredicates.append(orMatchPredicates)
        }
        
        // Match up the fields of the Product object.
        let finalCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)
        
        // サーチバーのキーワードでフィルタ
        let filteredResults = searchResults.filter { finalCompoundPredicate.evaluateWithObject($0) }
        
        // Hand over the filtered results to our search results table.
        let resultsController = searchController.searchResultsController as! CombinationListFilteredTableViewController
        resultsController.combinations = filteredResults
        resultsController.tableView.reloadData()
        
    }
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.editing {
            self.enableEditingToolBarItems(true)
        } else {
            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if self.editing {
            if tableView.indexPathsForSelectedRows == nil {
                self.enableEditingToolBarItems(false)
            }
        }
    }
    
    private func enableEditingToolBarItems(enabled : Bool) {
        self.toolbarItems?.filter{$0.tag == ToolBarItemId.moveBarButtonItem || $0.tag == ToolBarItemId.deleteBarButtonItem}.forEach{$0.enabled = enabled}
    }
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "削除") { (action, indexPath) -> Void in
            self.showOkCancelAlertMessage("本当に削除しますか？", message: "完全に削除され、元に戻せません。",
                okHandler: { alertAction in self.deleteCombination(self.combinations[indexPath.row]) },
                cancelHandler: { alertAction in self.tableView.setEditing(false, animated: false) })
        }
        deleteAction.backgroundColor = .redColor()
        
        let moveAction = UITableViewRowAction(style: .Default, title: "移動") { (action, indexPath) -> Void in
            // カテゴリピッカー表示
            self.pushFolderPickerTableViewController([self.combinations[indexPath.row]])
        }
        moveAction.backgroundColor = .grayColor()

        let copyAction = UITableViewRowAction(style: .Default, title: "複製") { (action, indexPath) -> Void in
            let maxCountOfLocalSaveCombinationInFolder = AppContext.sharedInstance.maxCountOfLocalSaveCombinationInFolder
            if self.combinations.count < maxCountOfLocalSaveCombinationInFolder {
                self.tableView.setEditing(false, animated: true)
                self.copyCombination(self.combinations[indexPath.row], completionHandler: {
                    self.loadCombinations()
                    self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                })
            } else {
                self.showAlertMaxLimitSaveCount(maxCountOfLocalSaveCombinationInFolder)
            }
        }
        copyAction.backgroundColor = UIColor.lightGrayColor()

        return [deleteAction, moveAction, copyAction]
    }
    
    private func copyCombination(srcCombination : Combination, completionHandler : (() -> Void)?) {
        let _ = try? srcCombination.realm?.write{
            let copied = Combination(value: srcCombination)
            copied.uuid = NSUUID().UUIDString
            copied.createdAt = NSDate()
            copied.updatedAt = copied.createdAt
            srcCombination.realm?.add(copied)
            completionHandler?()
        }
    }
    
    func deleteCombination(combination : Combination) {
        if let index = self.combinations.indexOf({$0.uuid == combination.uuid}) {
            if let realm = try? Realm() {
                let _ = try? realm.write({ () -> Void in
                    let removed = self.combinations.removeAtIndex(index)
                    print("removing combination : \(removed)")
                    realm.delete(removed)
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
                })
            }
        }
    }
    
    func pushFolderPickerTableViewController(combinations :[Combination]) {
        
        // Set up the detail view controller to show.
        let folderPickerTableViewController = FolderPickerTableViewController.forCombinations(combinations)
        folderPickerTableViewController.delegate = self
        folderPickerTableViewController.notIncludeFolderUUID = self.folderUUID ?? ""
        
        let newNV = UINavigationController(rootViewController: folderPickerTableViewController)
        newNV.toolbarHidden = false
        self.presentViewController(newNV, animated: true, completion: nil)
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

    override func didSaveCombination(combination: Combination) {
        print("didSaveCombination : \(combination)")
        self.loadCombinations()
        self.tableView.reloadData()
    }
    
    override func didCancelCombination(combination: Combination) {
        print("didCancelCombination : \(combination)")
        self.loadCombinations()
        self.tableView.reloadData()
    }
    
    func didSaveCombinationViaFilteredList(combination: Combination){
        self.didSaveCombination(combination)
        self.updateSearchResultsForSearchController(self.searchController)
    }
    
    func didCancelCombinationViaFilteredList(combination: Combination){
        self.didCancelCombination(combination)
        self.updateSearchResultsForSearchController(self.searchController)
    }
    
    func deleteActionViaFilteredList(combination: Combination){
        self.deleteCombination(combination)
        self.updateSearchResultsForSearchController(self.searchController)
    }
    
    func didSelectCombinationItemViaFilteredList(combination : Combination, combinationItem : CombinationItem){
        self.didSelectCombinationItem(combination, combinationItem: combinationItem)
    }
    
    func didSelectFolder(combinations: [Combination], folder: Folder) {
        // 次回のキューで実行しないとワーニングが表示されない
        dispatch_async(dispatch_get_main_queue()) { 
            self.moveFolder(folder, targetCombinations: combinations)
        }
    }
    
    private func moveFolder(toFolder : Folder, targetCombinations : [Combination]) {
        let maxCountOfLocalSaveCombinationInFolder = AppContext.sharedInstance.maxCountOfLocalSaveCombinationInFolder
        if toFolder.combinations.count < maxCountOfLocalSaveCombinationInFolder {
            targetCombinations.forEach{ targetCombi in
                if let index = self.combinations.indexOf({targetCombi.uuid == $0.uuid} ){
                    let removed = self.combinations.removeAtIndex(index)
                    let _ = try? removed.realm?.write{ removed.folder = toFolder }
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                }
            }
        } else {
            self.showAlertMaxLimitSaveCount(maxCountOfLocalSaveCombinationInFolder)
        }
    }
    
    private func encourageCreateNewCombination() {
        if let realm = try? Realm() {
            if realm.objects(Combination).count == 0 {
                self.showAlertMessage("組み合わせを作りましょう！", message: "右下のボタンを押して、組み合わせを作成する画面を開いてください。", okHandler: nil)
            }
        }
    }

}
