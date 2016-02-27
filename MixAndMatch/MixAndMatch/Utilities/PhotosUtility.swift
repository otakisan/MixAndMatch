//
//  PhotosUtility.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/27.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import Photos

class PhotosUtility {
    
    static func requestImageForLocalIdentifier(localFileURL : String, targetSize : CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions?, resultHandler : (UIImage?, [NSObject : AnyObject]?) -> Void) -> PHImageRequestID {
        
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([localFileURL], options: nil)
        var assetFetched : PHAsset?
        fetchResult.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            assetFetched = asset as? PHAsset
            stop.memory = true
        }
        
        guard let assetFetchedUnwrapped = assetFetched else {
            return PHInvalidImageRequestID
        }
        
        return PHImageManager.defaultManager().requestImageForAsset(assetFetchedUnwrapped, targetSize: targetSize, contentMode: contentMode, options: options) { (image, info) -> Void in
            resultHandler(image, info)
        }
    }
}