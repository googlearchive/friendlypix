//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "STXPost.h"
#import "STXUser.h"

@interface STXPost () <NSCoding, NSCopying>

@property (copy, nonatomic) NSString *postID;
@property (copy, nonatomic) NSDate *postDate;

@property (copy, nonatomic) NSURL *imageURL;
@property (copy, nonatomic) NSURL *link;

@property (copy, nonatomic) NSDictionary *caption;
@property (copy, nonatomic) NSDictionary *userDictionary;
@property (copy, nonatomic) NSString *fromUser;

@property (copy, nonatomic) NSDictionary *likes;
@property (copy, nonatomic) NSArray *comments;
@property (copy, nonatomic) NSDictionary *commentsDictionary;

@property (nonatomic) BOOL liked;

@end

@implementation STXPost

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_postID forKey:@"postID"];
    [encoder encodeObject:_postDate forKey:@"postDate"];
    [encoder encodeObject:_imageURL forKey:@"imageURL"];
    [encoder encodeObject:_link forKey:@"link"];
    [encoder encodeObject:_caption forKey:@"caption"];
    [encoder encodeObject:_userDictionary forKey:@"userDictionary"];
    [encoder encodeObject:_likes forKey:@"likes"];
    [encoder encodeObject:_comments forKey:@"comments"];
    [encoder encodeObject:_commentsDictionary forKey:@"commentsDictionary"];
    [encoder encodeBool:_liked forKey:@"liked"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _postID = [decoder decodeObjectForKey:@"postID"];
        _postDate = [decoder decodeObjectForKey:@"postDate"];
        _imageURL = [decoder decodeObjectForKey:@"imageURL"];
        _link = [decoder decodeObjectForKey:@"link"];
        _caption = [decoder decodeObjectForKey:@"caption"];
        _userDictionary = [decoder decodeObjectForKey:@"userDictionary"];
        _likes = [decoder decodeObjectForKey:@"likes"];
        _comments = [decoder decodeObjectForKey:@"comments"];
        _commentsDictionary = [decoder decodeObjectForKey:@"commentsDictionary"];
        _liked = [decoder decodeBoolForKey:@"liked"];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    STXPost *theCopy = [[STXPost allocWithZone:zone] init];  // use designated initializer
    
    [theCopy setPostID:[_postID copy]];
    [theCopy setPostDate:[_postDate copy]];
    [theCopy setImageURL:[_imageURL copy]];
    [theCopy setLink:[_link copy]];
    [theCopy setCaption:[_caption copy]];
    [theCopy setUserDictionary:[_userDictionary copy]];
    [theCopy setLikes:[_likes copy]];
    [theCopy setComments:[_comments copy]];
    [theCopy setCommentsDictionary:[_commentsDictionary copy]];
    [theCopy setLiked:_liked];
    
    return theCopy;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        NSArray *errors;
        NSDictionary *mappingDictionary = @{ @"id": KZProperty(postID),
                                             @"link": KZBox(URL, link),
                                             @"caption": KZProperty(caption),
                                             @"user": KZProperty(userDictionary),
                                             @"user_has_liked": KZProperty(liked),
                                             @"images": @{ @"standard_resolution": @{ @"url": KZBox(URL, imageURL) } },
                                             @"likes": KZProperty(likes),
                                             @"comments": KZProperty(commentsDictionary) };
        
        [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:mappingDictionary errors:&errors];
    }
    
    return self;
}

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot
{
  NSMutableDictionary *dictionary = snapshot.value;
  dictionary[@"id"] = snapshot.key;
  _commentsDictionary = ((NSDictionary*) snapshot.value[@"comments"]);
  return [self initWithDictionary:dictionary];
}


#pragma mark - NSObject

- (NSUInteger)hash
{
    return [_postID hash];
}

- (BOOL)isEqualToPost:(STXPost *)post
{
    return [post.postID isEqualToString:_postID];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[STXPost class]]) {
        return NO;
    }
    
    return [self isEqualToPost:(STXPost *)object];
}

- (NSString *)description
{
    NSDictionary *dictionary = @{ @"postID": self.postID ? : @"",
                                  @"postDate": self.postDate ? : @"",
                                  @"sharedURL": self.sharedURL ? : @"" };
    return [NSString stringWithFormat:@"<%@: %p> %@", NSStringFromClass([self class]), self, dictionary];
}

#pragma mark - STXPostItem

- (NSDate *)postDate
{
    NSTimeInterval createdTime = [[self.caption valueForKey:@"created_time"] doubleValue];
    return [NSDate dateWithTimeIntervalSince1970:createdTime];
}

- (NSString *)captionText
{
    return [self.caption valueForKey:@"text"];
}

- (NSURL *)sharedURL
{
    return self.link;
}

- (NSURL *)photoURL
{
    return self.imageURL;
}

- (NSArray *)comments
{
    if (_comments == nil) {
    
        NSMutableArray *mutableComments = [NSMutableArray array];

        NSArray *commentsArray = [self.commentsDictionary valueForKey:@"data"];
        for (NSDictionary *commentDictionary in commentsArray) {
            STXComment *comment = [[STXComment alloc] initWithDictionary:commentDictionary];
            [mutableComments addObject:comment];
        }
        
        _comments = [mutableComments copy];
    }
    
    return [_comments copy];
}

- (NSInteger)totalLikes
{
    NSNumber *count = [self.likes valueForKey:@"count"];
    return [count integerValue];
}

- (NSInteger)totalComments
{
    NSNumber *count = [self.commentsDictionary valueForKey:@"count"];
    return [count integerValue];
}

- (id<STXUserItem>)user
{
    STXUser *user = [[STXUser alloc] initWithDictionary:self.userDictionary];
    return user;
}

@end
