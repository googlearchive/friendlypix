//
//  STXLabel.m
//  STXDynamicTableView
//
//  Created by Hoang Ta on 3/19/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXLabel.h"

#import "NSString+Emoji.h"

@implementation STXLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self stx_setupAppearance];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self stx_setupAppearance];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self stx_setupAppearance];
}

- (void)stx_setupAppearance
{
}

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    if ([self.text stringContainsEmoji]) {
        UIFont *emojiFont = [UIFont fontWithName:@"AppleColorEmoji" size:self.font.pointSize];
        intrinsicContentSize.height = emojiFont.lineHeight;
    }
    
    return intrinsicContentSize;
}

@end
