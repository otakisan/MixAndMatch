//
//  AdBannerViewController.swift
//  MixAndMatch
//
//  Created by takashi on 2016/04/23.
//  Copyright © 2016年 Takashi Ikeda. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AdBannerViewController: UIViewController {

    @IBOutlet weak var adBannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // ツールバーの色と合わせる
        self.view.backgroundColor = UIColor(colorLiteralRed: 249.0/255.0, green: 249.0/255.0, blue: 249.0/255.0, alpha: 1.0)
        
        self.initAdBannerView()
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

    private func initAdBannerView(){
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        
        self.adBannerView.rootViewController = self
        let gadRequest = GADRequest()
        self.adBannerView.loadRequest(gadRequest)
    }
}
