//
//  STXFeedPhotoCell.m
//  STXDynamicTableView
//
//  Created by Triệu Khang on 24/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXFeedPhotoCell.h"

#import "UIImageView+Masking.h"

@interface STXFeedPhotoCell ()

@property (weak, nonatomic) IBOutlet UILabel *profileLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *postImageView;

@end

@implementation STXFeedPhotoCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.profileImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *imageGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileTapped:)];
    [self.profileImageView addGestureRecognizer:imageGestureRecognizer];
    
    self.profileLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *labelGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileTapped:)];
    [self.profileLabel addGestureRecognizer:labelGestureRecognizer];
    
    self.dateLabel.backgroundColor = [self.dateLabel superview].backgroundColor;
    
    self.profileImageView.clipsToBounds = YES;

    self.postImageView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setPostItem:(id<STXPostItem>)postItem
{
    if (_postItem != postItem) {
        _postItem = postItem;
        
        self.dateLabel.textColor = [UIColor grayColor];
        self.dateLabel.text = [MHPrettyDate prettyDateFromDate:postItem.postDate withFormat:MHPrettyDateLongRelativeTime];
        
        id<STXUserItem> userItem = [postItem user];
        NSString *name = [userItem fullname];
        self.profileLabel.text = name;
        NSURL *profilePhotoURL = [userItem profilePictureURL];
        
        [self.profileImageView setCircleImageWithURL:profilePhotoURL placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"] borderWidth:2];
        
        [self.postImageView setImageWithURL:postItem.photoURL];
    }
}

- (UIImage *)photoImage
{
    _photoImage = self.postImageView.image;
    return _photoImage;
}

- (void)cancelImageLoading
{
    [self.profileImageView cancelImageRequestOperation];
    [self.profileImageView setCircleImageWithURL:nil placeholderImage:[UIImage imageNamed:@"ProfilePlaceholder"]];
    
    [self.postImageView cancelImageRequestOperation];
    self.postImageView.image = nil;
}

#pragma mark - Actions

- (void)profileTapped:(UIGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(feedCellWillShowPoster:)])
        [self.delegate feedCellWillShowPoster:[self.postItem user]];
}

@end
