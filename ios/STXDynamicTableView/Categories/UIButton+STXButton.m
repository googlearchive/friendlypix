//
//  UIButton+STXButton.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 28/1/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "UIButton+STXButton.h"

@implementation UIButton (STXButton)

- (void)stx_setNormalAppearance
{
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    
    self.titleLabel.backgroundColor = self.backgroundColor;
}

- (void)stx_setSelectedAppearance
{
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
}

@end
