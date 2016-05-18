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
#import "FPAppState.h"

@import Photos;

@import FirebaseStorage;

@interface FPEditPhotoViewController ()
//@property (nonatomic, strong) PFFile *photoFile;
//@property (nonatomic, strong) PFFile *thumbnailFile;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (strong, nonatomic) FIRStorageReference *storageRef;
@property (strong, nonatomic) NSString *fileUrl;
@property (strong, nonatomic) NSString *storageUri;
@end

@implementation FPEditPhotoViewController

#pragma mark - NSObject

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];

  NSLog(@"Memory warning on Edit");
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [_imageView initWithImage:_image];

  _storageRef = [[FIRStorage storage] reference];

  [self shouldUploadImage:self.referenceURL];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self doneButtonAction:textField];
  [textField resignFirstResponder];
  return YES;
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
                               NSURL *imageFile = contentEditingInput.fullSizeImageURL;
                               NSString *filePath = [NSString stringWithFormat:@"%@/%lld/%@", [FPAppState sharedInstance].currentUser.userID, (long long)([[NSDate date] timeIntervalSince1970] * 1000.0), [_referenceURL lastPathComponent]];
                               FIRStorageMetadata *metadata = [FIRStorageMetadata new];
                               metadata.contentType = @"image/jpeg";
                               [[_storageRef child:filePath]
                                putFile:imageFile metadata:metadata
                                completion:^(FIRStorageMetadata *metadata, NSError *error) {
                                  if (error) {
                                    NSLog(@"Error uploading: %@", error);
                                    return;
                                  }
                                  _fileUrl = [metadata.downloadURLs[0] absoluteString];
                                  _storageUri = [_storageRef child:metadata.path].description;
                                }
                                ];
                             }];
  return YES;
}

- (IBAction)doneButtonAction:(id)sender {

  // Push data to Firebase Database
  NSString *trimmedComment = [self.commentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSDictionary * data = @{ @"url" : _fileUrl,
                           @"storage_uri": _storageUri,
                           @"text" : trimmedComment,
                           @"author" : [[FPAppState sharedInstance].currentUser author],
                           @"timestamp" : FIRServerValue.timestamp
                           };

  FIRDatabaseReference *ref;
  ref = [FIRDatabase database].reference;
  FIRDatabaseReference *photo = [[ref child:@"posts"] childByAutoId];
  [photo setValue:data];
  NSString *postId = photo.key;
  [ref updateChildValues:@{
                           [NSString stringWithFormat:@"people/%@/posts/%@", [FPAppState sharedInstance].currentUser.userID, postId]: @YES,
                           [NSString stringWithFormat:@"feed/%@/%@", [FPAppState sharedInstance].currentUser.userID, postId]: @YES
                           }];
  [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonAction:(id)sender {
  [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
