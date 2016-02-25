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
