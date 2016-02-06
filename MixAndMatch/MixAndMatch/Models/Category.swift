//
//  Category.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class Category: Object {
    dynamic var uuid = ""
    dynamic var name = ""
    let combinationItems = List<CombinationItem>()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
