//
//  FPTabBarController.swift
//  FriendlyPix
//
//  Created by Ibrahim Ulukaya on 12/1/15.
//  Copyright © 2015 Google Inc. All rights reserved.
//

import MobileCoreServices
protocol FPTabBarControllerDelegate {
  func tabBarController(tabBarController: UITabBarController, cameraButtonTouchUpInsideAction: UIButton)
}

@objc(FPTabBarController)
class FPTabBarController: UITabBarController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  var navController: UINavigationController?

//  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"My Alert"
//  message:@"This is an alert."
//  preferredStyle:UIAlertControllerStyleAlert];

  override func viewDidLoad() {
    super.viewDidLoad()
//    self.tabBar.backgroundColor = UIColor.whiteColor()

      //[[self tabBar] setBackgroundImage:[UIImage imageNamed:@"BackgroundTabBar.png"]];
      //    [[self tabBar] setSelectionIndicatorImage:[UIImage imageNamed:@"BackgroundTabBarItemSelected.png"]];
      // self.tabBar.tintColor = [UIColor colorWithRed:139.0f/255.0f green:111.0f/255.0f blue:95.0f/255.0f alpha:1.0f];


      // iOS 7 style
    self.tabBar.tintColor = UIColor.init(red: 254.0/255.0, green: 149.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    self.tabBar.barTintColor = UIColor.init(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    self.navigationItem.titleView = UIImageView.init(image: UIImage.init(named: "LogoNavigationBar.png"))


    self.navController = UINavigationController()
  }

  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }

  // MARK: - UITabBarController

  override func viewWillAppear(animated: Bool) {
    let cameraButton = UIButton.init(type: UIButtonType.Custom)
    cameraButton.frame = CGRectMake( 94.0, 0.0, 131.0, self.tabBar.bounds.size.height)
    cameraButton.setImage(UIImage.init(named: "ButtonCamera.png"), forState: .Normal)
    cameraButton.setImage(UIImage.init(named: "ButtonCameraSelected.png"), forState: .Highlighted)
    cameraButton.addTarget(self, action: "photoCaptureButtonAction:", forControlEvents: .TouchUpInside)
    self.tabBar.addSubview(cameraButton)

    let swipeUpGestureRecognizer = UISwipeGestureRecognizer.init(target: self, action: "handleGesture:")
    swipeUpGestureRecognizer.direction = (UISwipeGestureRecognizerDirection.Up)
    swipeUpGestureRecognizer.numberOfTouchesRequired = 1
    cameraButton.addGestureRecognizer(swipeUpGestureRecognizer)
  }

  // MARK: - UIImagePickerDelegate

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    dismissViewControllerAnimated(false, completion: nil)

    let image: UIImage = info[UIImagePickerControllerEditedImage] as! UIImage

    let viewController = FPEditPhotoViewController.init(aImage: image)
    viewController!.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve

    self.navController!.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
    self.navController?.pushViewController(viewController!, animated: false)

    self.presentViewController(self.navController!, animated:true, completion:nil)
  }

  // MARK: - UIActionSheetDelegate
//  - (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//  if (buttonIndex == 0) {
//  [self shouldStartCameraController];
//  } else if (buttonIndex == 1) {
//  [self shouldStartPhotoLibraryPickerController];
//  }
//  }


  // MARK: - FPTabBarController

  func shouldPresentPhotoCaptureController() -> Bool {
    var presentedPhotoCaptureController = self.shouldStartCameraController()

    if (!presentedPhotoCaptureController) {
      presentedPhotoCaptureController = self.shouldStartPhotoLibraryPickerController()
    }

    return presentedPhotoCaptureController;
  }

  // MARK: - ()

  func photoCaptureButtonAction(sender: AnyObject) {
    let cameraDeviceAvailable = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
    let photoLibraryAvailable = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)

    if (cameraDeviceAvailable && photoLibraryAvailable) {
//      UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Photo", nil];
//      [actionSheet showFromTabBar:self.tabBar];
    } else {
      // if we don't have at least two options, we automatically show whichever is available (camera or roll)
      self.shouldPresentPhotoCaptureController()
    }
  }

  func shouldStartCameraController() -> Bool {

    if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) == false) {
      return false
    }

    let cameraUI = UIImagePickerController()

    if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) && UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.Camera)!.contains(kUTTypeImage as String)) {

      cameraUI.mediaTypes = [kUTTypeImage as String]
      cameraUI.sourceType = UIImagePickerControllerSourceType.Camera

      if (UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.Rear)) {
        cameraUI.cameraDevice = UIImagePickerControllerCameraDevice.Rear
      } else if (UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.Front)) {
        cameraUI.cameraDevice = UIImagePickerControllerCameraDevice.Front
      }
    } else {
      return false
    }

    cameraUI.allowsEditing = true
    cameraUI.showsCameraControls = true
    cameraUI.delegate = self;

    self.presentViewController(cameraUI, animated:true, completion:nil)

    return true
  }


  func shouldStartPhotoLibraryPickerController() -> Bool {
    if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) == false
  && UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) == false) {
      return false
    }

    let cameraUI = UIImagePickerController()
    if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)
  && UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.PhotoLibrary)!.contains(kUTTypeImage as String)) {

      cameraUI.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
      cameraUI.mediaTypes = [kUTTypeImage as String]

    } else if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum)
  && UIImagePickerController.availableMediaTypesForSourceType(UIImagePickerControllerSourceType.SavedPhotosAlbum)!.contains(kUTTypeImage as String)) {

      cameraUI.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
      cameraUI.mediaTypes = [kUTTypeImage as String]

    } else {
      return false
    }

    cameraUI.allowsEditing = true
    cameraUI.delegate = self

    self.presentViewController(cameraUI, animated:true, completion:nil)

    return true
  }

  func handleGesture(gestureRecognizer:UIGestureRecognizer) {
    self.shouldPresentPhotoCaptureController()
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
