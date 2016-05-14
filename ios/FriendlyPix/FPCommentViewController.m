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
#import "FPComment.h"
#import "STXCommentCell.h"
#import "FPAppState.h"

@interface FPCommentViewController () <STXCommentCellDelegate>
@end

@implementation FPCommentViewController
NSMutableArray *comments;

- (void)viewDidLoad {
  comments = [self.post comments];
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
  NSDictionary *data = @{ @"timestamp": FIRServerValue.timestamp,
                          @"author": [[FPAppState sharedInstance].currentUser author],
                          @"text": textField.text
                          };
  // Push data to Firebase Database
  FIRDatabaseReference *ref;
  ref = [[FIRDatabase database] reference];
  FIRDatabaseReference *comment = [[ref child:[@"comments/" stringByAppendingString:self.post.postID]] childByAutoId];
  [comment setValue:data withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
    if (error==nil) {
      [ref observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        [comments addObject:[[FPComment alloc] initWithSnapshot:snapshot]];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath
                                                  indexPathForRow:[comments count]-1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationNone];
      }];
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
