//
//  CombinationItemsOfMyCategoryCollectionViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/13.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class CombinationItemsOfMyCategoryCollectionViewController: UICollectionViewController {
    
    struct Constants {
        struct CollectionViewCell {
            static let identifier = "CombinationItemsOfMyCategoryCollectionViewCell"
            static let numberOfCellsInRow = 3
            static let spacing = 1
        }
    }
    
    var myCategory : Category?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // ストーリーボードを使う場合、下記をコールしてはいけないらしい
        //self.collectionView!.registerClass(CombinationItemsOfMyCategoryCollectionViewCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCell.identifier)

        // Do any additional setup after loading the view.
        
        self.navigationItem.title = self.myCategory?.name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.myCategory?.combinationItems.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Constants.CollectionViewCell.identifier, forIndexPath: indexPath) as! CombinationItemsOfMyCategoryCollectionViewCell
        
        if let combinationItem = self.myCategory?.combinationItems[indexPath.row] {
            cell.configure(combinationItem)
        }
    
        // Configure the cell
    
        return cell
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
}

extension CombinationItemsOfMyCategoryCollectionViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(Constants.CollectionViewCell.spacing)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return CGFloat(Constants.CollectionViewCell.spacing)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let spacingInRow = CGFloat((Constants.CollectionViewCell.numberOfCellsInRow - 1) * Constants.CollectionViewCell.spacing)
        let size = (collectionView.frame.width - spacingInRow) / CGFloat(Constants.CollectionViewCell.numberOfCellsInRow)
        
        return CGSizeMake(size, size)
    }
    
}
