//
//  STXFeedTableViewDelegate.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 27/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXFeedTableViewDelegate.h"
#import "STXFeedTableViewDataSource.h"

#import "STXFeedPhotoCell.h"
#import "STXLikesCell.h"
#import "STXCaptionCell.h"
#import "STXCommentCell.h"
#import "STXUserActionCell.h"

#import "STXPostItem.h"

#define PHOTO_CELL_ROW 0
#define LIKES_CELL_ROW 1
#define CAPTION_CELL_ROW 2

#define MAX_NUMBER_OF_COMMENTS 5

static CGFloat const PhotoCellRowHeight = 344;
static CGFloat const UserActionCellHeight = 44;

@interface STXFeedTableViewDelegate () <UIScrollViewDelegate>

@property (weak, nonatomic) id <STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate> controller;

@end

@implementation STXFeedTableViewDelegate

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller
{
    self = [super init];
    if (self) {
        _controller = controller;
    }
    
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == PHOTO_CELL_ROW) {
        return PhotoCellRowHeight;
    }
    
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == PHOTO_CELL_ROW) {
        return PhotoCellRowHeight;
    }
    
    return UserActionCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Row Updates

- (void)reloadAtIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    self.insertingRow = YES;
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    id<UIScrollViewDelegate> scrollViewDelegate = (id<UIScrollViewDelegate>)self.controller;
    if ([scrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [scrollViewDelegate scrollViewDidScroll:scrollView];
    }
}

@end
