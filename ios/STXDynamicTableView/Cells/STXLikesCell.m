//
//  STXLikesCell.m
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 10/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

#import "STXLikesCell.h"

static CGFloat STXLikesViewLeadingEdgeInset = 10.f;
static CGFloat STXLikesViewTrailingEdgeInset = 10.f;

@interface STXLikesCell () <TTTAttributedLabelDelegate>

@property (nonatomic) BOOL didSetupConstraints;

@property (nonatomic) STXLikesCellStyle cellStyle;
@property (strong, nonatomic) TTTAttributedLabel *likesLabel;

@end

@implementation STXLikesCell

- (instancetype)initWithStyle:(STXLikesCellStyle)style likes:(NSDictionary *)likes reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _cellStyle = style;
        
        if (style == STXLikesCellStyleLikesCount) {
            NSInteger count = [[likes valueForKey:@"count"] integerValue];
            _likesLabel = [self likesLabelForCount:count];
        } else {
            NSArray *likers = [likes valueForKey:@"data"];
            _likesLabel = [self likersLabelForLikers:likers];
        }
        
        [self.contentView addSubview:_likesLabel];
        _likesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
   
    self.likesLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.frame) - (STXLikesViewLeadingEdgeInset + STXLikesViewTrailingEdgeInset);
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        [self.likesLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, STXLikesViewLeadingEdgeInset, 0, STXLikesViewTrailingEdgeInset)];
        
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)setLikes:(NSDictionary *)likes
{
    if (_likes != likes) {
        _likes = likes;
        
        NSInteger count = [[likes valueForKey:@"count"] integerValue];
        if (count > 2) {
            [self setLikesLabel:self.likesLabel count:count];
        } else {
            NSArray *likers = [likes valueForKey:@"data"];
            [self setLikersLabel:self.likesLabel likers:likers];
        }
    }
}

#pragma mark - Attributed Label

- (void)setLikesLabel:(TTTAttributedLabel *)likesLabel count:(NSInteger)count
{
    NSString *countString = [@(count) stringValue];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ loves", nil), countString];
    likesLabel.text = title;
}

- (void)setLikersLabel:(TTTAttributedLabel *)likersLabel likers:(NSArray *)likers
{
    NSMutableString *likersString = [NSMutableString stringWithCapacity:0];
    NSUInteger likerIndex = 0;
    NSArray *likerNames = [likers valueForKey:@"name"];
    for (NSString *likerName in likerNames) {
        if ([likerName length] > 0) {
            if (likerIndex == 0)
                [likersString setString:likerName];
            else
                [likersString appendFormat:NSLocalizedString(@" and %@", nil), likerName];
        }
        
        ++likerIndex;
    }
    
    if ([likersString length] > 0) {
        if ([likerNames count] == 1) {
            [likersString appendString:NSLocalizedString(@" loves this", nil)];
        } else {
            [likersString appendString:NSLocalizedString(@" love this", nil)];
        }
    }
    
    NSMutableArray *textCheckingResults = [NSMutableArray array];
    
    NSString *likersText = [likersString copy];
    
    [likersLabel setText:likersText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        
        NSRange searchRange = NSMakeRange(0, [mutableAttributedString length]);
        for (NSString *likerName in likerNames) {
            NSRange currentRange = [[mutableAttributedString string] rangeOfString:likerName options:NSLiteralSearch range:searchRange];
            
            NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:currentRange URL:nil];
            [textCheckingResults addObject:result];
            
            searchRange = NSMakeRange(currentRange.length, [mutableAttributedString length] - currentRange.length);
        }
        
        return mutableAttributedString;
    }];
    
    
    for (NSTextCheckingResult *result in textCheckingResults)
        [likersLabel addLinkWithTextCheckingResult:result];
}

- (TTTAttributedLabel *)likesLabelForCount:(NSInteger)count
{
    TTTAttributedLabel *likesLabel = [TTTAttributedLabel newAutoLayoutView];
    likesLabel.textColor = [UIColor blueColor];
    likesLabel.delegate = self;
    
    [self setLikesLabel:likesLabel count:count];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showLikers:)];
    [likesLabel addGestureRecognizer:recognizer];
    
    return likesLabel;
}

- (TTTAttributedLabel *)likersLabelForLikers:(NSArray *)likers
{
    TTTAttributedLabel *likersLabel = [TTTAttributedLabel newAutoLayoutView];
    likersLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    likersLabel.numberOfLines = 0;
    likersLabel.lineBreakMode = NSLineBreakByWordWrapping;
    likersLabel.delegate = self;
    
    likersLabel.linkAttributes = @{ (NSString *)kCTForegroundColorAttributeName: [UIColor blueColor],
                                    (NSString *)kCTUnderlineStyleAttributeName : @(kCTUnderlineStyleNone) };
    likersLabel.activeLinkAttributes = likersLabel.linkAttributes;
    likersLabel.inactiveLinkAttributes = likersLabel.linkAttributes;
    
    [self setLikersLabel:likersLabel likers:likers];
        
    return likersLabel;
}

#pragma mark - Actions

- (void)showLikers:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(likesCellWillShowLikes:)])
        [self.delegate likesCellWillShowLikes:self];
}

#pragma mark - Attributed Label

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result
{
    NSString *string = [[label.attributedText string] substringWithRange:result.range];
    UALog(@"%@", string);
    
    if ([self.delegate respondsToSelector:@selector(likesCellDidSelectLiker:)])
        [self.delegate likesCellDidSelectLiker:string];
}

@end
