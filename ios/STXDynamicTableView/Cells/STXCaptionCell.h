//
//  STXCaptionCell.h
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 10/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

@import UIKit;

@class STXCaptionCell;

@protocol STXCaptionCellDelegate <NSObject>

@optional

- (void)captionCell:(STXCaptionCell *)captionCell didSelectHashtag:(NSString *)hashtag;
- (void)captionCell:(STXCaptionCell *)captionCell didSelectMention:(NSString *)mention;
- (void)captionCell:(STXCaptionCell *)captionCell didSelectPoster:(id<STXUserItem>)userItem;

@end

@interface STXCaptionCell : UITableViewCell

@property (copy, nonatomic) NSDictionary *caption;

@property (weak, nonatomic) id <STXCaptionCellDelegate> delegate;

- (id)initWithCaption:(NSDictionary *)caption reuseIdentifier:(NSString *)reuseIdentifier;

@end