//
//  MyCategoryContainerViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/27.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class MyCategoryContainerViewController: UIViewController, MyCategoryViewControllerDelegate {

    var myCategory : Category?
    var delegate : MyCategoryViewControllerDelegate?

    @IBAction func onTapAddCombinationItemBarButtonItem(sender: UIBarButtonItem) {
        if let combiListVc = self.myCategoryCombinationItemListTableViewController {
            combiListVc.addCombinationItem()
        }
    }
    
    @IBAction func onTapEditListBarButtonItem(sender: UIBarButtonItem) {
        if let combiListVc = self.myCategoryCombinationItemListTableViewController {
            combiListVc.setEditing(!combiListVc.editing, animated: true)
            sender.title = combiListVc.editing ? "完了" : "編集"
        }
    }
    
    var myCategoryViewController : MyCategoryViewController? {
        get {
            return self.childViewControllers.filter({$0 is MyCategoryViewController}).first as? MyCategoryViewController
        }
    }
    
    var myCategoryCombinationItemListTableViewController : MyCategoryCombinationItemListTableViewController? {
        get {
            return self.childViewControllers.filter({$0 is MyCategoryCombinationItemListTableViewController}).first as? MyCategoryCombinationItemListTableViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "カテゴリー編集"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func didSaveMyCategory(myCategory : Category){
        self.delegate?.didSaveMyCategory(myCategory)
    }
}
