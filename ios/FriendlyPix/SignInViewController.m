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


#import "SignInViewController.h"
#import "FirebaseAuthProviderGoogle/FIRGoogleSignInAuthProvider.h"
#import "FirebaseAuth/FIRUser.h"
#import "FirebaseApp/FIRFirebaseApp.h"
#import "FirebaseApp/FIRFirebaseOptions.h"
#import "FPUser.h"
#import "FirebaseAuthUI/FIRAuthUI.h"
@import Firebase.AdMob;


@interface SignInViewController : UIViewController <FIRAuthUIDelegate>
@end

@implementation SignInViewController

- (IBAction)didTapSignIn:(UIButton *)sender {
  FIRAuth *firebaseAuth = [FIRAuth auth];
  FIRAuthUI *firebaseAuthUI =
  [FIRAuthUI authUIWithAuth:firebaseAuth delegate:self];
  [firebaseAuthUI presentSignInWithCallback:^(FIRUser *_Nullable user,
                                              NSError *_Nullable error) {
    if (error) {
      NSLog(error.localizedDescription);
      return;
    }

    Firebase *ref;
    ref = [[Firebase alloc] initWithUrl:[FIRContext sharedInstance].serviceInfo.databaseURL];
    Firebase *peopleRef = [ref childByAppendingPath: [NSString stringWithFormat:@"people/%@", user.userId]];
    [peopleRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *peopleSnapshot) {
      if (peopleSnapshot.exists) {
        [FPAppState sharedInstance].currentUser = [[FPUser alloc] initWithSnapshot:peopleSnapshot];
      } else {
        NSDictionary *person = @{
                                 @"username" : user.email,
                                 @"full_name" : user.displayName,
                                 @"profile_picture" : [user.photoURL absoluteString]
                                };

        [peopleRef setValue:person];
      }
      [self signedIn];
    }];
  }];
}

- (void)signedIn {
  [self performSegueWithIdentifier:@"SignInToFP" sender:nil];
}


@end
