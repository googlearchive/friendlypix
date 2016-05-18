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

#import "FPUser.h"
#import <KZPropertyMapper.h>

@interface FPUser ()

@property (copy, nonatomic) NSString *fullname;
@property (copy, nonatomic) NSURL *profilePictureURL;

@end

@implementation FPUser

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_userID forKey:@"userID"];
  [encoder encodeObject:_fullname forKey:@"fullname"];
  [encoder encodeObject:_profilePictureURL forKey:@"profilePictureURL"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _userID = [decoder decodeObjectForKey:@"userID"];
    _fullname = [decoder decodeObjectForKey:@"fullname"];
    _profilePictureURL = [decoder decodeObjectForKey:@"profilePictureURL"];
  }

  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  FPUser *theCopy = [[[self class] allocWithZone:zone] init];
  [theCopy setUserID:[_userID copy]];
  [theCopy setFullname:[_fullname copy]];
  [theCopy setProfilePictureURL:[_profilePictureURL copy]];

  return theCopy;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super init];
  if (self) {
    NSArray *errors;
    NSDictionary *mappingDictionary = @{
                                        @"full_name": KZProperty(fullname),
                                        @"profile_picture": KZBox(URL, profilePictureURL),
                                        @"uid": KZProperty(userID)};

    [KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:mappingDictionary errors:&errors];
  }

  return self;
}

- (instancetype)initWithSnapshot:(FIRDataSnapshot *)snapshot {
  FPUser *user = [self initWithDictionary:snapshot.value];
  user.userID = snapshot.key;
  return user;
}

- (NSUInteger)hash {
  return [_userID hash];
}

- (BOOL)isEqualToUser:(FPUser *)user {
  return [user.userID isEqualToString:_userID];
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[FPUser class]]) {
    return NO;
  }

  return [self isEqualToUser:(FPUser *)object];
}

- (NSString *)description {
  NSDictionary *dictionary = @{ @"userID": self.userID ? : @"",
                                @"fullname": self.username ? : @"",
                                @"profilePictureURL": self.profilePictureURL ? : @"" };
  return [NSString stringWithFormat:@"<%@: %p> %@", NSStringFromClass([self class]), self, dictionary];
}

- (NSString *)username {
  return _fullname;
}

- (NSDictionary *)author {
  return @{ @"uid": self.userID ? : @"",
            @"full_name": self.fullname ? : @"",
            @"profile_picture": self.profilePictureURL.absoluteString ? : @"" };
}

@end
