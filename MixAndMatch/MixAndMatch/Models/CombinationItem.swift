//
//  CombinationItem.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class CombinationItem: Object {
    dynamic var uuid = ""
    dynamic var name = ""
    dynamic var localFileURL = ""
    dynamic var category : Category?
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
