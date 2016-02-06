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
        // TODO: アルバムから画像を取得して表示
        // combinationItemの中にパスが必要
        //print("localId : \(combinationItem.localFileURL)")
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([combinationItem.localFileURL], options: nil)
        var assetFetched : PHAsset?
        fetchResult.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            assetFetched = asset as? PHAsset
            stop.memory = true
        }
        
        PHImageManager.defaultManager().requestImageForAsset(assetFetched!, targetSize: CGSizeMake(130, 130), contentMode: PHImageContentMode.AspectFit, options: nil) { (image, info) -> Void in
            if let itemImage = image {
                self.combinationItemImageView.contentMode = .ScaleAspectFill
                self.combinationItemImageView.image = itemImage
            }
        }
    }

}
