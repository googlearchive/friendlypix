//
//  STXCommentItem.h
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 3/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

@import Foundation;

@protocol STXUserItem;

@protocol STXCommentItem <NSObject>

- (id<STXUserItem>)from;

- (NSString *)commentID;
- (NSString *)text;
- (NSDate *)postDate;

@end
