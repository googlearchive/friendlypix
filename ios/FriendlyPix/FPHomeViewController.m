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

@implementation FPHomeViewController

- (void)loadFeed {

  // Make sure the home feed is updated with followed users's new posts.
  // Only after the feed creation is complete, start fetching the posts.
  [self updateHomeFeeds];
}

-(void)getHomeFeedPosts {
  FIRDatabaseQuery *homeFeedQuery = [[super.ref child:@"feed"] child:[FPAppState sharedInstance].currentUser.userID].queryOrderedByKey;
  [homeFeedQuery observeEventType:FIRDataEventTypeChildAdded
                        withBlock:^(FIRDataSnapshot *feedSnapshot) {
     [[super.ref child:[@"posts/" stringByAppendingString:feedSnapshot.key]]
      observeEventType:FIRDataEventTypeValue
      withBlock:^(FIRDataSnapshot *postSnapshot) {
        [super loadPost:postSnapshot];
      }];
   }];
}

/**
 * Keeps the home feed populated with latest followed users' posts live.
 */
- (void)startHomeFeedLiveUpdaters {
  // Make sure we listen on each followed people's posts.
  FIRDatabaseReference *followingRef = [[[super.ref child:@"people"] child:[FPAppState sharedInstance].currentUser.userID] child:@"following"];
  [followingRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull followingSnapshot) {
    // Start listening the followed user's posts to populate the home feed.
    NSString *followedUid = followingSnapshot.key;
    FIRDatabaseQuery *followedUserPostsRef = [[[super.ref child:@"people"] child:followedUid] child:@"posts"];
    if (followingSnapshot.exists && [followingSnapshot.value isKindOfClass:[NSString class]]) {
      followedUserPostsRef = [followedUserPostsRef.queryOrderedByKey queryStartingAtValue:followingSnapshot.value];
    }
    [followedUserPostsRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull postSnapshot) {
      if (postSnapshot.key != followingSnapshot.key) {
        NSDictionary *updates = @{
                                  [NSString stringWithFormat:@"/feed/%@/%@", [FPAppState sharedInstance].currentUser.userID, postSnapshot.key]: @YES,
                                  [NSString stringWithFormat:@"/people/%@/following/%@", [FPAppState sharedInstance].currentUser.userID, followedUid]: postSnapshot.key
                                  };
        [super.ref updateChildValues:updates];
      }
    }];
  }];

  // Stop listening to users we unfollow.
  [followingRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
    // Stop listening the followed user's posts to populate the home feed.
    NSString *followedUserId = snapshot.key;
    [[[[super.ref child:@"people"] child:followedUserId] child:@"posts"] removeAllObservers];
  }];
}

/**
 * Updates the home feed with new followed users' posts and returns a promise once that's done.
 */
- (void)updateHomeFeeds {
  // Make sure we listen on each followed people's posts.
  FIRDatabaseReference *followingRef = [[[super.ref child:@"people"] child:[FPAppState sharedInstance].currentUser.userID] child:@"following"];
  [followingRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull followingSnapshot) {
    // Start listening the followed user's posts to populate the home feed.
    NSDictionary *following = followingSnapshot.value;
    if (!following  || [following isEqual:[NSNull null]]) {
      return;
    }

    __block FIRDatabaseQuery *followedUserPostsRef;
    [following enumerateKeysAndObjectsUsingBlock:^(NSString* followedUid, id lastSyncedPostId, BOOL* stop) {
      followedUserPostsRef = [[[super.ref child:@"people"] child:followedUid] child:@"posts"];
      if ([lastSyncedPostId isKindOfClass:[NSString class]]) {
        followedUserPostsRef = [followedUserPostsRef.queryOrderedByKey queryStartingAtValue:lastSyncedPostId];
      }
      [followedUserPostsRef observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull postSnapshot) {
        if (!postSnapshot.value) {
          return;
        }
        NSDictionary *postArray = postSnapshot.value;
        NSMutableDictionary *updates = [[NSMutableDictionary alloc] init];
        for (NSString *postId in postArray.allKeys) {
          if (![postId isEqualToString:lastSyncedPostId]) {
            updates[[NSString stringWithFormat:@"/feed/%@/%@", [FPAppState sharedInstance].currentUser.userID, postId]] = @YES;
            updates[[NSString stringWithFormat:@"/people/%@/following/%@", [FPAppState sharedInstance].currentUser.userID, followedUid]] = postId;
          }
        }
        [super.ref updateChildValues:updates];

        // Add new posts from followers live.
        [self startHomeFeedLiveUpdaters];
        // Get home feed posts
        [self getHomeFeedPosts];
      }];
    }];
  }];
}

- (IBAction)inviteTapped:(id)sender {
  id<FIRInviteBuilder> inviteDialog = [FIRInvites inviteDialog];
  [inviteDialog setInviteDelegate:self];

  // NOTE: You must have the App Store ID set in your developer console project
  // in order for invitations to successfully be sent.
  NSString *message =
  [NSString stringWithFormat:@"Try this out!\n -%@",
   [FIRAuth auth].currentUser.displayName];

  // A message hint for the dialog. Note this manifests differently depending on the
  // received invitation type. For example, in an email invite this appears as the subject.
  [inviteDialog setMessage:message];

  // Title for the dialog, this is what the user sees before sending the invites.
  [inviteDialog setTitle:@"FriendlyPix"];
  [inviteDialog setDeepLink:@"app_url"];
  [inviteDialog setCallToActionText:@"Install!"];
  [inviteDialog setCustomImage:@"https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png"];
  [inviteDialog open];
}

- (void)inviteFinishedWithInvitations:(NSArray *)invitationIds error:(NSError *)error {
  NSString *message =
  error ? error.localizedDescription
  : [NSString stringWithFormat:@"%lu invites sent", (unsigned long)invitationIds.count];
  [[[UIAlertView alloc] initWithTitle:@"Done"
                              message:message
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
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
