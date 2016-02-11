//
//  AppStoreObserver.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/07.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import StoreKit

class AppStoreObserver: NSObject, SKPaymentTransactionObserver {
    let IAPPurchaseNotification = "IAPPurchaseNotification"
    static let sharedInstance = AppStoreObserver()
    var productsPurchased : [SKPaymentTransaction] = []
    var productsRestored : [SKPaymentTransaction] = []
    var purchasedID = ""
    var status : IAPPurchaseNotificationStatus = .PurchaseFailed
    var message = ""
    var downloadProgress : Float = 0.0
    
    // Make a purchase
    
    // Create and add a payment request to the payment queue
    func buy(product : SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    // Has purchased products
    
    // Returns whether there are purchased products
    var hasPurchasedProducts : Bool
    {
        get{
            // productsPurchased keeps track of all our purchases.
            // Returns YES if it contains some items and NO, otherwise
            return self.productsPurchased.count > 0
        }
    }
    
    // Has restored products
    
    // Returns whether there are restored purchases
    var hasRestoredProducts : Bool {
        // productsRestored keeps track of all our restored purchases.
        // Returns YES if it contains some items and NO, otherwise
        return self.productsRestored.count > 0
    }

    // Restore purchases
    func restore() {
        self.productsRestored = []
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // SKPaymentTransactionObserver methods
    
    // Called when there are trasactions in the payment queue
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]){
        for transaction in transactions {
            switch transaction.transactionState {
            case SKPaymentTransactionState.Purchasing:
                break
                
            case SKPaymentTransactionState.Deferred:
                // Do not block your UI. Allow the user to continue using your app.
                print("Allow the user to continue using your app.")
                break
                
                // The purchase was successful
            case SKPaymentTransactionState.Purchased:
                
                self.purchasedID = transaction.payment.productIdentifier
                self.productsPurchased.append(transaction)
                
                print("Deliver content for \(transaction.payment.productIdentifier)")
                
                // Check whether the purchased product has content hosted with Apple.
                if transaction.downloads.count > 0 {
                    self.completeTransaction(transaction, forStatus:IAPPurchaseNotificationStatus.DownloadStarted)
                }
                else {
                    self.completeTransaction(transaction, forStatus:IAPPurchaseNotificationStatus.PurchaseSucceeded)
                }
                
                break
                
                // There are restored products
            case SKPaymentTransactionState.Restored:
                
                self.purchasedID = transaction.payment.productIdentifier
                self.productsRestored.append(transaction)
                
                print("Restore content for \(transaction.payment.productIdentifier)")
                
                // Send a IAPDownloadStarted notification if it has
                if transaction.downloads.count > 0 {
                    self.completeTransaction(transaction, forStatus: IAPPurchaseNotificationStatus.DownloadStarted)
                }
                else {
                    self.completeTransaction(transaction, forStatus: IAPPurchaseNotificationStatus.RestoredSucceeded)
                }
                
                break
                
                // The transaction failed
            case SKPaymentTransactionState.Failed:
                
                self.message = "Purchase of \(transaction.payment.productIdentifier) failed."
                self.completeTransaction(transaction, forStatus: IAPPurchaseNotificationStatus.PurchaseFailed)
                
                break
            default:
                break
            }
        }

    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]){
        for download in downloads {
            switch (download.downloadState) {
                
                // The content is being downloaded. Let's provide a download progress to the user
            case .Active:
                
                self.status = .DownloadInProgress
                self.purchasedID = download.transaction.payment.productIdentifier
                self.downloadProgress = download.progress * 100
                NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
                
                break
                
            case .Cancelled:
                // StoreKit saves your downloaded content in the Caches directory. Let's remove it
                // before finishing the transaction.
                if let contentURL = download.contentURL {
                    let _ = try? NSFileManager.defaultManager().removeItemAtURL(contentURL)
                }
                
                self.finishDownloadTransaction(download.transaction)
                
                break
                
            case .Failed:
                // If a download fails, remove it from the Caches, then finish the transaction.
                // It is recommended to retry downloading the content in this case.
                if let contentURL = download.contentURL {
                    let _ = try? NSFileManager.defaultManager().removeItemAtURL(contentURL)
                }
                
                self.finishDownloadTransaction(download.transaction)
                break
                
            case .Paused:
                print("Download was paused")
                break
                
            case .Finished:
                // Download is complete. StoreKit saves the downloaded content in the Caches directory.
                print("Location of downloaded file \(download.contentURL)")
                self.finishDownloadTransaction(download.transaction)
                break
                
            case .Waiting:
                print("Download Waiting")
                SKPaymentQueue.defaultQueue().startDownloads([download])
                break
                
            default:
                break
            }
        }
        
    }
    
    // Logs all transactions that have been removed from the payment queue
    func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]){
        for transaction in transactions {
            print("\(transaction.payment.productIdentifier) was removed from the payment queue.")
        }
    }
    
    // Called when an error occur while restoring purchases. Notify the user about the error.
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError){
        if error.code != SKErrorPaymentCancelled {
            self.status = .RestoredFailed;
            self.message = error.localizedDescription;
            NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
        }
    }
    
    // Called when all restorable transactions have been processed by the payment queue
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue){
        print("All restorable transactions have been processed by the payment queue.")
    }
    
    // Complete transaction
    
    // Notify the user about the purchase process. Start the download process if status is
    // IAPDownloadStarted. Finish all transactions, otherwise.
    func completeTransaction(transaction : SKPaymentTransaction, forStatus status : IAPPurchaseNotificationStatus) {
        self.status = status;
        //Do not send any notifications when the user cancels the purchase
        if (transaction.error?.code != SKErrorPaymentCancelled) {
            // Notify the user
            NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
        }
        
        if (status == IAPPurchaseNotificationStatus.DownloadStarted) {
            // The purchased product is a hosted one, let's download its content
            SKPaymentQueue.defaultQueue().startDownloads(transaction.downloads)
        }
        else {
            // Remove the transaction from the queue for purchased and restored statuses
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        }
    }
    
    // Handle download transaction
    func finishDownloadTransaction(transaction : SKPaymentTransaction) {
        //allAssetsDownloaded indicates whether all content associated with the transaction were downloaded.
        var allAssetsDownloaded = true
        
        // A download is complete if its state is SKDownloadStateCancelled, SKDownloadStateFailed, or SKDownloadStateFinished
        // and pending, otherwise. We finish a transaction if and only if all its associated downloads are complete.
        // For the SKDownloadStateFailed case, it is recommended to try downloading the content again before finishing the transaction.
        for download in transaction.downloads {
            if  download.downloadState != SKDownloadState.Cancelled &&
                download.downloadState != SKDownloadState.Failed &&
                download.downloadState != SKDownloadState.Finished {
                //Let's break. We found an ongoing download. Therefore, there are still pending downloads.
                allAssetsDownloaded = false
                break
            }
        }
        
        // Finish the transaction and post a IAPDownloadSucceeded notification if all downloads are complete
        if allAssetsDownloaded {
            self.status = IAPPurchaseNotificationStatus.DownloadSucceeded
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
            NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
            
            if self.productsRestored.contains(transaction) {
                self.status = IAPPurchaseNotificationStatus.RestoredSucceeded
                NSNotificationCenter.defaultCenter().postNotificationName(IAPPurchaseNotification, object: self)
            }
        }
    }
}

enum IAPPurchaseNotificationStatus {
    case PurchaseFailed // Indicates that the purchase was unsuccessful
    case PurchaseSucceeded // Indicates that the purchase was successful
    case RestoredFailed // Indicates that restoring products was unsuccessful
    case RestoredSucceeded // Indicates that restoring products was successful
    case DownloadStarted // Indicates that downloading a hosted content has started
    case DownloadInProgress // Indicates that a hosted content is currently being downloaded
    case DownloadFailed  // Indicates that downloading a hosted content failed
    case DownloadSucceeded // Indicates that a hosted content was successfully downloaded
}
