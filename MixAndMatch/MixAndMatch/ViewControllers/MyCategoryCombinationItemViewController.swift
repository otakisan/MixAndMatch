//
//  MyCategoryCombinationItemViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/03/27.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import Photos

class MyCategoryCombinationItemViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    enum TextFieldTag : Int {
        case Name
        case Memo
    }
    
    var combinationItem : CombinationItem?
    var delegate : MyCategoryCombinationItemViewControllerDelegate?

    @IBOutlet weak var combinationItemNameTextField: UITextField!
    @IBOutlet weak var combinationItemMemoTextField: UITextField!
    @IBOutlet weak var combinationItemImageView: UIImageView!
    
    @IBAction func touchUpInsideAddOrUpdateCombinationItemImageButton(sender: UIButton) {
        self.showImagePickerViewController(.PhotoLibrary)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.initialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func initialize() {
        self.navigationItem.title = "アイテム編集"
        
        // 一旦、画像の高さは固定とする（高さ固定はAutoLayoutで実施）
        self.combinationItemImageView.clipsToBounds = true
        self.combinationItemImageView.contentMode = .ScaleAspectFill
        self.combinationItemImageView.image = ImageUtility.blankImage(CGSizeMake(256, 256))
        self.fetchAndSetImage(self.combinationItem?.localFileURL ?? "")
        
        self.combinationItemNameTextField.tag = TextFieldTag.Name.rawValue
        self.combinationItemNameTextField.text = self.combinationItem?.name
        self.combinationItemMemoTextField.tag = TextFieldTag.Memo.rawValue
        self.combinationItemMemoTextField.text = self.combinationItem?.memo
        
        // 1.キーボード表示する際に送られるNSNotificationを受け取るための処理を追加
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "willShowKeyboard:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "willHideKeyboard:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // 2.送られてきたNSNotificationを処理して、キーボードの高さを取得する
    func willShowKeyboard(notification : NSNotification) {
        
        if let userInfo = notification.userInfo {
            if let keyboard = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                let keyBoardRect = keyboard.CGRectValue()
                
                NSLog("\(keyBoardRect.size.height)")
                self.offsetOnShowKeyboard(keyBoardRect.size.height)
            }
        }
    }
    
    func willHideKeyboard(notification : NSNotification) {
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: self.view.frame.origin.y * -1.0)
    }
    
    private func offsetOnShowKeyboard(height : CGFloat) {
        // キーボードの高さが発生した場合に、不足分だけ画面を移動させる
        let currentVisibleBottom = UIScreen.mainScreen().bounds.height - height
        let mustVisibleBottom = self.view.frame.origin.y + self.combinationItemMemoTextField.frame.origin.y + self.combinationItemMemoTextField.frame.size.height + 15.0
        
        // 横表示の場合、一番下のviewの高さよりも、テキストフィールドのyの値が大きくなるため、viewの高さを調整する（しないと、黒背景が表示される）
        let lackOfHeight = max(0, mustVisibleBottom - self.view.frame.size.height) / 2.0
        self.view.frame = self.view.frame.insetBy(dx: 0, dy: -lackOfHeight)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: min(0, currentVisibleBottom - mustVisibleBottom + lackOfHeight))
    }
    
    private func fetchAndSetImage(localIdentifier : String) {
        let fetchResult = PHAsset.fetchAssetsWithLocalIdentifiers([localIdentifier], options: nil)
        var assetFetched : PHAsset?
        fetchResult.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
            assetFetched = asset as? PHAsset
            stop.memory = true
        }
        
        guard let assetFetchedUnwrapped = assetFetched else {
            return
        }
        
        PHImageManager.defaultManager().requestImageForAsset(assetFetchedUnwrapped, targetSize: CGSizeMake(self.combinationItemImageView.frame.size.width, self.combinationItemImageView.frame.size.height), contentMode: PHImageContentMode.AspectFit, options: nil) { (image, info) -> Void in
            if let itemImage = image, let resultIsDegradedKey = info?[PHImageResultIsDegradedKey] as? Int where resultIsDegradedKey == 0 {
                self.combinationItemImageView.image = itemImage
            }
        }
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return textField.endEditing(false)
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let currentText = textField.text, let tag = TextFieldTag(rawValue: textField.tag), let combinationItem = self.combinationItem {
            let replacedText = (currentText as NSString).stringByReplacingCharactersInRange(range, withString: string)
            print("textField : \(textField.text)")
            print("range : \(range)")
            print("replacementString : \(string)")
            print("replacedText : \(replacedText)")
            
            switch tag {
            case .Name:
                let _ = try? combinationItem.realm?.write({
                    combinationItem.name = replacedText
                    self.delegate?.didSaveCombinationItem(combinationItem)
                })
                break
            case .Memo:
                let _ = try? combinationItem.realm?.write({
                    combinationItem.memo = replacedText
                    self.delegate?.didSaveCombinationItem(combinationItem)
                })
                break
            }
        }
        
        return true
    }

    private func showImagePickerViewController(sourceType : UIImagePickerControllerSourceType) -> UIImagePickerController {
        let imageViewController = UIImagePickerController()
        imageViewController.sourceType = sourceType
        imageViewController.delegate = self
        imageViewController.allowsEditing = true
        self.presentViewController(imageViewController, animated: true, completion: nil)
        
        return imageViewController
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]){
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        // TODO: 動画の場合は、サイズチェック、静止画表示、データは別途保持する
        if let selectedImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
            print("selectedImageUrl : \(selectedImageUrl)")
            
            // アプリのアルバムは作成せず、指定画像のlocalIdentifierをそのまま保存する
            if let phAsset = PHAsset.fetchAssetsWithALAssetURLs([selectedImageUrl], options: nil).firstObject as? PHAsset {
                if let combinationItem = self.combinationItem {
                    let _ = try? combinationItem.realm?.write({ () -> Void in
                        combinationItem.localFileURL = phAsset.localIdentifier
                        if let combinationItem = self.combinationItem {
                            self.delegate?.didSaveCombinationItem(combinationItem)
                        }
                    })
                    self.fetchAndSetImage(phAsset.localIdentifier)
                }
            }
        }
    }
}

protocol MyCategoryCombinationItemViewControllerDelegate {
    func didSaveCombinationItem(combinationItem : CombinationItem)
}
