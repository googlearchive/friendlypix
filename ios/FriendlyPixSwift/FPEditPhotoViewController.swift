//
//  FPEditPhotoViewController.swift
//  FriendlyPix
//
//  Created by Ibrahim Ulukaya on 12/1/15.
//  Copyright © 2015 Google Inc. All rights reserved.
//

import UIKit

class FPEditPhotoViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {
  var scrollView: UIScrollView?
  var image: UIImage?
  var commentTextField: UITextField?
  var photoFile: NSFileHandle?
  var thumbnailFile: NSFileHandle?
  var fileUploadBackgroundTaskId: UIBackgroundTaskIdentifier?
  var photoPostBackgroundTaskId: UIBackgroundTaskIdentifier?

  deinit {
  }

  init? (aImage: UIImage?) {
    super.init(nibName: nil, bundle: nil)
    if (aImage == nil) {
      return nil;
    }
    self.image = aImage!
    self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

    override func viewDidLoad() {
        super.viewDidLoad()

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
