//
//  CombinationItemsOfMyCategoryCollectionViewCell.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class CombinationItemsOfMyCategoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var combinationItemImageView: UIImageView!
    
    var combinationItem : CombinationItem?
    
    func configure(combinationItem : CombinationItem) {
        self.combinationItem = combinationItem
        
        if let url = self.combinationItem?.localFileURL {
            PhotosUtility.requestImageForLocalIdentifier(url, targetSize: CGSize(width: self.frame.width, height: self.frame.height), contentMode: .AspectFill, options: nil, resultHandler: { (image, info) -> Void in
                self.combinationItemImageView.image = image
            })
        }
    }
}
