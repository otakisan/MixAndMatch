//
//  CombinationItemCombinationEditTableViewCell.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import RealmSwift

class CombinationItemCombinationEditTableViewCell: UITableViewCell {

    @IBOutlet weak var combinationItemCollectionView: UICollectionView!
    
    var selectedCombinationItem : CombinationItem?
    var combinationItems : [CombinationItem] = []
    var delegate : CombinationItemCombinationEditTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // UILongPressGestureRecognizer宣言
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "cellLongPressed:")
        
        // `UIGestureRecognizerDelegate`を設定するのをお忘れなく
        longPressRecognizer.delegate = self
        
        // tableViewにrecognizerを設定
        combinationItemCollectionView.addGestureRecognizer(longPressRecognizer)
    }
    
    func cellLongPressed(recognizer: UILongPressGestureRecognizer) {
        
        // 押された位置でcellのPathを取得
        let point = recognizer.locationInView(combinationItemCollectionView)
        let indexPath = combinationItemCollectionView.indexPathForItemAtPoint(point)
        
        if indexPath == nil {
            
        } else if recognizer.state == UIGestureRecognizerState.Began  {
            // 長押しされた場合の処理
            print("長押しされたcellのindexPath:\(indexPath?.row)")
            self.showAlertAndDeleteCombinationItem(indexPath!)
        }
    }
    
    func showAlertAndDeleteCombinationItem(indexPath : NSIndexPath) {
        let alert = UIAlertController(title: "アイテムを削除しますか？", message: nil, preferredStyle: .Alert)
        let yesAction = UIAlertAction(title: "削除します", style: .Default) { (action) -> Void in
            if let realm = try? Realm() {
                let _ = try? realm.write({ () -> Void in
                    let removed = self.combinationItems.removeAtIndex(indexPath.row)
                    print("removing item from the category : \(removed)")
                    removed.category?.combinationItems.removeAtIndex(indexPath.row)
                    self.combinationItemCollectionView.reloadData()
                })
            }
        }
        let noAction = UIAlertAction(title: "キャンセルします", style: .Default) { (action) -> Void in
            
        }
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        self.delegate?.requestForPresentViewController(alert)

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(item : CombinationItem) {
        self.combinationItems = item.category?.combinationItems.map{$0} ?? []
        print("item : \(item)")
        self.setSelectedCombinationItem(item)
        
        self.combinationItemCollectionView.dataSource = self
        self.combinationItemCollectionView.delegate = self
        self.combinationItemCollectionView.reloadData()
    }
    
    func selectCurrentCombinationItem() {
        if let index = self.combinationItems.indexOf({$0.uuid == self.selectedCombinationItem?.uuid}) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            self.combinationItemCollectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.Bottom)
            self.collectionView(self.combinationItemCollectionView, didSelectItemAtIndexPath: indexPath)
        }
    }
    
    func changeAppearance(cell : CombinationItemCollectionViewCell, selected : Bool) {
        cell.layer.borderWidth = selected ? 1.0 : 0
        cell.layer.borderColor = selected ? UIColor.blueColor().CGColor : UIColor.clearColor().CGColor
        cell.visibleCheckmark = selected
    }
    
    private func setSelectedCombinationItem(item : CombinationItem) {
        self.selectedCombinationItem = item
        self.delegate?.didSelectCombinationItem(item)
    }
}

extension CombinationItemCombinationEditTableViewCell : UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return self.combinationItems.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("combinationItemCollectionViewCell", forIndexPath: indexPath) as! CombinationItemCollectionViewCell
        
        cell.configure(self.combinationItems[indexPath.row])
        return cell
    }
}

extension CombinationItemCombinationEditTableViewCell : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        // ここはあくまで、ユーザーがタップして選択した場合の処理
        // selectItemAtIndexPathを呼んだ後、直接コールしないこと（しても、セルが取れない）
        self.setSelectedCombinationItem(self.combinationItems[indexPath.row])
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CombinationItemCollectionViewCell {
            self.changeAppearance(cell, selected: true)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CombinationItemCollectionViewCell {
            self.changeAppearance(cell, selected: false)
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // 再表示時に外観を整える必要がある
        if self.combinationItems[indexPath.row].uuid == self.selectedCombinationItem?.uuid {
            self.combinationItemCollectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            self.changeAppearance(cell as! CombinationItemCollectionViewCell, selected: true)
        } else {
            self.combinationItemCollectionView.deselectItemAtIndexPath(indexPath, animated: false)
            self.changeAppearance(cell as! CombinationItemCollectionViewCell, selected: false)
        }
    }
}

protocol CombinationItemCombinationEditTableViewCellDelegate {
    func didSelectCombinationItem(combinationItem : CombinationItem)
    func requestForPresentViewController(viewController : UIViewController)
}