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

@import UIKit;

#import "FPPhotoTimelineViewController.h"
#import "FPPost.h"
#import "FPUser.h"
#import "FPComment.h"
#import "FPAppState.h"
#import "FPAccountViewController.h"
#import "FPCommentViewController.h"
#import "STXDynamicTableView.h"

#define PHOTO_CELL_ROW 0

@interface FPPhotoTimelineViewController () <STXFeedPhotoCellDelegate, STXLikesCellDelegate,
    STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) STXFeedTableViewDataSource *tableViewDataSource;
@property (strong, nonatomic) STXFeedTableViewDelegate *tableViewDelegate;
@property (strong, nonatomic) NSMutableArray *posts;

@end

@implementation FPPhotoTimelineViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  _ref = [[FIRDatabase database] reference];
  _postsRef = [_ref child:@"posts"];
  _commentsRef = [_ref child:@"comments"];
  _likesRef = [_ref child:@"likes"];
  _posts = [[NSMutableArray alloc] init];

  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
  STXFeedTableViewDataSource *dataSource = [[STXFeedTableViewDataSource alloc]
                                            initWithController:self tableView:self.tableView];
  self.tableView.dataSource = dataSource;
  self.tableViewDataSource = dataSource;
    
  STXFeedTableViewDelegate *delegate = [[STXFeedTableViewDelegate alloc] initWithController:self];
  self.tableView.delegate = delegate;
  self.tableViewDelegate = delegate;
   
  self.activityIndicatorView = [self activityIndicatorViewOnView:self.view];
    
  [self loadFeed];
}

- (void)dealloc {
  // To prevent crash when popping this from navigation controller
  self.tableView.delegate = nil;
  self.tableView.dataSource = nil;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
    
  // This will be notified when the Dynamic Type user setting changes (from the system Settings app)
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(contentSizeCategoryChanged:)
                                               name:UIContentSizeCategoryDidChangeNotification
                                             object:nil];

  if ([self.tableViewDataSource.posts count] == 0) {
      [self.activityIndicatorView startAnimating];
  }
}

- (void)loadFeed {
  // Listen for new messages in the Firebase database
  [_postsRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *postSnapshot) {
    [self loadPost:postSnapshot];
  }];

  [_postsRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot *postSnapshot) {
     FPPost *post = [[FPPost alloc] initWithSnapshot:postSnapshot andComments:NULL];
     [_posts removeObject:post];
     self.tableViewDataSource.posts = [_posts copy];
     [self.tableView deleteSections:[NSIndexSet
      indexSetWithIndex:[self.tableViewDataSource.posts count]]
      withRowAnimation:UITableViewRowAnimationNone];
     [self.tableView reloadData];
   }];
}

- (void)loadPost:(FIRDataSnapshot *)postSnapshot {
  [[_commentsRef child:postSnapshot.key] observeEventType:FIRDataEventTypeValue
      withBlock:^(FIRDataSnapshot *commentsSnapshot) {
        NSMutableArray *commentsArray = [[NSMutableArray alloc]
            initWithCapacity:commentsSnapshot.childrenCount];
        FPComment *comment;
        for (FIRDataSnapshot *commentSnapshot in commentsSnapshot.children) {
          comment = [[FPComment alloc] initWithSnapshot:commentSnapshot];
          [commentsArray addObject:comment];
        }
        [[_likesRef child:postSnapshot.key] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
          FPPost *post = [[FPPost alloc] initWithSnapshot:postSnapshot andComments:commentsArray];
          NSDictionary *likes = snapshot.value;
          if (likes && ![likes isEqual:[NSNull null]]) {
            post.likes = likes;
          } else {
            post.likes = [[NSDictionary alloc] init];
          }
          [_posts addObject:post];
          self.tableViewDataSource.posts = [_posts copy];
          [self.tableView insertSections:[NSIndexSet indexSetWithIndex:[self.tableViewDataSource.posts count]-1]
                        withRowAnimation:UITableViewRowAnimationNone];
        }];
  }];
}

- (void)viewWillDisappear:(BOOL)animated {
  [_ref removeAllObservers];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)contentSizeCategoryChanged:(NSNotification *)notification {
    [self.tableView reloadData];
}

#pragma mark - User Action Cell

- (void)userDidLike:(STXUserActionCell *)userActionCell {
  FPPost *postItem = userActionCell.postItem;
  [[_ref child:[NSString stringWithFormat:@"likes/%@/%@", [postItem postID],
                                   [FPAppState sharedInstance].currentUser.userID]]
       setValue:FIRServerValue.timestamp withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
    if (error) {
      NSLog(@"error in syncing like");
      return;
    }
    postItem.liked = YES;
    [self.tableView reloadRowsAtIndexPaths:@[userActionCell.indexPath]
                            withRowAnimation:UITableViewRowAnimationNone];
       }];
}

- (void)userDidUnlike:(STXUserActionCell *)userActionCell {
  FPPost *postItem = userActionCell.postItem;
  [[_ref child:[NSString stringWithFormat:@"likes/%@/%@", [postItem postID],
                                   [FPAppState sharedInstance].currentUser.userID]]
       removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
    if (error) {
      NSLog(@"error in syncing unlike");
      return;
    }
    postItem.liked = NO;
    [self.tableView reloadRowsAtIndexPaths:@[userActionCell.indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
       }];
}

- (void)userWillComment:(STXUserActionCell *)userActionCell {
  id<STXPostItem> postItem = userActionCell.postItem;
  // Present comment view controller
  [self performSegueWithIdentifier:@"comment" sender:postItem];
}

- (void)userWillShare:(STXUserActionCell *)userActionCell {
  id<STXPostItem> postItem = userActionCell.postItem;
    
    NSIndexPath *photoCellIndexPath = [NSIndexPath
                                       indexPathForRow:PHOTO_CELL_ROW
                                       inSection:userActionCell.indexPath.section];
    STXFeedPhotoCell *photoCell = (STXFeedPhotoCell *)[self.tableView
                                                       cellForRowAtIndexPath:photoCellIndexPath];
    UIImage *photoImage = photoCell.photoImage;
    
    [self shareImage:photoImage text:postItem.captionText url:postItem.sharedURL];
}


- (void)feedCellWillShowPoster:(id <STXUserItem>)poster {
  if ([self isKindOfClass:[FPAccountViewController class]]) {
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ];
    anim.values = @[[NSValue
                  valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f)],
                  [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f)]];
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    [self.view.layer addAnimation:anim forKey:nil];
  } else {
    [self performSegueWithIdentifier:@"account" sender:poster];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"account"])  {
    FPAccountViewController *accountViewController = segue.destinationViewController;
    [accountViewController setUser:sender];
  } else if ([[segue identifier] isEqualToString:@"comment"]) {
    FPCommentViewController *commentViewController = segue.destinationViewController;
    [commentViewController setPost:sender];
  }
}

@end
