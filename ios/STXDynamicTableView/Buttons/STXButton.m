//
//  STXButton.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 4/2/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "STXButton.h"

@interface STXButton ()

@property (strong, nonatomic) UIImage *stx_highlightedImage;
@property (strong, nonatomic) UIImage *stx_normalImage;

@end

@implementation STXButton

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Keep the image for each state initially when laying out subviews
    if (self.stx_normalImage == nil) {
        self.stx_normalImage = [self imageForState:UIControlStateNormal];
    }
    
    if (self.stx_highlightedImage == nil) {
        self.stx_highlightedImage = [self imageForState:UIControlStateHighlighted];
    }
}

- (void)stx_setupAppearance
{
}

- (void)stx_reverseButtonStateAppearance
{
}

- (void)stx_resetButtonStateAppearance
{
}

@end
