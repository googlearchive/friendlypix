//
//  STXViewController+Sharing.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 18/2/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "UIViewController+Sharing.h"

@implementation UIViewController (Sharing)

- (void)shareImage:(UIImage *)image text:(NSString *)text url:(NSURL *)url
{
    NSMutableArray *activityItems = [NSMutableArray array];
    if (image)
        [activityItems addObject:image];
    if (text)
        [activityItems addObject:text];
    if (url)
        [activityItems addObject:url];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

@end
