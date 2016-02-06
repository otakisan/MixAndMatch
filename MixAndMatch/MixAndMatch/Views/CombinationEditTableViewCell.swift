//
//  CombinationEditTableViewCell.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit

class CombinationEditTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    
    var delegate : CombinationEditTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.nameTextField.delegate = self
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(combination : Combination) {
        self.nameTextField.text = combination.name
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.nameTextField.resignFirstResponder()
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool{
        let replaced = (textField.text ?? "" as NSString).stringByReplacingCharactersInRange(range, withString: string)
        print("combination name : \(replaced)")
        self.delegate?.nameTextChanged(replaced)
        
        return true
    }
}

protocol CombinationEditTableViewCellDelegate {
    func nameTextChanged(changedText : String)
}