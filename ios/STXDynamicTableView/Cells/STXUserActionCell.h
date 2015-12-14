//
//  STXUserActionCell.h
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 10/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

@import UIKit;

@class STXUserActionCell;

@protocol STXUserActionDelegate <NSObject>

- (void)userWillComment:(STXUserActionCell *)userActionCell;
- (void)userWillShare:(STXUserActionCell *)userActionCell;

- (void)userDidLike:(STXUserActionCell *)userActionCell;
- (void)userDidUnlike:(STXUserActionCell *)userActionCell;

@end

@interface STXUserActionCell : UITableViewCell

@property (weak, nonatomic) id <STXUserActionDelegate> delegate;

@property (copy, nonatomic) id <STXPostItem> postItem;
@property (copy, nonatomic) NSIndexPath *indexPath;

@end
