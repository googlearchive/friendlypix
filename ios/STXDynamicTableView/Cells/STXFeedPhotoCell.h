//
//  STXFeedPhotoCell.h
//  STXDynamicTableView
//
//  Created by Triệu Khang on 24/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

@import UIKit;

@protocol STXFeedPhotoCellDelegate <NSObject>

@optional

- (void)feedCellWillShowPoster:(id <STXUserItem>)poster;

@end

@interface STXFeedPhotoCell : UITableViewCell

@property (strong, nonatomic) NSIndexPath *indexPath;

@property (strong, nonatomic) id <STXPostItem> postItem;
@property (strong, nonatomic) UIImage *photoImage;

@property (weak, nonatomic) id <STXFeedPhotoCellDelegate> delegate;

- (void)cancelImageLoading;

@end
