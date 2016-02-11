//
//  AppDelegate.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/23.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // ローカルレシートから、購入済みアイテムを取得
        // TODO: 専用の管理クラスで取り扱うようリファクタする
        // TODO: 復元や購入が完了したタイミングでも課金アイテムの状態を更新する必要あり
        let receipt = ReceiptValidator.defaultValidator.verifyAndObtainReceipt()
        print(receipt)

        // Attach an observer to the payment queue        
        SKPaymentQueue.defaultQueue().addTransactionObserver(AppStoreObserver.sharedInstance)

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Remove the observer
        SKPaymentQueue.defaultQueue().removeTransactionObserver(AppStoreObserver.sharedInstance)
    }


}

