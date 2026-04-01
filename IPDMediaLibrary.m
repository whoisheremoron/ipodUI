// IPDMediaLibrary.m
#import "IPDMediaLibrary.h"

typedef NS_ENUM(NSInteger, IPDLibraryState) {
    IPDLibraryStateIdle,
    IPDLibraryStateLoading,
    IPDLibraryStateLoaded,
};

@interface IPDMediaLibrary ()
@property (nonatomic, assign) IPDLibraryState state;
@property (nonatomic, strong) NSMutableArray<void(^)(void)> *pendingCallbacks;

@property (nonatomic, strong) NSArray<MPMediaItemCollection*> *_albums;
@property (nonatomic, strong) NSArray<MPMediaItemCollection*> *_artists;
@property (nonatomic, strong) NSArray<MPMediaItemCollection*> *_playlists;
@property (nonatomic, strong) NSArray<MPMediaItem*>           *_songs;
@property (nonatomic, strong) NSArray<MPMediaItemCollection*> *_genres;
@end

@implementation IPDMediaLibrary

+ (instancetype)shared {
    static IPDMediaLibrary *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [IPDMediaLibrary new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    self.state = IPDLibraryStateIdle;
    self.pendingCallbacks = [NSMutableArray new];
    return self;
}

- (BOOL)isLoaded { return self.state == IPDLibraryStateLoaded; }

- (NSArray<MPMediaItemCollection*>*)albums   { return self._albums   ?: @[]; }
- (NSArray<MPMediaItemCollection*>*)artists  { return self._artists  ?: @[]; }
- (NSArray<MPMediaItemCollection*>*)playlists{ return self._playlists?: @[]; }
- (NSArray<MPMediaItem*>*)songs              { return self._songs    ?: @[]; }
- (NSArray<MPMediaItemCollection*>*)genres   { return self._genres   ?: @[]; }

- (void)preloadIfNeeded {
    [self preloadWithCompletion:nil];
}

- (void)preloadWithCompletion:(void(^)(void))completion {
    @synchronized(self) {
        if (self.state == IPDLibraryStateLoaded) {
            if (completion) dispatch_async(dispatch_get_main_queue(), completion);
            return;
        }
        if (completion) [self.pendingCallbacks addObject:completion];
        if (self.state == IPDLibraryStateLoading) return;
        self.state = IPDLibraryStateLoading;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // All MPMediaQuery calls are blocking — do them all here in background
        NSArray *albums    = [MPMediaQuery albumsQuery].collections    ?: @[];
        NSArray *artists   = [MPMediaQuery artistsQuery].collections   ?: @[];
        NSArray *playlists = [MPMediaQuery playlistsQuery].collections ?: @[];
        NSArray *songs     = [MPMediaQuery songsQuery].items           ?: @[];
        NSArray *genres    = [MPMediaQuery genresQuery].collections    ?: @[];

        dispatch_async(dispatch_get_main_queue(), ^{
            self._albums    = albums;
            self._artists   = artists;
            self._playlists = playlists;
            self._songs     = songs;
            self._genres    = genres;

            @synchronized(self) { self.state = IPDLibraryStateLoaded; }

            NSArray *cbs = [self.pendingCallbacks copy];
            [self.pendingCallbacks removeAllObjects];
            for (void(^cb)(void) in cbs) cb();
        });
    });
}

@end
