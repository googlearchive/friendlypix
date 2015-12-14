//
//  STXCommentCell.h
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 10/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(int16_t, STXCommentCellStyle) {
    STXCommentCellStyleSingleComment,
    STXCommentCellStyleShowAllComments
};

@class STXCommentCell;

@protocol STXCommentCellDelegate <NSObject>

@optional

- (void)commentCellWillShowAllComments:(STXCommentCell *)commentCell;
- (void)commentCell:(STXCommentCell *)commentCell willShowCommenter:(id<STXUserItem>)commenter;
- (void)commentCell:(STXCommentCell *)commentCell didSelectURL:(NSURL *)url;
- (void)commentCell:(STXCommentCell *)commentCell didSelectHashtag:(NSString *)hashtag;
- (void)commentCell:(STXCommentCell *)commentCell didSelectMention:(NSString *)mention;

@end

@interface STXCommentCell : UITableViewCell

@property (copy, nonatomic) id <STXCommentItem> comment;
@property (nonatomic) NSInteger totalComments;

@property (weak, nonatomic) id <STXCommentCellDelegate> delegate;

- (instancetype)initWithStyle:(STXCommentCellStyle)style comment:(id<STXCommentItem>)comment reuseIdentifier:(NSString *)reuseIdentifier;
- (instancetype)initWithStyle:(STXCommentCellStyle)style totalComments:(NSInteger)totalComments reuseIdentifier:(NSString *)reuseIdentifier;

@end
