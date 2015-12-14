//
//  STXAttributedLabel.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 19/3/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXAttributedLabel.h"
#import "NSString+Emoji.h"

static CGFloat STXAttributedLabelHeightPadding = 4.f;

@implementation STXAttributedLabel

- (instancetype)initForParagraphStyleWithText:(NSString *)text
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        if ([text stringContainsEmoji]) {
            UIFont *commentFont = self.font;
            UIFont *emojiFont = [UIFont fontWithName:@"AppleColorEmoji" size:commentFont.pointSize];
            if (emojiFont.lineHeight > commentFont.lineHeight) {
                self.minimumLineHeight = emojiFont.lineHeight;
                self.lineHeightMultiple = emojiFont.lineHeight / commentFont.lineHeight;
            }
        }
    }
    
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicContentSize = [super intrinsicContentSize];
    return CGSizeMake(intrinsicContentSize.width, intrinsicContentSize.height + STXAttributedLabelHeightPadding);
}

@end
