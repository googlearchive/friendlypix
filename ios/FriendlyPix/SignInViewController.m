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
#import "FPAppState.h"
@import Firebase;
@import GoogleMobileAds;

@implementation SignInViewController

- (void)viewDidAppear:(BOOL)animated {
  FIRUser *user = [FIRAuth auth].currentUser;
  if (user) {
    [self signedIn:user];
  }
}

-(void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
  if (error) {
    NSLog(@"%@", error.localizedDescription);
    return;
  }
  GIDAuthentication *auth = user.authentication;
  FIRAuthCredential *credential = [FIRGoogleAuthProvider credentialWithIDToken:auth.idToken accessToken:auth.accessToken];
  [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser * _Nullable user, NSError * _Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
      return;
    }
    [self signedIn:user];
  }];
}

- (IBAction)didTapSignIn:(UIButton *)sender {
  [GIDSignIn sharedInstance].clientID = [FIRApp defaultApp].options.clientID;
  [GIDSignIn sharedInstance].delegate = self;
  [GIDSignIn sharedInstance].uiDelegate = self;
  [[GIDSignIn sharedInstance] signIn];
}

- (void)signedIn:(FIRUser *)user {
  NSLog(user.uid);
  FIRDatabaseReference *ref;
  ref = [FIRDatabase database].reference;
  FIRDatabaseReference *peopleRef = [ref child: [NSString stringWithFormat:@"people/%@", user.uid]];
  [peopleRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *peopleSnapshot) {
    if (peopleSnapshot.exists) {
      [FPAppState sharedInstance].currentUser = [[FPUser alloc] initWithSnapshot:peopleSnapshot];
    } else {
      NSDictionary *person = @{
                               @"full_name" : user.displayName ? user.displayName : @"",
                               @"profile_picture" : user.photoURL ? [user.photoURL absoluteString] : @"",
                               @"_search_index" : @{
                                   @"full_name": user.displayName ? user.displayName.lowercaseString : @"",
                                   @"reversed_full_name": [[self reverseArray:[user.displayName componentsSeparatedByString:@" "]] componentsJoinedByString:@" "]
                                   }
                               };
      [peopleRef setValue:person];
      [FPAppState sharedInstance].currentUser = [[FPUser alloc] initWithDictionary:person];
      [FPAppState sharedInstance].currentUser.userID = user.uid;
    }
    [self performSegueWithIdentifier:@"SignInToFP" sender:nil];
  }];
}

- (NSArray *)reverseArray:(NSArray *)array {
  NSMutableArray *rarray = [NSMutableArray arrayWithCapacity:[array count]];
  NSEnumerator *enumerator = [array reverseObjectEnumerator];
  for (id element in enumerator) {
    [rarray addObject:element];
  }
  return rarray;
}

@end
