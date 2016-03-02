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


#import "FPEditPhotoViewController.h"
#import "FPPhotoDetailsFooterView.h"

#import "FirebaseStorage.h"
@import Firebase.Core;
@import FirebaseApp;
@import Photos;

@interface FPEditPhotoViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *referenceURL;
@property (nonatomic, strong) UITextField *commentTextField;
//@property (nonatomic, strong) PFFile *photoFile;
//@property (nonatomic, strong) PFFile *thumbnailFile;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;
@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (strong, nonatomic) NSString *fileUrl;
@end

@implementation FPEditPhotoViewController

#pragma mark - NSObject

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (id)initWithImage:(UIImage *)aImage referenceUrl:(NSURL *)referenceUrl{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    if (!aImage) {
      return nil;
    }

    self.image = aImage;
    self.referenceURL = referenceUrl;
    self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid;
    self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
  }
  return self;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];

  NSLog(@"Memory warning on Edit");
}


#pragma mark - UIViewController

- (void)loadView {
  self.scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  self.scrollView.delegate = self;
  self.scrollView.backgroundColor = [UIColor blackColor];
  self.view = self.scrollView;

  UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 42.0f, 320.0f, 320.0f)];
  [photoImageView setBackgroundColor:[UIColor blackColor]];
  [photoImageView setImage:self.image];
  [photoImageView setContentMode:UIViewContentModeScaleAspectFit];

  [self.scrollView addSubview:photoImageView];

  CGRect footerRect = [FPPhotoDetailsFooterView rectForView];
  footerRect.origin.y = photoImageView.frame.origin.y + photoImageView.frame.size.height;

  FPPhotoDetailsFooterView *footerView = [[FPPhotoDetailsFooterView alloc] initWithFrame:footerRect];
  self.commentTextField = footerView.commentField;
  self.commentTextField.delegate = self;
  [self.scrollView addSubview:footerView];

  [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, photoImageView.frame.origin.y + photoImageView.frame.size.height + footerView.frame.size.height)];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  FIRFirebaseApp *app = [FIRFirebaseApp app];
  self.storageRef = [[FIRStorage storageForApp:app] reference];

  [self.navigationItem setHidesBackButton:YES];

  self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar.png"]];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonAction:)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Publish" style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonAction:)];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

  [self shouldUploadImage:self.referenceURL];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self doneButtonAction:textField];
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self.commentTextField resignFirstResponder];
}


#pragma mark - ()

- (BOOL)shouldUploadImage:(NSURL *)URL {
  //    UIImage *resizedImage = [anImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
  //    UIImage *thumbnailImage = [anImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:10.0f interpolationQuality:kCGInterpolationDefault];

  // JPEG to decrease file size and enable faster uploads & downloads
  //    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.8f);
  //    NSData *thumbnailImageData = UIImagePNGRepresentation(thumbnailImage);
  //
  //    if (!imageData || !thumbnailImageData) {
  //        return NO;
  //    }

  //    self.photoFile = [PFFile fileWithData:imageData];
  //    self.thumbnailFile = [PFFile fileWithData:thumbnailImageData];

  // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
  //    self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
  //        [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
  //    }];
  //
  //    NSLog(@"Requested background expiration task with id %lu for Anypic photo upload", (unsigned long)self.fileUploadBackgroundTaskId);

  PHFetchResult* assets = [PHAsset fetchAssetsWithALAssetURLs:@[URL] options:nil];
  PHAsset *asset = [assets firstObject];
  [asset requestContentEditingInputWithOptions:nil
                             completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                               NSString *imageFile = [contentEditingInput.fullSizeImageURL absoluteString];
                               NSString *filePath = [NSString stringWithFormat:@"%@/%lld/%@", [FPAppState sharedInstance].currentUser.userID, (long long)([[NSDate date] timeIntervalSince1970] * 1000.0), [_referenceURL lastPathComponent]];
                               FIRStorageMetadata *metadata = [FIRStorageMetadata new];
                               metadata.contentType = @"image/jpeg";
                               [[_storageRef childByAppendingPath:filePath]
                                putFile:imageFile metadata:metadata
                                withCompletion:^(FIRStorageMetadata *metadata, NSError *error) {
                                  if (error) {
                                    NSLog(@"Error uploading: %@", error);
                                    return;
                                  }
                                  _fileUrl = [metadata.downloadURLs[0] absoluteString];
                                }
                                ];
                             }];

  //    [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
  //        if (succeeded) {
  //            NSLog(@"Photo uploaded successfully");
  //            [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
  //                if (succeeded) {
  //                    NSLog(@"Thumbnail uploaded successfully");
  //                }
  //                [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
  //            }];
  //        } else {
  //            [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
  //        }
  //    }];

  return YES;
}

- (void)keyboardWillShow:(NSNotification *)note {
  CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CGSize scrollViewContentSize = self.scrollView.bounds.size;
  scrollViewContentSize.height += keyboardFrameEnd.size.height;
  [self.scrollView setContentSize:scrollViewContentSize];

  CGPoint scrollViewContentOffset = self.scrollView.contentOffset;
  // Align the bottom edge of the photo with the keyboard
  scrollViewContentOffset.y = scrollViewContentOffset.y + keyboardFrameEnd.size.height*3.0f - [UIScreen mainScreen].bounds.size.height;

  [self.scrollView setContentOffset:scrollViewContentOffset animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)note {
  CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  CGSize scrollViewContentSize = self.scrollView.bounds.size;
  scrollViewContentSize.height -= keyboardFrameEnd.size.height;
  [UIView animateWithDuration:0.200f animations:^{
    [self.scrollView setContentSize:scrollViewContentSize];
  }];
}

- (void)doneButtonAction:(id)sender {

  // Push data to Firebase Database
  NSString *trimmedComment = [self.commentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSDictionary * data = @{ @"url" : _fileUrl,
                           @"text" : trimmedComment,
                           @"author" : [FPAppState sharedInstance].currentUser.userID,
                           @"timestamp" : FIRServerValue.timestamp
                           };

  FIRDatabaseReference *ref;
  ref = [FIRDatabase database].reference;
  FIRDatabaseReference *photo = [[ref childByAppendingPath:@"posts"] childByAutoId];
  [photo setValue:data];
  NSString *postId = photo.key;
  [[ref childByAppendingPath: [NSString stringWithFormat:@"users/%@/posts/%@", [FPAppState sharedInstance].currentUser.userID, postId]] setValue:@YES];
  [[ref childByAppendingPath: [NSString stringWithFormat:@"feed/%@/%@", [FPAppState sharedInstance].currentUser.userID, postId]] setValue:@YES];

  [[ref childByAppendingPath: [NSString stringWithFormat:@"users/%@/followers", [FPAppState sharedInstance].currentUser.userID]] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
    if (snapshot.exists) {
      NSDictionary *followers = snapshot.value;
      for (NSString *follower in followers.allKeys) {
        [[ref childByAppendingPath: [NSString stringWithFormat:@"feed/%@/%@", follower, postId]] setValue:@YES];
      }
    }
  }];
  [self.parentViewController dismissViewControllerAnimated:YES completion:nil];



  //    if (!self.photoFile || !self.thumbnailFile) {
  //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
  //        [alert show];
  //        return;
  //    }
  //
  //    // both files have finished uploading
  //
  //    // create a photo object
  //    PFObject *photo = [PFObject objectWithClassName:kPAPPhotoClassKey];
  //    [photo setObject:[PFUser currentUser] forKey:kPAPPhotoUserKey];
  //    [photo setObject:self.photoFile forKey:kPAPPhotoPictureKey];
  //    [photo setObject:self.thumbnailFile forKey:kPAPPhotoThumbnailKey];
  //
  //    // photos are public, but may only be modified by the user who uploaded them
  //    PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
  //    [photoACL setPublicReadAccess:YES];
  //    photo.ACL = photoACL;
  //
  //    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
  //    self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
  //        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
  //    }];

  // save
  //    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
  //        if (succeeded) {
  //            NSLog(@"Photo uploaded");
  //
  //            [[PAPCache sharedCache] setAttributesForPhoto:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];
  //
  //            // userInfo might contain any caption which might have been posted by the uploader
  //            if (userInfo) {
  //                NSString *commentText = [userInfo objectForKey:kPAPEditPhotoViewControllerUserInfoCommentKey];
  //
  //                if (commentText && commentText.length != 0) {
  //                    // create and save photo caption
  //                    PFObject *comment = [PFObject objectWithClassName:kPAPActivityClassKey];
  //                    [comment setObject:kPAPActivityTypeComment forKey:kPAPActivityTypeKey];
  //                    [comment setObject:photo forKey:kPAPActivityPhotoKey];
  //                    [comment setObject:[PFUser currentUser] forKey:kPAPActivityFromUserKey];
  //                    [comment setObject:[PFUser currentUser] forKey:kPAPActivityToUserKey];
  //                    [comment setObject:commentText forKey:kPAPActivityContentKey];
  //
  //                    PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
  //                    [ACL setPublicReadAccess:YES];
  //                    comment.ACL = ACL;
  //
  //                    [comment saveEventually];
  //                    [[PAPCache sharedCache] incrementCommentCountForPhoto:photo];
  //                }
  //            }
  //
  //            [[NSNotificationCenter defaultCenter] postNotificationName:PAPTabBarControllerDidFinishEditingPhotoNotification object:photo];
  //        } else {
  //            NSLog(@"Photo failed to save: %@", error);
  //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
  //            [alert show];
  //        }
  //        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
  //    }];
  //
  //    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonAction:(id)sender {
  [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
