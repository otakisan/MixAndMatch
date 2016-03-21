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
    dynamic var creatorType = ""
    dynamic var createdAt = NSDate(timeIntervalSince1970: 0)
    dynamic var updatedAt = NSDate(timeIntervalSince1970: 0)
    var combinationItems: [CombinationItem] {
        return linkingObjects(CombinationItem.self, forProperty: "category")
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override static func indexedProperties() -> [String] {
        return ["name"]
    }
}
