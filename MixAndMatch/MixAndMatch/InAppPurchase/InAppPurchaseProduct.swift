//
//  InAppPurchaseProduct.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

/**
 App内課金商品
 購入、復元、レシート検証の際にデータを格納する
*/
class InAppPurchaseProduct {

    /**
     App Storeで管理しているId
     */
    var productId : InAppPurchaseProductId = .None
    
    /**
     App Storeで管理している名称
     */
    //bvar productName : String = ""
    
    /**
     商品に紐づく拡張機能（複数）
     */
    var functions : [PurchasedExtension] = []
}

class InAppPurchaseProductManager {
    static let sharedInstance = InAppPurchaseProductManager.createInAppPurchaseProductManager()
    var products : [InAppPurchaseProductId:InAppPurchaseProduct] = [:]
    
    static func createInAppPurchaseProductManager() -> InAppPurchaseProductManager {
        let manager = InAppPurchaseProductManager()
        return manager
    }
    
    /**
     拡張機能有効化
     */
    func enableExtensions(inAppProductId : String) {
        if let productId = InAppPurchaseProductId(rawValue: inAppProductId) {
            self.products[productId]?.functions.forEach{$0.attach()}
        }
    }
    
    /**
     拡張機能無効化
     */
    func disableExtension(inAppProductId : String) {
        if let productId = InAppPurchaseProductId(rawValue: inAppProductId) {
            self.products[productId]?.functions.forEach{$0.detach()}
        }
    }
    
    /**
     App内課金商品を適用（ローカルレシート）
     */
    func applyInAppProductByLocalReceipt(localReceipt : NSDictionary) {
        if let inAppProductInfos = localReceipt[ReceiptValidator.defaultValidator.kReceiptInApp] as? NSArray {
            for productInfoDic in inAppProductInfos {
                if let productInfoDic = productInfoDic as? NSDictionary {
                    if let productId = productInfoDic[ReceiptValidator.defaultValidator.kReceiptInAppProductIdentifier] as? String {
                        self.applyInAppProductByProductId(productId)
                    }
                }
            }
        }
    }
    
    /**
     App内課金商品を適用（プロダクトID）
     */
    func applyInAppProductByProductId(productId : String){
        self.addInAppPurchaseProduct(productId)
        self.enableExtensions(productId)
    }
    
    func addInAppPurchaseProduct(inAppProductId : String){
        if let productId = InAppPurchaseProductId(rawValue: inAppProductId) where self.products[productId] == nil {
            self.products[productId] = self.createInAppPurchaseProduct(productId)
        }
    }
    
    func createInAppPurchaseProduct(productId : InAppPurchaseProductId) -> InAppPurchaseProduct? {
        
        var instance : InAppPurchaseProduct? = nil
        switch productId {
        case .UnlimitedSaveLocally:
            instance = InAppPurchaseProduct()
            instance?.productId = InAppPurchaseProductId.UnlimitedSaveLocally
            instance?.functions = [UnlimitedSaveLocallyPurchasedExtension()]
            break
        default:
            break
        }
        
        return instance
    }
    
    func purchased(inAppProductId : String) -> Bool {
        if let productId = InAppPurchaseProductId(rawValue: inAppProductId) where self.products[productId] != nil {
            return true
        }
        else{
            return false
        }
    }
}

/**
 購入済み拡張機能
*/
class PurchasedExtension {
    func attach() {
        
    }
    func detach() {
        
    }
}

/**
 購入済み拡張機能（保存無制限）
 */
class UnlimitedSaveLocallyPurchasedExtension : PurchasedExtension {
    override func attach() {
        AppContext.sharedInstance.maxCountOfLocalSaveFolder = unlimitedCount
        AppContext.sharedInstance.maxCountOfLocalSaveCombinationInFolder = unlimitedCount
        AppContext.sharedInstance.maxCountOfCombinationItemsInCategory = unlimitedCount
        AppContext.sharedInstance.maxCountOfCombinationItems = unlimitedCount
        AppContext.sharedInstance.maxCountOfCategory = unlimitedCount
    }
    override func detach() {
        AppContext.sharedInstance.maxCountOfLocalSaveFolder = defalutMaxCountOfLocalSaveFolder
        AppContext.sharedInstance.maxCountOfLocalSaveCombinationInFolder = defalutMaxCountOfLocalSaveCombinationInFolder
        AppContext.sharedInstance.maxCountOfCombinationItemsInCategory = defalutMaxCountOfCombinationItemsInCategory
        AppContext.sharedInstance.maxCountOfCombinationItems = defalutMaxCountOfCombinationItems
        AppContext.sharedInstance.maxCountOfCategory = defalutMaxCountOfCategory
    }
}

enum InAppPurchaseProductId : String {
    case None = ""
    case UnlimitedSaveLocally = "jp.cafe.MixAndMatch.localSaveCountUnlimited" // TODO: あとで変える
}
