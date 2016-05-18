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
#import "FPAppState.h"

@interface FPAccountViewController()
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followerCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followingCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureImageView;
@property unsigned long postCount;
@property NSDictionary *followers;
@property unsigned long followingCount;
@end

@implementation FPAccountViewController

- (void)loadFeed {
  [[[super.ref child:@"people"] child:_user.userID]
   observeSingleEventOfType:FIRDataEventTypeValue
   withBlock:^(FIRDataSnapshot *userSnapshot) {
     NSArray *posts = [userSnapshot childSnapshotForPath:@"posts"].value;
     self.postCount = posts.count;
     self.followingCount = [[userSnapshot childSnapshotForPath:@"following"] childrenCount];
     [self feedDidLoad];
     for (NSString *postId in posts) {
       [[super.ref child:[@"posts/" stringByAppendingString:postId]]
        observeEventType:FIRDataEventTypeValue
        withBlock:^(FIRDataSnapshot *postSnapshot) {
          [super loadPost:postSnapshot];
        }];
     }
   }];
  [[[super.ref child:@"followers"] child: _user.userID]
   observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
     self.followers = snapshot.value;
     unsigned long followersCount = [_followers count];
     [_followerCountLabel setText:[NSString
                                   stringWithFormat:@"%lu follower%@",
                                   followersCount, followersCount==1?@"":@"s"]];

   }];

  [_profilePictureImageView setCircleImageWithURL:_user.profilePictureURL placeholderImage:[UIImage imageNamed:@"PlaceholderPhoto"]];
}



#pragma mark - UIViewController

- (void)feedDidLoad {

  self.navigationItem.title = _user.username;

  [_photoCountLabel setText:[NSString
                             stringWithFormat:@"%lu post%@", _postCount, _postCount==1?@"":@"s"]];

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

  FIRDatabaseReference *myFeed = [super.ref child:
                                  [NSString stringWithFormat:@"feed/%@", [FPAppState sharedInstance].currentUser.userID]];
  [[super.ref child:
    [NSString stringWithFormat:@"people/%@/posts", _user.userID]]
   observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
     NSString *lastPostID = @YES;
     for (NSString *postId in [snapshot.value allKeys]) {
       [[myFeed child:postId] setValue:@YES];
       lastPostID = postId;
     }
     [super.ref updateChildValues:@{
                           [NSString stringWithFormat:@"followers/%@/%@", _user.userID,
                            [FPAppState sharedInstance].currentUser.userID]: lastPostID,
                           [NSString stringWithFormat:@"people/%@/following/%@",
                            [FPAppState sharedInstance].currentUser.userID, _user.userID]: @YES
                           }];

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

  FIRDatabaseReference *myFeed = [super.ref child:
                                  [NSString stringWithFormat:@"feed/%@", [FPAppState sharedInstance].currentUser.userID]];
  [[super.ref child:
    [NSString stringWithFormat:@"people/%@/posts", _user.userID]]
   observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
     for (NSString *postId in [snapshot.value allKeys]) {
       [[myFeed child:postId] removeValue];
     }
     [super.ref updateChildValues:@{
                           [NSString stringWithFormat:@"followers/%@/%@", _user.userID,
                            [FPAppState sharedInstance].currentUser.userID]: [NSNull null],
                           [NSString stringWithFormat:@"people/%@/following/%@",
                            [FPAppState sharedInstance].currentUser.userID, _user.userID]: [NSNull null]
                           }];
   }];
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