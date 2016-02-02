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

#define PHOTO_CELL_ROW 0

@interface FPPhotoTimelineViewController () <STXFeedPhotoCellDelegate, STXLikesCellDelegate,
    STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) STXFeedTableViewDataSource *tableViewDataSource;
@property (strong, nonatomic) STXFeedTableViewDelegate *tableViewDelegate;

@end

@implementation FPPhotoTimelineViewController
@synthesize ref;
@synthesize postsRef;

- (void)viewDidLoad {
  [super viewDidLoad];

  ref = [[Firebase alloc] initWithUrl:[FIRContext sharedInstance].serviceInfo.databaseURL];
  postsRef = [ref childByAppendingPath:@"posts"];

  self.title = NSLocalizedString(@"Feed", nil);
    
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
  [postsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *postSnapshot) {
    [self loadPost:postSnapshot];
  }];

  [postsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *postSnapshot) {
     FPPost *post = [[FPPost alloc] initWithSnapshot:postSnapshot];
     [self.tableViewDataSource.posts removeObject:post];
     //[self.tableView deleteSections:[NSIndexSet
     // indexSetWithIndex:[self.tableViewDataSource.posts count]-1]
     // withRowAnimation:UITableViewRowAnimationNone];
     [self.tableView reloadData];
   }];


}

- (void)loadPost:(FDataSnapshot *)postSnapshot {
  FPPost *post = [[FPPost alloc] initWithSnapshot:postSnapshot];

  for (NSString *commentId in postSnapshot.value[@"comments"]) {
    [[ref childByAppendingPath:[@"comments/" stringByAppendingString:commentId]]
     observeEventType:FEventTypeValue
     withBlock:^(FDataSnapshot *commentSnapshot) {
       FPComment *comment = [[FPComment alloc] initWithSnapshot:commentSnapshot];
       NSString *fromUser = commentSnapshot.value[@"from"];
       if (![[FPAppState sharedInstance].users objectForKey:fromUser]) {
         [[ref childByAppendingPath:[@"people/" stringByAppendingString:fromUser]]
          observeEventType:FEventTypeValue
          withBlock:^(FDataSnapshot *peopleSnapshot) {
            [FPAppState sharedInstance].users[fromUser] = [[FPUser alloc]
                                                           initWithSnapshot:peopleSnapshot];
            [post addComment:comment];
            [self.tableView reloadData];
          }];
       } else {
         [post addComment:comment];
         [self.tableView reloadData];
       }
     }];
  }

  NSString *authorId = postSnapshot.value[@"user"];
  if (![[FPAppState sharedInstance].users objectForKey:authorId]) {
    [[ref childByAppendingPath:[@"people/" stringByAppendingString:authorId]]
     observeEventType:FEventTypeValue
     withBlock:^(FDataSnapshot *peopleSnapshot) {
       [FPAppState sharedInstance].users[authorId] = [[FPUser alloc]
                                                      initWithSnapshot:peopleSnapshot];
       [self.tableViewDataSource.posts addObject:post];
       [self.tableView insertSections:[NSIndexSet
                                       indexSetWithIndex:[self.tableViewDataSource.posts count]-1]
                     withRowAnimation:UITableViewRowAnimationNone];
     }];
  } else {
    [self.tableViewDataSource.posts addObject:post];
    [self.tableView insertSections:[NSIndexSet
                                    indexSetWithIndex:[self.tableViewDataSource.posts count]-1]
                  withRowAnimation:UITableViewRowAnimationNone];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [ref removeAllObservers];
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

#pragma mark - Feed

//- (void)loadFeed {
//    NSString *feedPath = [[NSBundle mainBundle] pathForResource:@"instagram_media_popular"
//          ofType:@"json"];
//    
//    NSError *error;
//    NSData *jsonData = [NSData dataWithContentsOfFile:feedPath options:NSDataReadingMappedIfSafe error:&error];
//    if (jsonData) {
//        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
//        if (error) {
//            UALog(@"%@", error);
//        }
//        
//        NSDictionary *instagramPopularMediaDictionary = jsonObject;
//        if (instagramPopularMediaDictionary) {
//            NSArray *mediaDataArray = [instagramPopularMediaDictionary valueForKey:@"data"];
//            
//            NSMutableArray *posts = [NSMutableArray array];
//            for (NSDictionary *mediaDictionary in mediaDataArray) {
//                STXPost *post = [[STXPost alloc] initWithDictionary:mediaDictionary];
//                [posts addObject:post];
//            }
//            
//            self.tableViewDataSource.posts = [posts copy];
//            
//            [self.tableView reloadData];
//            
//        } else {
//            if (error) {
//                UALog(@"%@", error);
//            }
//        }
//    } else {
//        if (error) {
//            UALog(@"%@", error);
//        }
//    }
//    
//}

#pragma mark - User Action Cell

- (void)userDidLike:(STXUserActionCell *)userActionCell {
  FPPost *postItem = userActionCell.postItem;
  // user_has_liked ???
  //++postItem.totalLikes;
//  [[ref childByAppendingPath:[[@"posts/" stringByAppendingString:[postItem postID]]
//         stringByAppendingString:@"/like_count"]] runTransactionBlock:^FTransactionResult
//            *(FMutableData *currentData) {
//    NSNumber *value = currentData.value;
//    if (currentData.value == [NSNull null]) {
//      value = 0;
//    }
//    [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
//    return [FTransactionResult successWithValue:currentData];
//  }];
  
  [[postsRef childByAppendingPath:[NSString stringWithFormat:@"%@/likes/%@", [postItem postID],
                                   [FPAppState sharedInstance].currentUser.userID]]
       setValue:[NSNumber numberWithBool:YES] withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      NSLog(@"error in syncing like");
    } else {
      postItem.liked = YES;
      [self.tableView reloadRowsAtIndexPaths:@[userActionCell.indexPath]
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }];
}

- (void)userDidUnlike:(STXUserActionCell *)userActionCell {
  FPPost *postItem = userActionCell.postItem;
  // user_has_liked ???
  //--postItem.totalLikes;
//  [[ref childByAppendingPath:[[@"posts/" stringByAppendingString:[postItem postID]]
//      stringByAppendingString:@"/like_count"]]
//      runTransactionBlock:^FTransactionResult *(FMutableData *currentData) {
//    NSNumber *value = currentData.value;
//    if (currentData.value == [NSNull null] || currentData.value == 0) {
//      value = 0;
//    } else {
//      [currentData setValue:[NSNumber numberWithInt:([value intValue] - 1)]];
//    }
//    return [FTransactionResult successWithValue:currentData];
//  }];
  [[postsRef childByAppendingPath:[NSString stringWithFormat:@"%@/likes/%@", [postItem postID],
                                   [FPAppState sharedInstance].currentUser.userID]]
       removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error) {
      NSLog(@"error in syncing unlike");
    } else {
      postItem.liked = NO;
      [self.tableView reloadRowsAtIndexPaths:@[userActionCell.indexPath]
                            withRowAnimation:UITableViewRowAnimationNone];
    }
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
    [self performSegueWithIdentifier:@"asd" sender:poster];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // Get reference to the destination view controller
  UINavigationController *navController = [segue destinationViewController];

  // Make sure your segue name in storyboard is the same as this line
  if ([[segue identifier] isEqualToString:@"asd"])
  {
    FPAccountViewController *accountViewController =
        (FPAccountViewController *)([navController viewControllers][0]);

    // Pass any objects to the view controller here, like...
    [accountViewController setUser:sender];
  } else if ([[segue identifier] isEqualToString:@"comment"]) {
    FPCommentViewController *commentViewController =
        (FPCommentViewController *)([navController viewControllers][0]);

    // Pass any objects to the view controller here, like...
    [commentViewController setPost:sender];
  }
}

@end
