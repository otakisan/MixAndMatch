//
//  UIViewControllerExtensions.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import Photos

extension UIViewController {
    func showAlertMessage(title : String?, message : String?, okHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: okHandler))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showOkCancelAlertMessage(title : String?, message : String?, okCaption : String, cancelCaption : String, okHandler: ((UIAlertAction) -> Void)?, cancelHandler: ((UIAlertAction) -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: okCaption, style: .Default, handler: okHandler))
        alert.addAction(UIAlertAction(title: cancelCaption, style: .Cancel, handler: cancelHandler))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showOkCancelAlertMessage(title : String?, message : String?, okHandler: ((UIAlertAction) -> Void)?, cancelHandler: ((UIAlertAction) -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: okHandler))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .Cancel, handler: cancelHandler))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func close(animated: Bool, completion: (() -> Void)?) {
        if self.navigationController?.viewControllers.first == self {
            self.dismissViewControllerAnimated(animated, completion: completion)
        } else {
            self.navigationController?.popToViewController(self, animated: animated)
        }
    }
    
    func promotePhotosAccesibility() {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .NotDetermined:
            // 問い合わせる
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.Denied {
                    // 設定画面へ誘導
                    self.showOkCancelAlertMessage("写真をお取り扱いするためのアクセス権が必要です。", message: "写真へのアクセス権を付与していただくと、写真を表示することができます。", okHandler: {action in PhotosUtility.showPhotosPrivacySettings()}, cancelHandler: nil)
                }
            })
            break
        case .Denied:
            // 設定画面へ誘導
            self.showOkCancelAlertMessage("写真をお取り扱いするためのアクセス権が必要です。", message: "写真へのアクセス権を付与していただくと、写真を表示することができます。", okHandler: {action in PhotosUtility.showPhotosPrivacySettings()}, cancelHandler: nil)
            break
            
        case .Restricted:
            // 写真の使用が制限されているため、本アプリで写真を扱うことができない
            self.showAlertMessage("写真の使用が制限されています。", message: "iOSの機能制限の設定で、写真の使用が制限されているため、本アプリで写真を扱うことができません。", okHandler: nil)
            break
            
        case .Authorized:
            // 承認の場合は何もしない。
            break
        }
    }

    func showViewControllerByStoryboardId(viewControllerIdentifier: String, storyboardName : String, initialize : ((UIViewController) -> Void)?) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        let viewController = storyboard.instantiateViewControllerWithIdentifier(viewControllerIdentifier)
        let newNV = UINavigationController(rootViewController: viewController)
        initialize?(viewController)
        
        self.presentViewController(newNV, animated: true, completion: nil)
        
        return viewController
    }
    
    func addCloseBarButtonItemIfRootViewControllerOfNavigationController() {
        if self.navigationController?.viewControllers.first == self {
            let closeBarButtonItem = UIBarButtonItem(title: "閉じる", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.onTapCloseBarButtonItemWhenFirstViewControllerOfNavigationController(_:)))
            if var leftBarButtonItems = self.navigationItem.leftBarButtonItems {
                leftBarButtonItems.append(closeBarButtonItem)
            }else{
                self.navigationItem.leftBarButtonItem = closeBarButtonItem
            }
        }
    }
    
    func onTapCloseBarButtonItemWhenFirstViewControllerOfNavigationController(barButtonItem : UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension UITableViewController {
    func forEachCells( block : ((indexPath : NSIndexPath, cell : UITableViewCell) -> Void) ) {
        for sectionIndex in 0..<self.tableView.numberOfSections {
            for rowIndex in 0..<self.tableView.numberOfRowsInSection(sectionIndex){
                if let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowIndex, inSection: sectionIndex)){
                    block(indexPath: NSIndexPath(forRow: rowIndex, inSection: sectionIndex), cell: cell)
                }
            }
        }
    }
    
    /**
     データのない部分の罫線を隠します
     */
    func hideExtraFooterLine() {
        self.tableView.tableFooterView = UIView()
    }
}