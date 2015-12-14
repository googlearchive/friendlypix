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

#import "AppDelegate.h"

// [START usermanagement_import]
#import "FirebaseAuth/FIRAuth.h"
#import "FirebaseApp/FIRFirebaseApp.h"
#import "FirebaseApp/FIRFirebaseOptions.h"
#import "FirebaseAuthProviderGoogle/FIRGoogleSignInAuthProvider.h"
// [END usermanagement_import]

/*! @var kWidgetURL
 @brief The GITkit widget URL.
 */
static NSString *const kWidgetURL = @"https://gitkitmobile.appspot.com/gitkit.jsp";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//  NSNotificationCenter.defaultCenter().addObserver(self, selector: "connectToFriendlyPing",
//                                                   name: FPConstants.NotificationKeys.SignedIn, object: nil)
  [self configureFIRContext];
  [GINInvite applicationDidFinishLaunchingWithOptions:launchOptions];
  [self configureSignIn];
  [self configureGCMService];

  return YES;
}

- (void)configureFIRContext {
  // [START firebase_configure]
  // Use Firebase library to configure APIs
  NSError *configureError;
  BOOL status = [[FIRContext sharedInstance] configure:&configureError];
  NSAssert(status, @"Error configuring Firebase services: %@", configureError);
  // [END firebase_configure]
}

- (void) configureSignIn {
  // [START usermanagement_initialize]
  // Configure the default Firebase application
  FIRGoogleSignInAuthProvider *googleSignIn =
  [[FIRGoogleSignInAuthProvider alloc] initWithClientId:
   [FIRContext sharedInstance].serviceInfo.clientID];

  FIRFirebaseOptions *firebaseOptions = [[FIRFirebaseOptions alloc] init];
  firebaseOptions.APIKey = [FIRContext sharedInstance].serviceInfo.apiKey;
  firebaseOptions.authWidgetURL = [NSURL URLWithString:kWidgetURL];
  firebaseOptions.signInProviders = @[ googleSignIn ];
  [FIRFirebaseApp initializedAppWithAppId:[FIRContext sharedInstance].serviceInfo.googleAppID
                                  options:firebaseOptions];
  // [END usermanagement_initialize]
}

- (void) configureGCMService {
  NSString *senderID = [FIRContext sharedInstance].gcmSenderID;
//  FPAppState.sharedInstance.senderID = senderID
//  FPAppState.sharedInstance.serverAddress = "\(senderID)@gcm.googleapis.com"
  // [START start_gcm_service]
  GCMConfig *gcmConfig = [GCMConfig defaultConfig];
  gcmConfig.receiverDelegate = self;
  [[GCMService sharedInstance] startWithConfig:gcmConfig];
  // [END start_gcm_service]
}

- (void) registerForRemoteNotifications:(UIApplication *)application {
  // Register for remote notifications
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
    // iOS 7.1 or earlier
    UIRemoteNotificationType allNotificationTypes =
    (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeBadge);
    [application registerForRemoteNotificationTypes:allNotificationTypes];
  } else {
    // iOS 8 or later
    // [END_EXCLUDE]
    UIUserNotificationType allNotificationTypes =
    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
  }
  // [END register_for_remote_notifications]
//  __weak typeof(self) weakSelf = self;
//  // Handler for registration token request
//  _registrationHandler = ^(NSString *registrationToken, NSError *error) {
//    if (registrationToken != nil) {
//      weakSelf.registrationToken = registrationToken;
//      NSLog(@"Registration Token: %@", registrationToken);
//      [weakSelf subscribeToTopic];
//      NSDictionary *userInfo = @{ @"registrationToken" : registrationToken };
//      [[NSNotificationCenter defaultCenter] postNotificationName:weakSelf.registrationKey
//                                                          object:nil
//                                                        userInfo:userInfo];
//    } else {
//      NSLog(@"Registration to GCM failed with error: %@", error.localizedDescription);
//      NSDictionary *userInfo = @{ @"error" : error.localizedDescription };
//      [[NSNotificationCenter defaultCenter] postNotificationName:weakSelf.registrationKey
//                                                          object:nil
//                                                        userInfo:userInfo];
//    }
//  };
}



- (BOOL)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
            options:(nonnull NSDictionary<NSString *, id> *)options {
  if ([FIRFirebaseApp handleOpenURL:url
                  sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]]) {
    return YES;
  }

  return NO;
}

@end
