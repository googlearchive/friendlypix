//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FPTabBarController.h"
#import "FPEditPhotoViewController.h"
@import MobileCoreServices;

@implementation FPTabBarController

#pragma mark - UITabBarController

- (void)viewWillAppear:(BOOL)animated {
  UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
  cameraButton.frame = CGRectMake( (self.tabBar.bounds.size.width)/3, 0.0f, (self.tabBar.bounds.size.width)/3, self.tabBar.bounds.size.height);
  [cameraButton setImage:[UIImage imageNamed:@"ButtonCamera.png"] forState:UIControlStateNormal];
  [cameraButton setImage:[UIImage imageNamed:@"ButtonCameraSelected.png"] forState:UIControlStateHighlighted];
  [cameraButton addTarget:self action:@selector(photoCaptureButtonAction:) forControlEvents:UIControlEventTouchUpInside];
  [self.tabBar addSubview:cameraButton];

  UISwipeGestureRecognizer *swipeUpGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
  [swipeUpGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
  [swipeUpGestureRecognizer setNumberOfTouchesRequired:1];
  [cameraButton addGestureRecognizer:swipeUpGestureRecognizer];
}



#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [self dismissViewControllerAnimated:NO completion:nil];

  [self performSegueWithIdentifier:@"edit" sender:info];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [self shouldStartCameraController];
  } else if (buttonIndex == 1) {
    [self shouldStartPhotoLibraryPickerController];
  }
}

#pragma mark - PAPTabBarController

- (BOOL)shouldPresentPhotoCaptureController {
  BOOL presentedPhotoCaptureController = [self shouldStartCameraController];

  if (!presentedPhotoCaptureController) {
    presentedPhotoCaptureController = [self shouldStartPhotoLibraryPickerController];
  }

  return presentedPhotoCaptureController;
}

#pragma mark - ()

- (void)photoCaptureButtonAction:(id)sender {
  BOOL cameraDeviceAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
  BOOL photoLibraryAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];

  if (cameraDeviceAvailable && photoLibraryAvailable) {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Photo", nil];
    [actionSheet showFromTabBar:self.tabBar];
  } else {
    // if we don't have at least two options, we automatically show whichever is available (camera or roll)
    [self shouldPresentPhotoCaptureController];
  }
}

- (BOOL)shouldStartCameraController {

  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
    return NO;
  }

  UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];

  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
      && [[UIImagePickerController availableMediaTypesForSourceType:
           UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage]) {

    cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;

    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
      cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
      cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }

  } else {
    return NO;
  }

  cameraUI.allowsEditing = YES;
  cameraUI.showsCameraControls = YES;
  cameraUI.delegate = self;

  [self presentViewController:cameraUI animated:YES completion:nil];

  return YES;
}


- (BOOL)shouldStartPhotoLibraryPickerController {
  if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
       && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) {
    return NO;
  }

  UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
      && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage]) {

    cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];

  } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
             && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage]) {

    cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];

  } else {
    return NO;
  }

  cameraUI.allowsEditing = YES;
  cameraUI.delegate = self;

  [self presentViewController:cameraUI animated:YES completion:nil];

  return YES;
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
  [self shouldPresentPhotoCaptureController];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"edit"])  {
    UINavigationController *navigationController = segue.destinationViewController;
    FPEditPhotoViewController *viewController = (FPEditPhotoViewController *)navigationController.topViewController;
//    FPEditPhotoViewController *viewController = segue.destinationViewController;
    viewController.image = sender[UIImagePickerControllerEditedImage];
    viewController.referenceURL = sender[UIImagePickerControllerReferenceURL];
  }
}

@end
