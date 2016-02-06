//
//  CombinationListTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class CombinationListTableViewController: CombinationListBaseTableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, CombinationListFilteredTableViewControllerDelegate {

    @IBAction func onTapNewCombinationBarButtonItem(sender: UIBarButtonItem) {
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
        
        self.initializeSearchController()
        
        self.loadCombinations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadCombinations() {
        if let realm = try? Realm() {
            // TODO: Results<Combination>のまま保持するのが、よい？
            let results = realm.objects(Combination).filter("folder.name = '\(self.folderName)'")
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

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

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

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            self.deleteCombination(self.combinations[indexPath.row])
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
    
//    func deleteCombinationAtIndexPath(indexPath : NSIndexPath) {
//        if let realm = try? Realm() {
//            let _ = try? realm.write({ () -> Void in
//                let removed = self.combinations.removeAtIndex(indexPath.row)
//                realm.delete(removed)
//                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//            })
//        }
//    }

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
}
