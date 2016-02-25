//
//  Folder.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class Folder: Object {
    dynamic var uuid = ""
    dynamic var name = ""
    dynamic var createdAt = NSDate(timeIntervalSince1970: 0)
    var combinations: [Combination] {
        return linkingObjects(Combination.self, forProperty: "folder")
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }

    override static func indexedProperties() -> [String] {
        return ["name"]
    }
}
