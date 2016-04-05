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

#import "FPHomeViewController.h"
#import "FPAppState.h"
@import FirebaseAuth;

@implementation FPHomeViewController

- (void)loadFeed {
  // Listen for new messages in the Firebase database

  [[super.ref child: [NSString stringWithFormat:@"feed/%@", [FPAppState sharedInstance].currentUser.userID]]
   observeEventType:FIRDataEventTypeChildAdded
   withBlock:^(FIRDataSnapshot *feedSnapshot) {
     [[super.ref child:[@"posts/" stringByAppendingString:feedSnapshot.key]]
      observeEventType:FIRDataEventTypeValue
      withBlock:^(FIRDataSnapshot *postSnapshot) {
        [super loadPost:postSnapshot];
      }];
   }];
}

- (IBAction)didTapSignOut:(id)sender {
  NSError *signOutError;
  BOOL status = [[FIRAuth auth] signOut:&signOutError];
  if (!status) {
    NSLog(@"Error signing out: %@", signOutError);
    return;
  }
  [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}
@end
