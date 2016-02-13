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
let defalutMaxCountOfLocalSaveCombinationInFolder = 4
let defalutMaxCountOfCombinationItemsInCategory = 10
let defalutMaxCountOfCombinationItems = 6

class AppContext: NSObject {
    static let sharedInstance = AppContext()
    
    var maxCountOfLocalSaveFolder = defalutMaxCountOfLocalSaveFolder
    var maxCountOfLocalSaveCombinationInFolder = defalutMaxCountOfLocalSaveCombinationInFolder
    var maxCountOfCombinationItemsInCategory = defalutMaxCountOfCombinationItemsInCategory
    var maxCountOfCombinationItems = defalutMaxCountOfCombinationItems
}
