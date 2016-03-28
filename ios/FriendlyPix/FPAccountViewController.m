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

#import "FPAccountViewController.h"
#import "UIImageView+Masking.h"

@interface FPAccountViewController()
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followerCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followingCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property unsigned long postCount;
@property unsigned long feedCount;
@property NSDictionary *followers;
@property unsigned long followingCount;
@end

@implementation FPAccountViewController

- (void)loadFeed {
  [[super.ref childByAppendingPath:[@"users/" stringByAppendingString:_user.userID]]
   observeEventType:FIRDataEventTypeValue
   withBlock:^(FIRDataSnapshot *userSnapshot) {
     NSArray *posts = [userSnapshot childSnapshotForPath:@"posts"].value;
     _postCount = posts.count;
     _feedCount = [[userSnapshot childSnapshotForPath:@"feed"] childrenCount];
     _followers = userSnapshot.value[@"followers"];
     _followingCount = [[userSnapshot childSnapshotForPath:@"following"] childrenCount];
     [self feedDidLoad];
     for (NSString *postId in posts) {

       [[super.ref childByAppendingPath:[@"posts/" stringByAppendingString:postId]]
        observeEventType:FIRDataEventTypeValue
        withBlock:^(FIRDataSnapshot *postSnapshot) {
          [super loadPost:postSnapshot];
        }];
     }
   }];
}



#pragma mark - UIViewController

- (void)feedDidLoad {

  self.navigationItem.title = _user.username;

  [_photoCountLabel setText:[NSString
                             stringWithFormat:@"%lu photo%@", _feedCount, _feedCount==1?@"":@"s"]];

  unsigned long followersCount = [_followers count];
  [_followerCountLabel setText:[NSString
                                stringWithFormat:@"%lu follower%@",
                                followersCount, followersCount==1?@"":@"s"]];

  [_followingCountLabel setText:[NSString
                                 stringWithFormat:@"%lu following",
                                 _followingCount]];

  if (![self.user.userID isEqualToString:[FPAppState sharedInstance].currentUser.userID]) {
    UIActivityIndicatorView *loadingActivityIndicatorView =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];

    // check if the currentUser is following this user
    if ([_followers objectForKey:[FPAppState sharedInstance].currentUser.userID]) {
      [self configureUnfollowButton];
    } else {
      [self configureFollowButton];
    }
  }
}

#pragma mark - ()

- (void)followButtonAction:(id)sender {
  UIActivityIndicatorView *loadingActivityIndicatorView =
  [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
   UIActivityIndicatorViewStyleWhite];
  [loadingActivityIndicatorView startAnimating];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithCustomView:loadingActivityIndicatorView];

  [[super.ref childByAppendingPath:
    [NSString stringWithFormat:@"users/%@/followers/%@", _user.userID,
     [FPAppState sharedInstance].currentUser.userID]] setValue:[NSNumber numberWithBool:YES]];
  [[super.ref childByAppendingPath:
    [NSString stringWithFormat:@"users/%@/following/%@",
     [FPAppState sharedInstance].currentUser.userID, _user.userID]]
   setValue:[NSNumber numberWithBool:YES]];

  FIRDatabaseReference *myFeed = [super.ref childByAppendingPath:
                      [NSString stringWithFormat:@"users/%@/feed", [FPAppState sharedInstance].currentUser.userID]];
  [[super.ref childByAppendingPath:
    [NSString stringWithFormat:@"users/%@/posts", _user.userID]]
   observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
     for (NSString *postId in [snapshot.value allKeys]) {
       [[myFeed childByAppendingPath:postId] setValue:[NSNumber numberWithBool:YES]];
     }
   }];

  [self configureUnfollowButton];

}

- (void)unfollowButtonAction:(id)sender {
  UIActivityIndicatorView *loadingActivityIndicatorView =
  [[UIActivityIndicatorView alloc]
   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  [loadingActivityIndicatorView startAnimating];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithCustomView:loadingActivityIndicatorView];

  [[super.ref childByAppendingPath:
    [NSString stringWithFormat:@"users/%@/followers/%@",
     _user.userID, [FPAppState sharedInstance].currentUser.userID]] removeValue];
  [[super.ref childByAppendingPath:
    [NSString stringWithFormat:@"users/%@/following/%@",
     [FPAppState sharedInstance].currentUser.userID, _user.userID]] removeValue];

  [self configureFollowButton];
}

- (void)backButtonAction:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureFollowButton {
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Follow" style:UIBarButtonItemStylePlain
                                            target:self action:@selector(followButtonAction:)];
}

- (void)configureUnfollowButton {
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Unfollow"
                                            style:UIBarButtonItemStylePlain
                                            target:self action:@selector(unfollowButtonAction:)];
}

@end