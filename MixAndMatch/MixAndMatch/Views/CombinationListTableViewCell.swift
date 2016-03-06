//
//  CombinationListTableViewCell.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class CombinationListTableViewCell: UITableViewCell {

    struct Constants {
        struct Nib {
            static let name = "CombinationListCollectionViewCell"
        }
        
        struct TableViewCell {
            static let identifier = "combinationListCollectionViewCell"
        }
    }

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var updatedAtLabel: UILabel!
    @IBOutlet weak var combinationItemsCollectionView: UICollectionView!
    
    private var combination : Combination!
    var delegate : CombinationListTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let nib = UINib(nibName: Constants.Nib.name, bundle: nil)
        self.combinationItemsCollectionView.registerNib(nib, forCellWithReuseIdentifier: Constants.TableViewCell.identifier)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(combination : Combination) {
        self.combination = combination
        print(self.combination)
        
        self.combinationItemsCollectionView.dataSource = self
        self.combinationItemsCollectionView.delegate = self
        
        self.nameLabel.text = combination.name
        if NSDate(timeIntervalSinceNow: -86400).compare(combination.updatedAt) == NSComparisonResult.OrderedAscending {
            self.updatedAtLabel.text = "24時間以内に更新 \(DateUtility.localTimeString(combination.updatedAt))"
        }else{
            self.updatedAtLabel.text = DateUtility.localDateString(combination.updatedAt)
        }
        
        self.combinationItemsCollectionView.reloadData()
    }
}

extension CombinationListTableViewCell : UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        return self.combination.combinationItems.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.TableViewCell.identifier, forIndexPath: indexPath) as! CombinationListCollectionViewCell
        
        cell.configure(self.combination.combinationItems[indexPath.row])
        
        return cell
        
    }
}

extension CombinationListTableViewCell : UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        self.delegate?.didSelectCombinationItem(self.combination, combinationItem: self.combination.combinationItems[indexPath.row])
    }
}

protocol CombinationListTableViewCellDelegate {
    func didSelectCombinationItem(combination : Combination, combinationItem : CombinationItem)
}
