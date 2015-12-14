//
//  UIImage+STXImage.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 28/2/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "UIImage+STXImage.h"

@implementation UIImage (STXImage)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)imageSize
{
    CGRect rect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)cropImageWithInfo:(NSDictionary *)info
{
    UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    CGRect cropRect = [[info objectForKey:UIImagePickerControllerCropRect] CGRectValue];
    CGAffineTransform rotateTransform = CGAffineTransformIdentity;
    
    switch (originalImage.imageOrientation) {
        case UIImageOrientationDown:
            rotateTransform = CGAffineTransformRotate(rotateTransform, M_PI);
            rotateTransform = CGAffineTransformTranslate(rotateTransform, -originalImage.size.width, -originalImage.size.height);
            break;
            
        case UIImageOrientationLeft:
            rotateTransform = CGAffineTransformRotate(rotateTransform, M_PI_2);
            rotateTransform = CGAffineTransformTranslate(rotateTransform, 0.0, -originalImage.size.height);
            break;
            
        case UIImageOrientationRight:
            rotateTransform = CGAffineTransformRotate(rotateTransform, -M_PI_2);
            rotateTransform = CGAffineTransformTranslate(rotateTransform, -originalImage.size.width, 0.0);
            break;
            
        default:
            break;
    }
    
    CGRect rotatedCropRect = CGRectApplyAffineTransform(cropRect, rotateTransform);
    
    CGImageRef croppedImage = CGImageCreateWithImageInRect([originalImage CGImage], rotatedCropRect);
    UIImage *result = [UIImage imageWithCGImage:croppedImage scale:[UIScreen mainScreen].scale orientation:originalImage.imageOrientation];
    CGImageRelease(croppedImage);
    
    return result;
}

- (UIImage *)squareAspectFilledImage
{
    // This calculates the crop area.
    CGFloat originalWidth  = self.size.width * self.scale;
    CGFloat originalHeight = self.size.height * self.scale;
    
    CGFloat edge = fminf(originalWidth, originalHeight);
    
    CGFloat posX = (originalWidth - edge) / 2.f;
    CGFloat posY = (originalHeight - edge) / 2.f;
    
    CGRect cropSquare = CGRectMake(posX, posY, edge, edge);
    CGImageRef croppedCGImage = CGImageCreateWithImageInRect(self.CGImage, cropSquare);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedCGImage scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(croppedCGImage);
    return croppedImage;
}

- (UIImage *)circleBorderedAtWidth:(CGFloat)width forImageWithSize:(CGSize)imageSize
{
    UIImage *squareAspectFilledImage = [self squareAspectFilledImage];
    
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
    
    [squareAspectFilledImage drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setStroke];
    
    CGContextSetLineWidth(context, width * [[UIScreen mainScreen] scale]);
    
    CGRect circleRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    UIImage *circledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return circledImage;
}

- (UIImage *)watermarkedImage
{
    UIImage *watermarkImage = [UIImage imageNamed:@"Watermark"];
    CGSize watermarkSize = watermarkImage.size;
    
    CGSize totalSize = CGSizeMake(self.size.width, self.size.height + watermarkSize.height);
    
    UIGraphicsBeginImageContextWithOptions(totalSize, YES, 0);
    
    CGRect drawRect = CGRectMake(0, 0, totalSize.width, self.size.height);
    [self drawInRect:drawRect];
    
    CGRect watermarkRect = CGRectMake(0, self.size.height, CGRectGetWidth(drawRect), watermarkSize.height);
    [watermarkImage drawInRect:watermarkRect];
    
    UIImage *watermarkedImage = UIGraphicsGetImageFromCurrentImageContext();
    return watermarkedImage;
}

@end
