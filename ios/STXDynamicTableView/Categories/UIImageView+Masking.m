//
//  UIImageView+Masking.m
//  STXDynamicTableView
//
//  Created by Jesse Armand on 7/2/14.
//  Copyright (c) 2014 2359 Media. All rights reserved.
//

#import "UIImageView+Masking.h"
#import "UIImage+STXImage.h"

#import <objc/runtime.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface STXImageCache : NSCache <AFImageCache>
@end

#pragma mark -

static char kSTXSharedImageCacheKey;
static char kSTXCircleImageOperationKey;

@interface UIImageView (_Masking)
@property (readwrite, nonatomic, strong, setter = stx_setCircleImageOperation:) NSOperation *stx_circleImageOperation;
@end

@implementation UIImageView (_Masking)

+ (NSOperationQueue *)stx_sharedCircleImageOperationQueue
{
    static NSOperationQueue *_stx_sharedCircleImageOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _stx_sharedCircleImageOperationQueue = [[NSOperationQueue alloc] init];
        _stx_sharedCircleImageOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
    
    return _stx_sharedCircleImageOperationQueue;
}

- (NSOperation *)stx_circleImageOperation
{
    return (NSOperation *)objc_getAssociatedObject(self, &kSTXCircleImageOperationKey);
}

- (void)stx_setCircleImageOperation:(NSOperation *)circleImageOperation
{
    objc_setAssociatedObject(self, &kSTXCircleImageOperationKey, circleImageOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIImageView (Masking)

+ (id<AFImageCache>)sharedImageCache {
    static STXImageCache *_stx_defaultImageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _stx_defaultImageCache = [[STXImageCache alloc] init];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * __unused notification) {
            [_stx_defaultImageCache removeAllObjects];
        }];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    return objc_getAssociatedObject(self, &kSTXSharedImageCacheKey) ?: _stx_defaultImageCache;
#pragma clang diagnostic pop
}

+ (void)setSharedImageCache:(id<AFImageCache>)imageCache {
    objc_setAssociatedObject(self, &kSTXSharedImageCacheKey, imageCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCircleImageWithURL:(NSURL *)imageURL placeholderImage:(UIImage *)placeholderImage
{
    [self setCircleImageWithURL:imageURL placeholderImage:placeholderImage borderWidth:3];
}

- (void)setCircleImageWithURL:(NSURL *)imageURL placeholderImage:(UIImage *)placeholderImage borderWidth:(CGFloat)borderWidth;
{
    [self cancelCircleImageOperation];
    
    [self addCircleMask];
    
    CGSize imageSize = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    
    __weak UIImageView *weakSelf = self;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
    UIImage *cachedImage = [[[self class] sharedImageCache] cachedImageForRequest:request];
    if (cachedImage) {
        self.image = cachedImage;
    } else {
        __block NSOperationQueue *circleImageOperationQueue = [[self class] stx_sharedCircleImageOperationQueue];
        id<AFImageCache> imageCache = [[self class] sharedImageCache];
        
        [self setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf.stx_circleImageOperation = [NSBlockOperation blockOperationWithBlock:^{
                UIImage *circledImage = [image circleBorderedAtWidth:borderWidth forImageWithSize:imageSize];
                [imageCache cacheImage:circledImage forRequest:request];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    strongSelf.image = circledImage;
                }];
            }];
            
            [circleImageOperationQueue addOperation:strongSelf.stx_circleImageOperation];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;

            if (strongSelf.image != nil) {
                return;
            }
            
            strongSelf.stx_circleImageOperation = [NSBlockOperation blockOperationWithBlock:^{
                UIImage *circledImage = [placeholderImage circleBorderedAtWidth:borderWidth forImageWithSize:imageSize];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    strongSelf.image = circledImage;
                }];
            }];
            
            [circleImageOperationQueue addOperation:strongSelf.stx_circleImageOperation];
        }];
    }
}

- (void)addCircleMask
{
    self.clipsToBounds = YES;
    
    self.backgroundColor = [UIColor whiteColor];
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.layer.cornerRadius = CGRectGetWidth(self.bounds)/2;
    self.layer.masksToBounds = YES;
}

- (void)cancelCircleImageOperation
{
    [self.stx_circleImageOperation cancel];
    self.stx_circleImageOperation = nil;
}

@end

#pragma mark - STXImageCache

@implementation STXImageCache

static inline NSString * STXImageCacheKeyFromURLRequest(NSURLRequest *request) {
    return [[request URL] absoluteString];
}

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
    switch ([request cachePolicy]) {
        case NSURLRequestReloadIgnoringCacheData:
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return nil;
        default:
            break;
    }

	return [self objectForKey:STXImageCacheKeyFromURLRequest(request)];
}

- (void)cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request
{
    if (image && request) {
        [self setObject:image forKey:STXImageCacheKeyFromURLRequest(request)];
    }
}

@end
