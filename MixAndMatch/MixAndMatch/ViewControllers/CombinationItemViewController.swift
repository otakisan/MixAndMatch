//
//  CombinationItemViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/01/24.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import Photos

class CombinationItemViewController: UIViewController {

    var combinationItem : CombinationItem?
    
    @IBOutlet weak var combinationItemScrollView: UIScrollView!
    @IBOutlet weak var combinationItemImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.initViewController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initViewController() {
        self.initializeImageInteraction()
        
        if let localIdentifier = self.combinationItem?.localFileURL {
            let options = PHImageRequestOptions()
            options.deliveryMode = .HighQualityFormat
            options.resizeMode = .Exact
            PhotosUtility.requestImageForLocalIdentifier(localIdentifier, targetSize: CGSize(width: 4032, height: 4032), contentMode: .AspectFit, options: options, resultHandler: { (image, infoDic) -> Void in
                if let degradedKey = infoDic?["PHImageResultIsDegradedKey"] as? Int where degradedKey == 0 {
                    self.combinationItemImageView.image = image
                }
            })
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

}

extension CombinationItemViewController : UIScrollViewDelegate {
    
    private func initializeImageInteraction() {
        self.combinationItemScrollView.delegate = self
        self.combinationItemScrollView.minimumZoomScale = 1
        self.combinationItemScrollView.maximumZoomScale = 8
        self.combinationItemScrollView.scrollEnabled = true
        self.combinationItemScrollView.showsHorizontalScrollIndicator = true
        self.combinationItemScrollView.showsVerticalScrollIndicator = true
        self.combinationItemScrollView.zoomScale = 1.0
        
        let doubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:"doubleTap:")
        doubleTapGesture.numberOfTapsRequired = 2
        self.combinationItemImageView.userInteractionEnabled = true
        self.combinationItemImageView.addGestureRecognizer(doubleTapGesture)
    }
    
    // ピンチイン・ピンチアウト
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.combinationItemImageView
    }
    
    // ダブルタップ
    func doubleTap(gesture: UITapGestureRecognizer) -> Void {
        
        print(self.combinationItemScrollView.zoomScale)
        if ( self.combinationItemScrollView.zoomScale < self.combinationItemScrollView.maximumZoomScale ) {
            
            let newScale:CGFloat = self.combinationItemScrollView.zoomScale * 3
            let zoomRect:CGRect = self.zoomRectForScale(newScale, center: gesture.locationInView(gesture.view))
            self.combinationItemScrollView.zoomToRect(zoomRect, animated: true)
            
        } else {
            self.combinationItemScrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    // 領域
    func zoomRectForScale(scale : CGFloat, center: CGPoint) -> CGRect{
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = self.combinationItemScrollView.frame.size.height / scale
        zoomRect.size.width = self.combinationItemScrollView.frame.size.width / scale
        
        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0
        
        return zoomRect
    }

}
