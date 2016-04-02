//
//  InAppPurchaseProductsListTableViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/07.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import StoreKit

let purchasedStatusAvailableProducts = "AVAILABLE PRODUCTS"
let purchasedStatusPurchased = "PURCHASED"
let purchasedStatusRestored = "RESTORED"

class InAppPurchaseProductsListTableViewController: UITableViewController {
    
    var restoreWasCalled = false
    var availableProducts : [(name : String, elements : [SKProduct])] = []
    var purchasedProducts : [(name : String, elements : [SKPaymentTransaction])] = []
    
    let nameTable : [String:String] = [
        purchasedStatusAvailableProducts : "購入可能",
        purchasedStatusPurchased : "購入処理完了",
        purchasedStatusRestored : "復元処理完了"
    ]

    @IBAction func onTapRestoreBarButtonItem(sender: UIBarButtonItem) {
        AppStoreObserver.sharedInstance.restore()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // 余分な罫線を消す
        self.hideExtraFooterLine()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(InAppPurchaseProductsListTableViewController.handleProductRequestNotification(_:)),
            name: AppStoreManager.sharedInstance.IAPProductRequestNotification,
            object: AppStoreManager.sharedInstance)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(InAppPurchaseProductsListTableViewController.handlePurchasesNotification(_:)),
            name: AppStoreObserver.sharedInstance.IAPPurchaseNotification,
            object: AppStoreObserver.sharedInstance)
        
        self.fetchProductInformation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.availableProducts.count + self.purchasedProducts.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section < self.availableProducts.count ? self.availableProducts[section].elements.count :
            (section < (self.availableProducts.count + self.purchasedProducts.count)) ? self.purchasedProducts[section - self.availableProducts.count].elements.count : 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("InAppPurchaseProductsListTableViewCell", forIndexPath: indexPath)

        // Configure the cell...
        if self.availableProducts.count > indexPath.section {
            let skProduct : SKProduct = self.availableProducts[indexPath.section].elements[indexPath.row]
            cell.textLabel?.text = "\(skProduct.localizedTitle) (\(skProduct.priceLocale.objectForKey(NSLocaleCurrencySymbol) as? String ?? "")\(skProduct.price))"
            cell.detailTextLabel?.text = skProduct.localizedDescription
            cell.accessoryType = InAppPurchaseProductManager.sharedInstance.purchased(skProduct.productIdentifier) ? .Checkmark : .None
        } else if (self.availableProducts.count + self.purchasedProducts.count) > indexPath.section {
            let index = indexPath.section - self.availableProducts.count
            let product = AppStoreManager.sharedInstance.titleMatchingProductIdentifier(self.purchasedProducts[index].elements[indexPath.row].payment.productIdentifier)
            cell.textLabel?.text = product
            cell.detailTextLabel?.text = ""
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.stringForDisplaySectionName(section < self.availableProducts.count ? self.availableProducts[section].name :
        (section < (self.availableProducts.count + self.purchasedProducts.count)) ?
            self.purchasedProducts[section - self.availableProducts.count].name : nil)
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? "一度ご購入いただきますと、ずっとお使いいただけます。ご購入の確認が取れたものには、右側に✔︎が表示されます。以前にご購入済で、✔︎が表示されていない場合には、右上の復元ボタンを押してください。" : nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Only available products can be bought
        if self.availableProducts.count > indexPath.section && self.availableProducts[indexPath.section].name == purchasedStatusAvailableProducts {
            let product = self.availableProducts[indexPath.section].elements[indexPath.row]
            // Attempt to purchase the tapped product
            AppStoreObserver.sharedInstance.buy(product)
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func stringForDisplaySectionName(keyString : String?) -> String? {
        var displayName : String?
        if let keyString = keyString {
            displayName = self.nameTable[keyString]
        }
        
        return displayName
    }
    
    // Fetch product information
    
    // Retrieve product information from the App Store
    func fetchProductInformation() {
        // Query the App Store for product information if the user is is allowed to make purchases.
        // Display an alert, otherwise.
        if SKPaymentQueue.canMakePayments() {
            // Load the product identifiers fron ProductIds.plist
            if  let plistURL = NSBundle.mainBundle().URLForResource("ProductIds", withExtension: "plist"),
                let productIds = NSArray(contentsOfURL: plistURL) as? [String] {
                AppStoreManager.sharedInstance.fetchProductInformationForIds(productIds)
            }
        }
        else {
            // Warn the user that they are not allowed to make purchases.
            self.alertWithTitle("Warning", message: "Purchases are disabled on this device.")
        }
    }

    // Display message
    func alertWithTitle(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Return an array that will be used to populate the Purchases view
    func dataSourceForPurchasesUI() -> [(name : String, elements : [SKPaymentTransaction])] {
        var dataSource : [(name : String, elements : [SKPaymentTransaction])] = []
        
        if self.restoreWasCalled &&
        AppStoreObserver.sharedInstance.hasRestoredProducts && AppStoreObserver.sharedInstance.hasPurchasedProducts {
            dataSource = [
                (name : purchasedStatusPurchased, elements : AppStoreObserver.sharedInstance.productsPurchased),
                (name : purchasedStatusRestored, elements : AppStoreObserver.sharedInstance.productsRestored)
            ]
        }
        else if self.restoreWasCalled && AppStoreObserver.sharedInstance.hasRestoredProducts
        {
            dataSource = [
                (name : purchasedStatusRestored, elements : AppStoreObserver.sharedInstance.productsRestored)
            ]
        }
        else if AppStoreObserver.sharedInstance.hasPurchasedProducts
        {
            dataSource = [
                (name : purchasedStatusPurchased, elements : AppStoreObserver.sharedInstance.productsPurchased)
            ]
        }
        
        // Only want to display restored products when the Restore button was tapped and there are restored products
        self.restoreWasCalled = false
        return dataSource
    }
    
    // IAPTableViewDataSource
    
    func reloadUIWithData(data : [(name : String, elements :[SKPaymentTransaction])]){
        self.purchasedProducts = data
        self.tableView.reloadData()
    }
    
    func reloadUIWithData(data : [(name : String, elements :[SKProduct])]){
        self.availableProducts = data
        self.tableView.reloadData()
    }
    
    // Update the UI according to the product request notification result
    func handleProductRequestNotification(notification : NSNotification?) {
        if let productRequestNotification = notification?.object as? AppStoreManager {
            if productRequestNotification.status == .ProductRequestResponse {
                self.reloadUIWithData(productRequestNotification.productRequestResponse)
                self.reloadUIWithData(self.dataSourceForPurchasesUI())
            }
        }
    }
    
    // Handle purchase request notification
    
    // Update the UI according to the purchase request notification result
    func handlePurchasesNotification(notification : NSNotification?) {
        if let purchasesNotification = notification?.object as? AppStoreObserver {
            let status = purchasesNotification.status
            
            switch status {
            case .PurchaseSucceeded:
                // ProductIdに紐づく機能の有効化
                InAppPurchaseProductManager.sharedInstance.applyInAppProductByProductId(purchasesNotification.purchasedID)
                self.reloadUIWithData(self.dataSourceForPurchasesUI())
                break
            case .PurchaseFailed:
                self.alertWithTitle("Purchase Status", message: purchasesNotification.message)
                break
                
                // Switch to the iOSPurchasesList view controller when receiving a successful restore notification
            case .RestoredSucceeded:
                // ProductIdに紐づく機能の有効化
                InAppPurchaseProductManager.sharedInstance.applyInAppProductByProductId(purchasesNotification.purchasedID)
                
                self.restoreWasCalled = true
                self.reloadUIWithData(self.dataSourceForPurchasesUI())
                break
                
            case .RestoredFailed:
                self.alertWithTitle("Purchase Status", message: purchasesNotification.message)
                break
                
                // Notify the user that downloading is about to start when receiving a download started notification
            case .DownloadStarted:
                
                //self.hasDownloadContent = true
                //self.view.addSubview(self.statusMessage)
                
                break
                
                // Display a status message showing the download progress
            case .DownloadInProgress:
                
                //self.hasDownloadContent = true
//                let title =AppStoreObserver.sharedInstance
//                    NSString *title = [[StoreManager sharedInstance] titleMatchingProductIdentifier:purchasesNotification.purchasedID];
//                    NSString *displayedTitle = (title.length > 0) ? title : purchasesNotification.purchasedID;
//                    self.statusMessage.text = [NSString stringWithFormat:@" Downloading %@   %.2f%%",displayedTitle, purchasesNotification.downloadProgress];
                
                break
                
                // Downloading is done, remove the status message
            case .DownloadSucceeded:
                
//                    self.hasDownloadContent = NO;
//                    self.statusMessage.text = @"Download complete: 100%";
//                    
//                    // Remove the message after 2 seconds
//                    [self performSelector:@selector(hideStatusMessage) withObject:nil afterDelay:2];
                
                break
            default:
                break
            }
        }
    }
}
