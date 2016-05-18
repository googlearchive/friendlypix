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
#import <KZPropertyMapper/KZPropertyMapper.h>
#define MAX_NUMBER_OF_COMMENTS 5


@interface FPPost () <NSCoding, NSCopying>

@property (copy, nonatomic) NSString *postID;
@property (copy, nonatomic) NSDate *postDate;

@property (copy, nonatomic) NSURL *imageURL;
@property (copy, nonatomic) NSURL *link;

//@property (copy, nonatomic) NSDictionary *caption;

@property (copy, nonatomic) FPUser *user;
@property (copy, nonatomic) NSString *text;

//@property (nonatomic) NSInteger likeCount;
//@property (nonatomic) NSInteger commentCount;
@property (copy, nonatomic) NSMutableArray *comments;

@end

@implementation FPPost

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_postID forKey:@"postID"];
  [encoder encodeObject:_postDate forKey:@"postDate"];
  [encoder encodeObject:_imageURL forKey:@"imageURL"];
  [encoder encodeObject:_link forKey:@"link"];
  //  [encoder encodeObject:_caption forKey:@"caption"];
  //  [encoder encodeInteger:_likeCount forKey:@"likeCount"];
  //  [encoder encodeInteger:_commentCount forKey:@"commentCount"];
  [encoder encodeObject:_comments forKey:@"comments"];
  [encoder encodeObject:_likes forKey:@"likes"];
  [encoder encodeObject:_user forKey:@"user"];
  [encoder encodeObject:_text forKey:@"text"];
  [encoder encodeBool:_liked forKey:@"liked"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
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
    _user = [decoder decodeObjectForKey:@"user"];
    _text = [decoder decodeObjectForKey:@"text"];
    _liked = [decoder decodeBoolForKey:@"liked"];
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  FPPost *theCopy = [[FPPost allocWithZone:zone] init];  // use designated initializer

  [theCopy setPostID:[_postID copy]];
  [theCopy setPostDate:[_postDate copy]];
  [theCopy setImageURL:[_imageURL copy]];
  [theCopy setLink:[_link copy]];
  [theCopy setComments:[_comments copy]];
  [theCopy setLikes:[_likes copy]];
  [theCopy setUser:_user];
  [theCopy setText:_text];
  [theCopy setLiked:_liked];

  return theCopy;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (self) {
    NSArray *errors;
    NSDictionary *mappingDictionary = @{
                                        @"text": KZProperty(text),
                                        @"url": KZBox(URL, imageURL),
                                        @"timestamp": KZBox(Date, postDate)
                                        };

    [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:mappingDictionary errors:&errors];
    if(dictionary[@"author"]) {
      self.user = [[FPUser alloc] initWithDictionary:dictionary[@"author"]];
    }
  }

  return self;
}

- (instancetype)initWithSnapshot:(FIRDataSnapshot *)snapshot andComments:(NSArray<FPComment *> *)comments {
  FPPost *post = [self initWithDictionary:snapshot.value];
  post.postID = snapshot.key;
  _comments = comments;
  _liked = [_likes objectForKey:[FPAppState sharedInstance].currentUser.userID];
  return post;
}


#pragma mark - NSObject

- (NSUInteger)hash {
  return [_postID hash];
}

- (BOOL)isEqualToPost:(FPPost *)post {
  return [post.postID isEqualToString:_postID];
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[FPPost class]]) {
    return NO;
  }

  return [self isEqualToPost:(FPPost *)object];
}

- (NSString *)description {
  NSDictionary *dictionary = @{ @"postID": self.postID ? : @"",
                                @"postDate": self.postDate ? : @"",
                                @"sharedURL": self.sharedURL ? : @"" };
  return [NSString stringWithFormat:@"<%@: %p> %@", NSStringFromClass([self class]), self, dictionary];
}

#pragma mark - FPPostItem

- (NSString *)captionText {
  return self.text;
}

- (NSURL *)sharedURL {
  return self.link;
}

- (NSURL *)photoURL {
  return self.imageURL;
}

//- (NSArray *)comments {
//  return [_comments copy];
//}

//- (NSArray *)mutableComments {
//  return _comments;
//}

- (NSInteger)totalLikes {
  long totalLikes = [_likes count];
  // if current user liked after syncing.
  if (_liked && [_likes objectForKey:[FPAppState sharedInstance].currentUser.userID]) {
    ++totalLikes;
  } else if (!_liked && ![_likes objectForKey:[FPAppState sharedInstance].currentUser.userID]) {
    // if current user disliked after syncing.
    --totalLikes;
  }
  return totalLikes;
}

- (NSInteger)totalComments {
  return [_comments count];
}

- (NSDictionary *)likes {
  return @{@"count": [NSNumber numberWithInt:[self totalLikes]]} ;
}

- (NSDictionary *)caption {
  return @{@"text": self.text};
}

@end
