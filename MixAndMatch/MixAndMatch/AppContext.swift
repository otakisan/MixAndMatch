//
//  AppContext.swift
//  MixAndMatch
//
//  Created by takashi on 2016/02/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

let unlimitedCount = Int.max
let defalutMaxCountOfLocalSaveFolder = 5
let defalutMaxCountOfLocalSaveCombinationInFolder = 10
let defalutMaxCountOfCombinationItemsInCategory = 10
let defalutMaxCountOfCombinationItems = 5
let defalutMaxCountOfCategory = 10

let categoryCreatorTypeKey = "creatorType"
let categoryCreatorTypeUser = "user"

class AppContext: NSObject {
    static let sharedInstance = AppContext()
    
    var maxCountOfLocalSaveFolder = defalutMaxCountOfLocalSaveFolder
    var maxCountOfLocalSaveCombinationInFolder = defalutMaxCountOfLocalSaveCombinationInFolder
    var maxCountOfCombinationItemsInCategory = defalutMaxCountOfCombinationItemsInCategory
    var maxCountOfCombinationItems = defalutMaxCountOfCombinationItems
    var maxCountOfCategory = defalutMaxCountOfCategory
}
