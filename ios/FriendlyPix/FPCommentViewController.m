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

#import "FPCommentViewController.h"
@import Firebase.AdMob;
#import "FPComment.h"

@implementation FPCommentViewController
NSMutableArray *comments;
- (void)viewDidLoad {
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
  comments = [self.post mutableComments];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *CellIdentifier = @"Cell";

  STXCommentCell *cell = (STXCommentCell *) [tableView
                                             dequeueReusableCellWithIdentifier:CellIdentifier];
  id<STXCommentItem> comment = comments[indexPath.row];
  if (cell == nil) {
    cell = [[STXCommentCell alloc] initWithStyle:STXCommentCellStyleSingleComment
                                         comment:comment reuseIdentifier:CellIdentifier];
  } else {
    [cell setComment:comment];
  }
  cell.delegate = self;
  [cell setNeedsUpdateConstraints];
  [cell updateConstraintsIfNeeded];

  return cell;
}
- (IBAction)didSendComment:(id)sender {
  [self textFieldShouldReturn:_commentField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSDictionary *data = @{ @"created_time": @"123",
                          @"from": [FPAppState sharedInstance].currentUser.userID,
                          @"text": textField.text
                          };
  // Push data to Firebase Database
  Firebase *ref;
  ref = [[Firebase alloc] initWithUrl:[FIRContext sharedInstance].serviceInfo.databaseURL];
  Firebase *comment = [[ref childByAppendingPath:@"comments"] childByAutoId];
  [comment setValue:data];
  NSString *commentId = comment.key;
  [[ref childByAppendingPath: [NSString stringWithFormat:@"posts/%@/comments/%@",
                               self.post.postID, commentId]] setValue:[NSNumber numberWithBool:YES]
                               withCompletionBlock:^(NSError *error, Firebase *ref) {
    if (error==nil) {
      [comments addObject:[[FPComment alloc] initWithDictionary:data]];
      [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath
                                                indexPathForRow:[comments count]-1 inSection:0]]
                            withRowAnimation:UITableViewRowAnimationNone];
    } else {
      NSLog(@"comment push error");
    }
  }];
  textField.text = @"";
  return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [comments count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (void)dismissPresentingViewController {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
  return self.footerView;
}

@end
