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

#import "FPComment.h"
#import "FPAppState.h"
#import "FPUser.h"
#import <KZPropertyMapper/KZPropertyMapper.h>

@interface FPComment ()

@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSDate *postDate;
@property (copy, nonatomic) FPUser *from;

@end

@implementation FPComment

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_commentID forKey:@"commentID"];
  [encoder encodeObject:_text forKey:@"text"];
  [encoder encodeObject:_postDate forKey:@"postDate"];
  [encoder encodeObject:_from forKey:@"from"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _commentID = [decoder decodeObjectForKey:@"commentID"];
    _text = [decoder decodeObjectForKey:@"text"];
    _postDate = [decoder decodeObjectForKey:@"postDate"];
    _from = [decoder decodeObjectForKey:@"from"];
  }

  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  FPComment *theCopy = [[[self class] allocWithZone:zone] init];
  [theCopy setCommentID:[_commentID copy]];
  [theCopy setText:[_text copy]];
  [theCopy setPostDate:[_postDate copy]];
  [theCopy setFrom:[_from copy]];

  return theCopy;
}

#pragma mark - Initializers

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (self) {
    NSArray *errors;
    NSDictionary *mappingDictionary = @{ @"text": KZProperty(text),
                                         @"timestamp": KZBox(Date, postDate)};

    [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:mappingDictionary errors:&errors];
    if(dictionary[@"author"]) {
      self.from = [[FPUser alloc] initWithDictionary:dictionary[@"author"]];
    }
  }
  return self;
}

- (instancetype)initWithSnapshot:(FIRDataSnapshot *)snapshot {
  FPComment *comment = [self initWithDictionary:snapshot.value];
  comment.commentID = snapshot.key;
  return comment;
}

- (NSUInteger)hash
{
  return [_commentID hash];
}

- (BOOL)isEqualToComment:(FPComment *)comment {
  return [comment.commentID isEqualToString:_commentID];
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[FPComment class]]) {
    return NO;
  }

  return [self isEqualToComment:(FPComment *)object];
}

- (NSString *)description {
  NSDictionary *dictionary = @{ @"commentID": self.commentID ? : @"",
                                @"from": self.from ? [self.from username] : @"",
                                @"text": self.text ? : @"" };
  return [NSString stringWithFormat:@"<%@: %p> %@", NSStringFromClass([self class]), self, dictionary];
}

@end
