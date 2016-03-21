//
//  MyCategoryListTableViewCell.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class MyCategoryListTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // imageViewを正方形にする。ラベルの位置も合わせて補正する。
        self.imageView?.clipsToBounds = true
        self.imageView?.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleHeight.rawValue | UIViewAutoresizing.FlexibleWidth.rawValue)
        self.imageView?.contentMode = .ScaleAspectFill
        
        let imageViewX = self.imageView?.frame.origin.x ?? 0
        self.imageView?.frame = CGRectMake(
            imageViewX,
            self.imageView?.frame.origin.y ?? 0,
            self.imageView?.frame.size.height ?? 0,
            self.imageView?.frame.size.height ?? 0
        )
        
        // 詳細テキストの幅を先に確保
        let margin = CGFloat(15.0)
        let detailTextLabelWidth = CGFloat(50.0)
        let textLabelX = imageViewX + (self.imageView?.frame.size.width ?? 0) + margin
        let textLabelWidth = self.frame.size.width - (textLabelX + imageViewX + detailTextLabelWidth + margin)
        self.textLabel?.frame = CGRectMake(
            textLabelX,
            self.textLabel?.frame.origin.y ?? 0,
            textLabelWidth,
            self.textLabel?.frame.size.height ?? 0
        )
        let detailTextLabelX = textLabelX + textLabelWidth + margin
        self.detailTextLabel?.frame = CGRectMake(
            detailTextLabelX,
            self.detailTextLabel?.frame.origin.y ?? 0,
            detailTextLabelWidth,
            self.detailTextLabel?.frame.size.height ?? 0
        )

    }

}
