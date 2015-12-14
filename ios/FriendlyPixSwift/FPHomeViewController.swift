//
//  FPHomeViewController.swift
//  FriendlyPix
//
//  Created by Ibrahim Ulukaya on 12/3/15.
//  Copyright © 2015 Google Inc. All rights reserved.
//
import UIKit

@objc(FPHomeViewController)
class FPHomeViewController: FPPhotoTimelineViewController, UIActionSheetDelegate {
  var firstLaunch: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()

      // self.navigationItem.rightBarButtonItem = [[PAPSettingsButtonItem alloc] initWithTarget:self action:@selector(settingsButtonAction:)];
      

        // Do any additional setup after loading the view.
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

}
