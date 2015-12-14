//
//  UIImage+STXImage.h
//  STXDynamicTableView
//
//  Created by Jesse Armand on 28/2/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

@import UIKit;

@interface UIImage (STXImage)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)imageSize;

+ (UIImage *)cropImageWithInfo:(NSDictionary *)info;

- (UIImage *)squareAspectFilledImage;

- (UIImage *)circleBorderedAtWidth:(CGFloat)width forImageWithSize:(CGSize)imageSize;

- (UIImage *)watermarkedImage;

@end
