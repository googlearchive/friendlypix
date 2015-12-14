//
//  STXFeedTableViewDataSource.h
//  STXDynamicTableView
//
//  Created by Jesse Armand on 27/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

@import Foundation;
@import UIKit;

@protocol STXFeedPhotoCellDelegate;
@protocol STXLikesCellDelegate;
@protocol STXCaptionCellDelegate;
@protocol STXCommentCellDelegate;
@protocol STXUserActionDelegate;

@class STXLikesCell;
@class STXCaptionCell;
@class STXCommentCell;

@interface STXFeedTableViewDataSource : NSObject <UITableViewDataSource>

@property (copy, nonatomic) NSMutableArray *posts;

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller
                         tableView:(UITableView *)tableView;

- (STXLikesCell *)likesCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (STXCaptionCell *)captionCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (STXCommentCell *)commentCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;

@end
