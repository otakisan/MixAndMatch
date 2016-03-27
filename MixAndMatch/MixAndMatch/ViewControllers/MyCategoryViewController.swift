//
//  MyCategoryViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/27.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class MyCategoryViewController: UIViewController, UITextFieldDelegate {

    var myCategory : Category?
    var delegate : MyCategoryViewControllerDelegate?
    
    @IBOutlet weak var categoryNameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func didMoveToParentViewController(parent: UIViewController?) {
        if let myCategoryContainerVc = parent as? MyCategoryContainerViewController {
            self.myCategory = myCategoryContainerVc.myCategory
            self.delegate = myCategoryContainerVc
            self.categoryNameTextField.text = self.myCategory?.name
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return self.categoryNameTextField.endEditing(true)
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let replacedText = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        print("textField : \(textField.text)")
        print("range : \(range)")
        print("replacementString : \(string)")
        print("replacedText : \(replacedText)")
        
        // 新規登録済みカテゴリーの前提
        if let myCategory = self.myCategory {
            let _ = try? myCategory.realm?.write({ () -> Void in
                myCategory.name = replacedText
                self.delegate?.didSaveMyCategory(myCategory)
            })
        }
        
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol MyCategoryViewControllerDelegate {
    func didSaveMyCategory(myCategory : Category)
}