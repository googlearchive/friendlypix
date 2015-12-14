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

#import "FPPost.h"
#import "FPUser.h"
#import "FPAppState.h"
#define MAX_NUMBER_OF_COMMENTS 5


@interface FPPost () <NSCoding, NSCopying>

@property (copy, nonatomic) NSString *postID;
@property (copy, nonatomic) NSDate *postDate;

@property (copy, nonatomic) NSURL *imageURL;
@property (copy, nonatomic) NSURL *link;

//@property (copy, nonatomic) NSDictionary *caption;

@property (copy, nonatomic) NSString *fromUser;
@property (copy, nonatomic) NSString *text;

//@property (nonatomic) NSInteger likeCount;
//@property (nonatomic) NSInteger commentCount;
@property (copy, nonatomic) NSMutableArray *comments;
@property (copy, nonatomic) NSDictionary *likes;

//@property (nonatomic) BOOL liked;

@end

@implementation FPPost

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_postID forKey:@"postID"];
  [encoder encodeObject:_postDate forKey:@"postDate"];
  [encoder encodeObject:_imageURL forKey:@"imageURL"];
  [encoder encodeObject:_link forKey:@"link"];
//  [encoder encodeObject:_caption forKey:@"caption"];
//  [encoder encodeInteger:_likeCount forKey:@"likeCount"];
//  [encoder encodeInteger:_commentCount forKey:@"commentCount"];
  [encoder encodeObject:_comments forKey:@"comments"];
  [encoder encodeObject:_likes forKey:@"likes"];
  [encoder encodeObject:_fromUser forKey:@"fromUser"];
  [encoder encodeObject:_text forKey:@"text"];
//  [encoder encodeBool:_liked forKey:@"liked"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self) {
    _postID = [decoder decodeObjectForKey:@"postID"];
    _postDate = [decoder decodeObjectForKey:@"postDate"];
    _imageURL = [decoder decodeObjectForKey:@"imageURL"];
    _link = [decoder decodeObjectForKey:@"link"];
//    _caption = [decoder decodeObjectForKey:@"caption"];
//    _likeCount = [decoder decodeIntegerForKey:@"likeCount"];
//    _commentCount = [decoder decodeIntegerForKey:@"commentCount"];
    _comments = [decoder decodeObjectForKey:@"comments"];
    _likes = [decoder decodeObjectForKey:@"likes"];
    _fromUser = [decoder decodeObjectForKey:@"fromUser"];
    _text = [decoder decodeObjectForKey:@"text"];
//    _liked = [decoder decodeBoolForKey:@"liked"];
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
  FPPost *theCopy = [[FPPost allocWithZone:zone] init];  // use designated initializer

  [theCopy setPostID:[_postID copy]];
  [theCopy setPostDate:[_postDate copy]];
  [theCopy setImageURL:[_imageURL copy]];
  [theCopy setLink:[_link copy]];
//  [theCopy setCaption:[_caption copy]];
//  [theCopy setLikeCount:_likeCount];
//  [theCopy setCommentCount:_commentCount];
  [theCopy setComments:[_comments copy]];
  [theCopy setLikes:[_likes copy]];
  [theCopy setFromUser:_fromUser];
  [theCopy setText:_text];

  return theCopy;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
  self = [super init];
  if (self) {
    NSArray *errors;
    NSDictionary *mappingDictionary = @{ @"link": KZBox(URL, link),
                                         @"text": KZProperty(text),
//                                         @"caption": KZProperty(caption),
                                         @"user": KZProperty(fromUser),
//                                         @"user_has_liked": KZProperty(liked),
                                         @"image": KZBox(URL, imageURL),
                                         @"likes": KZProperty(likes),
//                                         @"like_count": KZProperty(likeCount),
                                         @"created_time": KZBox(Date, postDate),
//                                         @"comment_count": KZProperty(commentCount)
                                         };

    [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:mappingDictionary errors:&errors];
  }

  return self;
}

- (instancetype)initWithSnapshot:(FDataSnapshot *)snapshot
{
  FPPost *post = [self initWithDictionary:snapshot.value];
  post.postID = snapshot.key;
  _comments = [[NSMutableArray alloc] init];
  return post;
}


#pragma mark - NSObject

- (NSUInteger)hash
{
  return [_postID hash];
}

- (BOOL)isEqualToPost:(FPPost *)post
{
  return [post.postID isEqualToString:_postID];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[FPPost class]]) {
    return NO;
  }

  return [self isEqualToPost:(FPPost *)object];
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
  return [[NSDate alloc] initWithTimeIntervalSince1970:1420973061];
  //return self.postDate;
}

- (NSString *)captionText
{
  return self.text;
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
  return [_comments copy];
}

- (NSInteger)totalLikes
{
  return [_likes count];
}

- (NSInteger)totalComments
{
  return [_comments count];
}

- (NSDictionary *)likes
{
  return @{@"count": [NSNumber numberWithInt:[self totalLikes]]} ;
}

- (NSDictionary *)caption
{
  return @{@"text": self.text};
}


-(void)addComment:(FPComment *)comment
{
  [_comments addObject:comment];
}

- (id<STXUserItem>)user
{
  return [FPAppState sharedInstance].users[_fromUser];
}

- (BOOL)liked
{
  return [_likes objectForKey:[FPAppState sharedInstance].currentUser.userID];
}

@end
