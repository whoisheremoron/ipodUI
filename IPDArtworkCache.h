// IPDArtworkCache.h — async artwork loader with NSCache backing
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPDArtworkCache : NSObject

+ (nonnull instancetype)shared;

/// Returns cached image immediately (may be nil), kicks async load, calls completion on main queue.
- (nullable UIImage *)artworkForItem:(nullable MPMediaItem *)item
                                size:(CGSize)size
                          completion:(nullable void(^)(UIImage * _Nullable img))completion;

- (void)purge;

@end

NS_ASSUME_NONNULL_END
