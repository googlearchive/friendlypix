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

#import "FPPhotoDetailsFooterView.h"
//#import "PAPUtility.h"

@interface FPPhotoDetailsFooterView ()
@property (nonatomic, strong) UIView *mainView;
@end

@implementation FPPhotoDetailsFooterView

@synthesize commentField;
@synthesize mainView;
@synthesize hideDropShadow;


#pragma mark - NSObject

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        mainView = [[UIView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, 320.0f, 51.0f)];
        mainView.backgroundColor = [UIColor whiteColor];
        [self addSubview:mainView];
        
        UIImageView *messageIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"IconAddComment.png"]];
        messageIcon.frame = CGRectMake( 20.0f, 15.0f, 22.0f, 22.0f);
        [mainView addSubview:messageIcon];
        
        UIImageView *commentBox = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TextFieldComment.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f)]];
        commentBox.frame = CGRectMake(55.0f, 8.0f, 237.0f, 34.0f);
        [mainView addSubview:commentBox];
        
        commentField = [[UITextField alloc] initWithFrame:CGRectMake( 66.0f, 8.0f, 217.0f, 34.0f)];
        commentField.font = [UIFont systemFontOfSize:14.0f];
        commentField.placeholder = @"Add a comment";
        commentField.returnKeyType = UIReturnKeySend;
        commentField.textColor = [UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f];
        commentField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [commentField setValue:[UIColor colorWithRed:114.0f/255.0f green:114.0f/255.0f blue:114.0f/255.0f alpha:1.0f] forKeyPath:@"_placeholderLabel.textColor"]; // Are we allowed to modify private properties like this? -Héctor
        [mainView addSubview:commentField];
    }
    return self;
}



#pragma mark - PAPPhotoDetailsFooterView

+ (CGRect)rectForView {
    return CGRectMake( 0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 69.0f);
}

@end
