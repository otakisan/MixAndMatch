//
//  Combination.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class Combination: Object {
    dynamic var uuid = ""
    dynamic var name = ""
    dynamic var createdAt = NSDate(timeIntervalSince1970: 0)
    dynamic var folder: Folder? // Properties can be optional
    let combinationItems = List<CombinationItem>()

    override static func primaryKey() -> String? {
        return "uuid"
    }
}
