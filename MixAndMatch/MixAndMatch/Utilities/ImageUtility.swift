//
//  ImageUtility.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class ImageUtility: NSObject {
    static func blankImage(size : CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let blank  = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return blank
    }
}
