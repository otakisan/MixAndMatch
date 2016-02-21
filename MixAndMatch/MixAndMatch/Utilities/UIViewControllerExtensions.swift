//
//  UIViewControllerExtensions.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlertMessage(title : String?, message : String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showOkCancelAlertMessage(title : String?, message : String?, okHandler: ((UIAlertAction) -> Void)?, cancelHandler: ((UIAlertAction) -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: okHandler))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .Cancel, handler: cancelHandler))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
