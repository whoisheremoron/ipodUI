// IPDMediaLibrary.h — preloads all MPMediaQuery results in background once
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface IPDMediaLibrary : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) BOOL isLoaded;

@property (nonatomic, readonly) NSArray<MPMediaItemCollection*> *albums;
@property (nonatomic, readonly) NSArray<MPMediaItemCollection*> *artists;
@property (nonatomic, readonly) NSArray<MPMediaItemCollection*> *playlists;
@property (nonatomic, readonly) NSArray<MPMediaItem*>           *songs;
@property (nonatomic, readonly) NSArray<MPMediaItemCollection*> *genres;

/// Start background load. Safe to call multiple times (no-op if already loading/loaded).
- (void)preloadWithCompletion:(void(^)(void))completion;

/// Convenience — same as preloadWithCompletion:nil
- (void)preloadIfNeeded;

@end
