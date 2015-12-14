//
//  STXFeedTableViewDelegate.h
//  STXDynamicTableView
//
//  Created by Jesse Armand on 27/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

@import Foundation;

@protocol STXFeedPhotoCellDelegate;
@protocol STXLikesCellDelegate;
@protocol STXCaptionCellDelegate;
@protocol STXCommentCellDelegate;
@protocol STXUserActionDelegate;

@interface STXFeedTableViewDelegate : NSObject <UITableViewDelegate>

@property (nonatomic) BOOL insertingRow;

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller;

- (void)reloadAtIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView;

@end
