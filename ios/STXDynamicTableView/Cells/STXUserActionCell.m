//
//  STXUserActionCell.m
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 10/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

#import "STXUserActionCell.h"

#import "UIButton+STXButton.h"

@interface STXUserActionCell ()

@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIView *buttonDividerLeft;
@property (weak, nonatomic) IBOutlet UIView *buttonDividerRight;

@end

@implementation STXUserActionCell

- (void)awakeFromNib
{
    self.buttonDividerLeft.backgroundColor = [UIColor grayColor];
    self.buttonDividerRight.backgroundColor = [UIColor grayColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.postItem liked]) {
        [self setButton:self.likeButton toLoved:YES];
    } else {
        [self setButton:self.likeButton toLoved:NO];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setPostItem:(id<STXPostItem>)postItem
{
    _postItem = postItem;
    
    NSString *likeButtonTitle = postItem.liked ? NSLocalizedString(@"Loved", nil) : NSLocalizedString(@"Love", nil);
    [self.likeButton setTitle:likeButtonTitle forState:UIControlStateNormal];
    
    if (postItem.liked) {
        [self.likeButton stx_setSelectedAppearance];
    } else {
        [self.likeButton stx_setNormalAppearance];
    }
}

#pragma mark - Action

- (void)setButton:(UIButton *)button toLoved:(BOOL)loved
{
    if (loved) {
        [button setTitle:NSLocalizedString(@"Loved", nil) forState:UIControlStateNormal];
        [button stx_setSelectedAppearance];
    } else {
        [button setTitle:NSLocalizedString(@"Love", nil) forState:UIControlStateNormal];
        [button stx_setNormalAppearance];
    }
}

- (IBAction)like:(id)sender
{
    // Need to return here if it's disabled, or the buttons may do a delayed
    // update.
    if (![sender isUserInteractionEnabled]) {
        return;
    }
    
    // Prevent rapid interaction
    [sender setUserInteractionEnabled:NO];
    
    if (![self.postItem liked]) {
        [self setButton:sender toLoved:YES];
        
        if ([self.delegate respondsToSelector:@selector(userDidLike:)]) {
            [self.delegate userDidLike:self];
        }
    } else {
        [self setButton:sender toLoved:NO];
        
        if ([self.delegate respondsToSelector:@selector(userDidUnlike:)]) {
            [self.delegate userDidUnlike:self];
        }
    }
}

- (IBAction)comment:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(userWillComment:)]) {
        [self.delegate userWillComment:self];
    }
}

- (IBAction)share:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(userWillShare:)]) {
        [self.delegate userWillShare:self];
    }
}

@end
