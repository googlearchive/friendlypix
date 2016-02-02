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
@property (nonatomic, strong) UIView *headerView;
@property unsigned long postCount;
@property unsigned long feedCount;
@property NSDictionary *followers;
@property unsigned long followingCount;
@end

@implementation FPAccountViewController
@synthesize headerView;
@synthesize user;
@synthesize postCount;
@synthesize feedCount;
@synthesize followers;
@synthesize followingCount;

#pragma mark - Initialization

- (id)initWithUser:(FPUser *)aUser {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.user = aUser;

    if (!aUser) {
      [NSException raise:NSInvalidArgumentException
                  format:@"FPAccountViewController init exception: user cannot be nil"];
    }

  }
  return self;
}

- (void)loadFeed {
  [[super.ref childByAppendingPath:[@"users/" stringByAppendingString:user.userID]]
   observeEventType:FEventTypeValue
   withBlock:^(FDataSnapshot *userSnapshot) {
     NSArray *posts = [userSnapshot childSnapshotForPath:@"posts"].value;
     postCount = posts.count;
     feedCount = [[userSnapshot childSnapshotForPath:@"feed"] childrenCount];
     followers = userSnapshot.value[@"followers"];
     followingCount = [[userSnapshot childSnapshotForPath:@"following"] childrenCount];
     [self feedDidLoad];
     for (NSString *postId in posts) {

       [[super.ref childByAppendingPath:[@"posts/" stringByAppendingString:postId]]
        observeEventType:FEventTypeValue
        withBlock:^(FDataSnapshot *postSnapshot) {
          [super loadPost:postSnapshot];
        }];
     }
   }];
}



#pragma mark - UIViewController

- (void)feedDidLoad {

  //    if (!self.user) {
  //        self.user = [PFUser currentUser];
  //        [[PFUser currentUser] fetchIfNeeded];
  //    }

  self.navigationItem.titleView = [[UIImageView alloc]
                                   initWithImage:[UIImage imageNamed:@"LogoNavigationBar.png"]];

  if (self.navigationController.viewControllers[0] == self) {
    UIBarButtonItem *dismissLeftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(dismissPresentingViewController)];

    self.navigationItem.leftBarButtonItem = dismissLeftBarButtonItem;
  }
  else {
    self.navigationItem.leftBarButtonItem = nil;
  }


  self.headerView = [[UIView alloc] initWithFrame:
                     CGRectMake( 0.0f, 0.0f, self.tableView.bounds.size.width, 222.0f)];
  [self.headerView setBackgroundColor:[UIColor clearColor]];

  UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
  [texturedBackgroundView setBackgroundColor:[UIColor blackColor]];
  self.tableView.backgroundView = texturedBackgroundView;

  UIView *profilePictureBackgroundView = [[UIView alloc] initWithFrame:
                                          CGRectMake( 94.0f, 38.0f, 132.0f, 132.0f)];
  [profilePictureBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
  profilePictureBackgroundView.alpha = 0.0f;
  CALayer *layer = [profilePictureBackgroundView layer];
  layer.cornerRadius = 66.0f;
  layer.masksToBounds = YES;
  [self.headerView addSubview:profilePictureBackgroundView];

  UIImageView *profilePictureImageView = [[UIImageView alloc] initWithFrame:
                                          CGRectMake( 94.0f, 38.0f, 132.0f, 132.0f)];
  [self.headerView addSubview:profilePictureImageView];
  [profilePictureImageView setContentMode:UIViewContentModeScaleAspectFill];
  layer = [profilePictureImageView layer];
  layer.cornerRadius = 66.0f;
  layer.masksToBounds = YES;
  profilePictureImageView.alpha = 0.0f;
  [profilePictureImageView setCircleImageWithURL:[user profilePictureURL]
                                placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"]
                                     borderWidth:2];

  UIImageView *photoCountIconImageView = [[UIImageView alloc] initWithImage:nil];
  [photoCountIconImageView setImage:[UIImage imageNamed:@"IconPics.png"]];
  [photoCountIconImageView setFrame:CGRectMake( 26.0f, 50.0f, 45.0f, 37.0f)];
  [self.headerView addSubview:photoCountIconImageView];

  UILabel *photoCountLabel = [[UILabel alloc] initWithFrame:
                              CGRectMake( 0.0f, 94.0f, 92.0f, 22.0f)];
  [photoCountLabel setTextAlignment:NSTextAlignmentCenter];
  [photoCountLabel setBackgroundColor:[UIColor clearColor]];
  [photoCountLabel setTextColor:[UIColor whiteColor]];
  [photoCountLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
  [photoCountLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
  [photoCountLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
  [self.headerView addSubview:photoCountLabel];

  UIImageView *followersIconImageView = [[UIImageView alloc] initWithImage:nil];
  [followersIconImageView setImage:[UIImage imageNamed:@"IconFollowers.png"]];
  [followersIconImageView setFrame:CGRectMake( 247.0f, 50.0f, 52.0f, 37.0f)];
  [self.headerView addSubview:followersIconImageView];

  UILabel *followerCountLabel = [[UILabel alloc] initWithFrame:
                                 CGRectMake( 226.0f, 94.0f,
                                            self.headerView.bounds.size.width - 226.0f, 16.0f)];
  [followerCountLabel setTextAlignment:NSTextAlignmentCenter];
  [followerCountLabel setBackgroundColor:[UIColor clearColor]];
  [followerCountLabel setTextColor:[UIColor whiteColor]];
  [followerCountLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
  [followerCountLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
  [followerCountLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
  [self.headerView addSubview:followerCountLabel];

  UILabel *followingCountLabel = [[UILabel alloc] initWithFrame:
                                  CGRectMake( 226.0f, 110.0f,
                                             self.headerView.bounds.size.width - 226.0f, 16.0f)];
  [followingCountLabel setTextAlignment:NSTextAlignmentCenter];
  [followingCountLabel setBackgroundColor:[UIColor clearColor]];
  [followingCountLabel setTextColor:[UIColor whiteColor]];
  [followingCountLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
  [followingCountLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
  [followingCountLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
  [self.headerView addSubview:followingCountLabel];

  UILabel *userDisplayNameLabel = [[UILabel alloc] initWithFrame:
                                   CGRectMake(0, 176.0f, self.headerView.bounds.size.width, 22.0f)];
  [userDisplayNameLabel setTextAlignment:NSTextAlignmentCenter];
  [userDisplayNameLabel setBackgroundColor:[UIColor clearColor]];
  [userDisplayNameLabel setTextColor:[UIColor whiteColor]];
  [userDisplayNameLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
  [userDisplayNameLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
  [userDisplayNameLabel setText: [user username]];
  [userDisplayNameLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
  [self.headerView addSubview:userDisplayNameLabel];

  [photoCountLabel setText:[NSString
                            stringWithFormat:@"%lu photo%@", feedCount, feedCount==1?@"":@"s"]];

  unsigned long followersCount = [followers count];
  [followerCountLabel setText:[NSString
                               stringWithFormat:@"%lu follower%@",
                               followersCount, followersCount==1?@"":@"s"]];

  [followingCountLabel setText:[NSString
                                stringWithFormat:@"%lu following",
                                followingCount]];

  if (![self.user.userID isEqualToString:[FPAppState sharedInstance].currentUser.userID]) {
    UIActivityIndicatorView *loadingActivityIndicatorView =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];

    // check if the currentUser is following this user
    if ([followers objectForKey:[FPAppState sharedInstance].currentUser.userID]) {
      [self configureUnfollowButton];
    } else {
      [self configureFollowButton];
    }
  }

  self.tableView.tableHeaderView = headerView;
}

- (void)dismissPresentingViewController {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PFQueryTableViewController

- (void)objectsDidLoad:(NSError *)error {
  //    [super objectsDidLoad:error];

  self.tableView.tableHeaderView = headerView;
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
      [NSString stringWithFormat:@"users/%@/followers/%@", user.userID,
          [FPAppState sharedInstance].currentUser.userID]] setValue:[NSNumber numberWithBool:YES]];
  [[super.ref childByAppendingPath:
      [NSString stringWithFormat:@"users/%@/following/%@",
          [FPAppState sharedInstance].currentUser.userID, user.userID]]
              setValue:[NSNumber numberWithBool:YES]];

  Firebase *myFeed = [super.ref childByAppendingPath:
      [NSString stringWithFormat:@"users/%@/feed", [FPAppState sharedInstance].currentUser.userID]];
  [[super.ref childByAppendingPath:
      [NSString stringWithFormat:@"users/%@/posts", user.userID]]
          observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
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
          user.userID, [FPAppState sharedInstance].currentUser.userID]] removeValue];
  [[super.ref childByAppendingPath:
      [NSString stringWithFormat:@"users/%@/following/%@",
          [FPAppState sharedInstance].currentUser.userID, user.userID]] removeValue];

  [self configureFollowButton];

}

- (void)backButtonAction:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureFollowButton {
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Follow" style:UIBarButtonItemStylePlain
                                            target:self action:@selector(followButtonAction:)];
  //    [[PAPCache sharedCache] setFollowStatus:NO user:self.user];
}

- (void)configureUnfollowButton {
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithTitle:@"Unfollow"
                                            style:UIBarButtonItemStylePlain
                                            target:self action:@selector(unfollowButtonAction:)];
  //    [[PAPCache sharedCache] setFollowStatus:YES user:self.user];
}

@end