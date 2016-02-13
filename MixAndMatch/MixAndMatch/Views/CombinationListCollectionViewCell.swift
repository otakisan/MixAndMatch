//
//  CombinationListCollectionViewCell.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/31.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import Photos

class CombinationListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var combinationItemImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(combinationItem : CombinationItem) {
        //print("localId : \(combinationItem.localFileURL)")
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([combinationItem.localFileURL], options: nil)
        var assetFetched : PHAsset?
        fetchResult.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            assetFetched = asset as? PHAsset
            stop.memory = true
        }

        guard let assetFetchedUnwrapped = assetFetched else {
            return
        }
        
        PHImageManager.defaultManager().requestImageForAsset(assetFetchedUnwrapped, targetSize: CGSizeMake(130, 130), contentMode: PHImageContentMode.AspectFit, options: nil) { (image, info) -> Void in
            if let itemImage = image {
                self.combinationItemImageView.contentMode = .ScaleAspectFill
                self.combinationItemImageView.image = itemImage
            }
        }
    }

}
