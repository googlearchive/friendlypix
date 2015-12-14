//
//  STXCommentCell.m
//  STXDynamicTableViewExample
//
//  Created by Jesse Armand on 10/4/14.
//  Copyright (c) 2014 2359 Media Pte Ltd. All rights reserved.
//

#import "STXCommentCell.h"
#import "STXAttributedLabel.h"

static CGFloat STXCommentViewLeadingEdgeInset = 10.f;
static CGFloat STXCommentViewTrailingEdgeInset = 10.f;

static NSString *HashTagAndMentionRegex = @"(#|@)(\\w+)";

@interface STXCommentCell () <TTTAttributedLabelDelegate>

@property (nonatomic) STXCommentCellStyle cellStyle;
@property (strong, nonatomic) STXAttributedLabel *commentLabel;

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation STXCommentCell

- (id)initWithStyle:(STXCommentCellStyle)style comment:(id<STXCommentItem>)comment totalComments:(NSInteger)totalComments reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _cellStyle = style;
        
        if (style == STXCommentCellStyleShowAllComments) {
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Show %d comments", nil), totalComments];
            _commentLabel = [self allCommentsLabelWithTitle:title];
        } else {
            id<STXUserItem> commenter = [comment from];
            _commentLabel = [self commentLabelWithText:[comment text] commenter:[commenter username]];
        }
        
        [self.contentView addSubview:_commentLabel];
        _commentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
   }
    return self;
}
                                                                              
- (instancetype)initWithStyle:(STXCommentCellStyle)style comment:(id<STXCommentItem>)comment reuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithStyle:style comment:comment totalComments:0 reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithStyle:(STXCommentCellStyle)style totalComments:(NSInteger)totalComments reuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithStyle:style comment:nil totalComments:totalComments reuseIdentifier:reuseIdentifier];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
   
    self.commentLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.frame) - (STXCommentViewLeadingEdgeInset + STXCommentViewTrailingEdgeInset);
}

- (void)updateConstraints
{
    if (!self.didSetupConstraints) {
        [self.commentLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, STXCommentViewLeadingEdgeInset, 0, STXCommentViewTrailingEdgeInset)];
        
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)setComment:(id<STXCommentItem>)comment
{
    if (_comment != comment) {
        _comment = comment;
        
        id <STXUserItem> commenter = [comment from];
        [self setCommentLabel:self.commentLabel text:[comment text] commenter:[commenter username]];
    }
}

- (void)setTotalComments:(NSInteger)totalComments
{
    if (_totalComments != totalComments) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Show %d comments", nil), totalComments];
        [self setAllCommentsLabel:self.commentLabel title:title];
    }
}

#pragma mark - Attributed Label

- (void)setAllCommentsLabel:(STXAttributedLabel *)commentLabel title:(NSString *)title
{
    [commentLabel setText:title];
}

- (void)setCommentLabel:(STXAttributedLabel *)commentLabel text:(NSString *)text commenter:(NSString *)commenter
{
    NSString *commentText = [NSString stringWithFormat:@"%@ %@", commenter, text];
    
    NSMutableArray *textCheckingResults = [NSMutableArray array];
    [commentLabel setText:commentText afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange searchRange = NSMakeRange(0, [mutableAttributedString length]);
        
        NSRange currentRange = [[mutableAttributedString string] rangeOfString:commenter options:NSLiteralSearch range:searchRange];
        NSTextCheckingResult *textCheckingResult = [NSTextCheckingResult linkCheckingResultWithRange:currentRange URL:nil];
        [textCheckingResults addObject:textCheckingResult];
        
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:HashTagAndMentionRegex
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        if (error) {
            UALog(@"%@", error);
        }
        
        [regex enumerateMatchesInString:[mutableAttributedString string] options:0 range:NSMakeRange(0, [mutableAttributedString length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [textCheckingResults addObject:result];
        }];
        
        return mutableAttributedString;
    }];
   
    for (NSTextCheckingResult *result in textCheckingResults) {
        [commentLabel addLinkWithTextCheckingResult:result];
    }
}

- (STXAttributedLabel *)allCommentsLabelWithTitle:(NSString *)title
{
    STXAttributedLabel *allCommentsLabel = [STXAttributedLabel newAutoLayoutView];
    allCommentsLabel.delegate = self;
    allCommentsLabel.textColor = [UIColor lightGrayColor];
    allCommentsLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    
    allCommentsLabel.linkAttributes = @{ (NSString *)kCTFontAttributeName: allCommentsLabel.font,
                                         (NSString *)kCTForegroundColorAttributeName: allCommentsLabel.textColor};
    allCommentsLabel.activeLinkAttributes = allCommentsLabel.linkAttributes;
    allCommentsLabel.inactiveLinkAttributes = allCommentsLabel.linkAttributes;
    [allCommentsLabel setText:title];
    
    NSTextCheckingResult *textCheckingResult = [NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(0, [title length]) URL:nil];
    [allCommentsLabel addLinkWithTextCheckingResult:textCheckingResult];
    
    return allCommentsLabel;
}

- (STXAttributedLabel *)commentLabelWithText:(NSString *)text commenter:(NSString *)commenter
{
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *commentText = [[commenter stringByAppendingString:@" "] stringByAppendingString:trimmedText];
    
    STXAttributedLabel *commentLabel = [[STXAttributedLabel alloc] initForParagraphStyleWithText:commentText];
    commentLabel.delegate = self;
    commentLabel.numberOfLines = 0;
    commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    commentLabel.linkAttributes = @{ (NSString *)kCTForegroundColorAttributeName: [UIColor blueColor] };
    commentLabel.activeLinkAttributes = commentLabel.linkAttributes;
    commentLabel.inactiveLinkAttributes = commentLabel.linkAttributes;
    
    [self setCommentLabel:commentLabel text:text commenter:commenter];
    
    return commentLabel;
}

- (void)showAllComments:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(commentCellWillShowAllComments:)])
        [self.delegate commentCellWillShowAllComments:self];
}

#pragma mark - Attributed Label

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result
{
    NSString *selectedText = [[label.attributedText string] substringWithRange:result.range];
    UALog(@"%@", selectedText);
    
    if ([selectedText hasPrefix:@"http://"] || [selectedText hasPrefix:@"https://"]) {
        NSURL *selectedURL = [NSURL URLWithString:selectedText];
        
        if (selectedURL) {
            if ([self.delegate respondsToSelector:@selector(commentCell:didSelectURL:)]) {
                [self.delegate commentCell:self didSelectURL:selectedURL];
            }
            return;
        }
    } else if ([selectedText hasPrefix:@"#"]) {
        NSString *hashtag = [selectedText substringFromIndex:1];
        
        if ([self.delegate respondsToSelector:@selector(commentCell:didSelectHashtag:)]) {
            [self.delegate commentCell:self didSelectHashtag:hashtag];
        }
    } else if ([selectedText hasPrefix:@"@"]) {
        NSString *mention = [selectedText substringFromIndex:1];
        
        if ([self.delegate respondsToSelector:@selector(commentCell:didSelectMention:)]) {
            [self.delegate commentCell:self didSelectMention:mention];
        }
    }
    
    if (self.cellStyle == STXCommentCellStyleShowAllComments) {
        [self showAllComments:label];
    } else {
        if ([self.delegate respondsToSelector:@selector(commentCell:willShowCommenter:)]) {
            [self.delegate commentCell:self willShowCommenter:[self.comment from]];
        }
    }
}

@end
