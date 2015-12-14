//
//  STXPostItem.h
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 3/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

@import Foundation;

@protocol STXUserItem;

@protocol STXPostItem <NSObject>

- (NSString *)postID;
- (NSDate *)postDate;
- (NSURL *)sharedURL;
- (NSURL *)photoURL;
- (NSString *)captionText;
- (NSDictionary *)caption;
- (NSDictionary *)likes;
- (NSArray *)comments;

- (BOOL)liked;

- (NSInteger)totalLikes;
- (NSInteger)totalComments;

- (id<STXUserItem>)user;

@end
