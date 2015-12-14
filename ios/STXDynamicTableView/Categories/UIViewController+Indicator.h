//
//  UIViewController+Indicator.h
//  STXDynamicTableView
//
//  Created by Jesse Armand on 28/1/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

@interface UIViewController (Indicator)

/** 
 *  Return a new UIActivityIndicatorView at the middle of the UIViewController's view
 *  It will be positioned on top of contentView if provided, if not just add it to self.view.
 */

- (UIActivityIndicatorView *)activityIndicatorViewOnView:(UIView *)contentView;

@end
