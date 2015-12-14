//
//  UIViewController+Indicator.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 28/1/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "UIViewController+Indicator.h"

#import <PureLayout/PureLayout.h>

@implementation UIViewController (Indicator)

- (UIActivityIndicatorView *)activityIndicatorViewOnView:(UIView *)contentView
{
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    activityIndicatorView.hidesWhenStopped = YES;
    
    if (contentView)
        [self.view insertSubview:activityIndicatorView aboveSubview:contentView];
    else
        [self.view addSubview:activityIndicatorView];
    
    [activityIndicatorView autoCenterInSuperview];
    return activityIndicatorView;
}

@end
