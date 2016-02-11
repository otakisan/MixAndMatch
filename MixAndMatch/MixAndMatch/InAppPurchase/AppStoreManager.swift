//
//  AppStoreManager.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/07.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import StoreKit

class AppStoreManager: NSObject, SKRequestDelegate, SKProductsRequestDelegate {
    let IAPProductRequestNotification = "IAPProductRequestNotification"

    static let sharedInstance = AppStoreManager()
    var availableProducts : [SKProduct] = []
    var productRequestResponse : [(name : String, elements : [SKProduct])] = []
    var status : IAPProductRequestStatus = .ProductsFound
    
    // Fetch information about your products from the App Store
    func fetchProductInformationForIds(productIds : [String]) {
        self.productRequestResponse = []
        // Create a product request object and initialize it with our product identifiers
        let request = SKProductsRequest(productIdentifiers: Set(productIds))
        request.delegate = self
    
        // Send the request to the App Store
        request.start()
    }
    
    // SKProductsRequestDelegate
    
    // Used to get the App Store's response to your request and notifies your observer
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse){
        
        // The products array contains products whose identifiers have been recognized by the App Store.
        // As such, they can be purchased. Create an "AVAILABLE PRODUCTS" model object.
        if ((response.products).count > 0)
        {
            self.productRequestResponse += [(name : "AVAILABLE PRODUCTS", elements : response.products)]
            self.availableProducts = response.products
        }
        
        // The invalidProductIdentifiers array contains all product identifiers not recognized by the App Store.
        // Create an "INVALID PRODUCT IDS" model object.
        if ((response.invalidProductIdentifiers).count > 0)
        {
            //model = [[MyModel alloc] initWithName:@"INVALID PRODUCT IDS" elements:response.invalidProductIdentifiers];
            //[self.productRequestResponse addObject:model];
        }
        
        self.status = .ProductRequestResponse
        NSNotificationCenter.defaultCenter().postNotificationName(IAPProductRequestNotification, object: self)
    }
    
    // SKRequestDelegate method
    
    // Called when the product request failed.
    func request(request: SKRequest, didFailWithError error: NSError){
        print("Product Request Status: \(error.localizedDescription)")
    }
    
    // Helper method
    // Return the product's title matching a given product identifier
    func titleMatchingProductIdentifier(identifier : String) -> String? {
        var productTitle : String? = nil;
        
        // Iterate through availableProducts to find the product whose productIdentifier
        // property matches identifier, return its localized title when found
        for product in self.availableProducts {
            if product.productIdentifier == identifier {
                productTitle = product.localizedTitle
            }
        }
        
        return productTitle
    }
}

enum IAPProductRequestStatus {
    case ProductsFound// Indicates that there are some valid products
    case IdentifiersNotFound // indicates that are some invalid product identifiers
    case ProductRequestResponse // Returns valid products and invalid product identifiers
    case RequestFailed // Indicates that the product request failed
}