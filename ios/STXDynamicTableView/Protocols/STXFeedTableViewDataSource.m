//
//  STXFeedTableViewDataSource.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 27/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXFeedTableViewDataSource.h"

#import "STXFeedPhotoCell.h"
#import "STXLikesCell.h"
#import "STXCaptionCell.h"
#import "STXCommentCell.h"
#import "STXUserActionCell.h"

#define PHOTO_CELL_ROW 0
#define LIKES_CELL_ROW 1
#define CAPTION_CELL_ROW 2

#define NUMBER_OF_STATIC_ROWS 4
#define MAX_NUMBER_OF_COMMENTS 5

@interface STXFeedTableViewDataSource () 

@property (weak, nonatomic) id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate> controller;

@end

@implementation STXFeedTableViewDataSource

- (instancetype)initWithController:(id<STXFeedPhotoCellDelegate, STXLikesCellDelegate, STXCaptionCellDelegate, STXCommentCellDelegate, STXUserActionDelegate>)controller
                         tableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
      _posts = [[NSMutableArray alloc] init];
        _controller = controller;
        
        NSString *feedPhotoCellIdentifier = NSStringFromClass([STXFeedPhotoCell class]);
        UINib *feedPhotoCellNib = [UINib nibWithNibName:feedPhotoCellIdentifier bundle:nil];
        [tableView registerNib:feedPhotoCellNib forCellReuseIdentifier:feedPhotoCellIdentifier];
        
        NSString *userActionCellIdentifier = NSStringFromClass([STXUserActionCell class]);
        UINib *userActionCellNib = [UINib nibWithNibName:userActionCellIdentifier bundle:nil];
        [tableView registerNib:userActionCellNib forCellReuseIdentifier:userActionCellIdentifier];
   }
    
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.posts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<STXPostItem> postItem = self.posts[section];
    NSInteger commentsCount = MIN(MAX_NUMBER_OF_COMMENTS, [postItem totalComments]);
    return NUMBER_OF_STATIC_ROWS + commentsCount;
}

- (STXFeedPhotoCell *)photoCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = NSStringFromClass([STXFeedPhotoCell class]);
    STXFeedPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
   
    if (cell.indexPath != nil && cell.indexPath.section != indexPath.section) {
        [cell cancelImageLoading];
    }
  
    cell.indexPath = indexPath;
    
    if (indexPath.section < [self.posts count]) {
        id<STXPostItem> post = self.posts[indexPath.section];
        cell.postItem = post;
        cell.delegate = self.controller;
    }
    
    return cell;
}

- (STXLikesCell *)likesCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> post = self.posts[indexPath.section];
    STXLikesCell *cell;
    
    if (cell == nil) {
        NSDictionary *likes = [post likes];
        NSInteger count = [[likes valueForKey:@"count"] integerValue];
        if (count > 2) {
            static NSString *CellIdentifier = @"STXLikesCountCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[STXLikesCell alloc] initWithStyle:STXLikesCellStyleLikesCount likes:likes reuseIdentifier:CellIdentifier];
            }
        } else {
            static NSString *CellIdentifier = @"STXLikersCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[STXLikesCell alloc] initWithStyle:STXLikesCellStyleLikers likes:likes reuseIdentifier:CellIdentifier];
            }
        }

        cell.delegate = self.controller;
    }
    
    cell.likes = [post likes];
    
    return cell;
}

- (STXCaptionCell *)captionCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> post = self.posts[indexPath.section];
    
    NSString *CellIdentifier = NSStringFromClass([STXCaptionCell class]);
    STXCaptionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[STXCaptionCell alloc] initWithCaption:[post caption] reuseIdentifier:CellIdentifier];
        cell.delegate = self.controller;
    }
    
    cell.caption = [post caption];
    
    return cell;
}

- (STXCommentCell *)commentCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> post = self.posts[indexPath.section];
    STXCommentCell *cell;
    
    if (indexPath.row == 0 && [post totalComments] > MAX_NUMBER_OF_COMMENTS) {

        static NSString *AllCommentsCellIdentifier = @"STXAllCommentsCell";
        cell = [tableView dequeueReusableCellWithIdentifier:AllCommentsCellIdentifier];
    
        if (cell == nil) {
            cell = [[STXCommentCell alloc] initWithStyle:STXCommentCellStyleShowAllComments
                                           totalComments:[post totalComments]
                                         reuseIdentifier:AllCommentsCellIdentifier];
        } else {
            cell.totalComments = [post totalComments];
        }
        
    } else {
        static NSString *CellIdentifier = @"STXSingleCommentCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        NSArray *comments = [post comments];
        id<STXCommentItem> comment = comments[indexPath.row];
        
        if (indexPath.row < [comments count]) {
            if (cell == nil) {
                cell = [[STXCommentCell alloc] initWithStyle:STXCommentCellStyleSingleComment
                                                     comment:comment
                                             reuseIdentifier:CellIdentifier];
            } else {
                cell.comment = comment;
            }
        }
    }
    
    cell.delegate = self.controller;

    return cell;
}

- (STXUserActionCell *)userActionCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    id<STXPostItem> postItem = self.posts[indexPath.section];
    STXUserActionCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([STXUserActionCell class]) forIndexPath:indexPath];
    cell.postItem = postItem;
    cell.delegate = self.controller;
    cell.indexPath = indexPath;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    NSInteger captionRowOffset = 3;
    
    id<STXPostItem> postItem = self.posts[indexPath.section];
    NSInteger commentsCount = MIN(MAX_NUMBER_OF_COMMENTS, [postItem totalComments]);
    NSInteger commentsRowLimit = captionRowOffset + commentsCount;
    
    if (indexPath.row == PHOTO_CELL_ROW) {
        cell = [self photoCellForTableView:tableView atIndexPath:indexPath];
    } else if (indexPath.row == LIKES_CELL_ROW) {
        cell = [self likesCellForTableView:tableView atIndexPath:indexPath];
    } else if (indexPath.row == CAPTION_CELL_ROW) {
        cell = [self captionCellForTableView:tableView atIndexPath:indexPath];
    } else if (indexPath.row > CAPTION_CELL_ROW && indexPath.row < commentsRowLimit) {
        NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:indexPath.row-captionRowOffset inSection:indexPath.section];
        cell = [self commentCellForTableView:tableView atIndexPath:commentIndexPath];
    } else {
        cell = [self userActionCellForTableView:tableView atIndexPath:indexPath];
    }
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

@end
