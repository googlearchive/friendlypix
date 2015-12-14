//
//  UIImageView+Masking.h
//  STXDynamicTableView
//
//  Created by Jesse Armand on 7/2/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

@interface UIImageView (Masking)

- (void)setCircleImageWithURL:(NSURL *)imageURL placeholderImage:(UIImage *)placeholderImage;

- (void)setCircleImageWithURL:(NSURL *)imageURL placeholderImage:(UIImage *)placeholderImage borderWidth:(CGFloat)borderWidth;

@end
