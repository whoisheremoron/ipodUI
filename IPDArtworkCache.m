// IPDArtworkCache.m
#import "IPDArtworkCache.h"

@interface IPDArtworkCache ()
@property (nonatomic, strong) NSCache<NSString*, UIImage*> *cache;
@property (nonatomic, strong) NSMutableSet<NSString*>      *inFlight; // keys being loaded
@property (nonatomic, strong) dispatch_queue_t              queue;
@end

@implementation IPDArtworkCache

+ (instancetype)shared {
    static IPDArtworkCache *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [IPDArtworkCache new]; });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    self.cache    = [NSCache new];
    self.cache.countLimit    = 300;   // max 300 thumbnails in memory
    self.cache.totalCostLimit = 1024 * 1024 * 40; // ~40 MB
    self.inFlight = [NSMutableSet new];
    self.queue    = dispatch_queue_create("com.ipod.artwork", DISPATCH_QUEUE_SERIAL);
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(purge)
        name:UIApplicationDidReceiveMemoryWarningNotification
        object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)keyForItem:(MPMediaItem *)item size:(CGSize)size {
    MPMediaEntityPersistentID pid = [item valueForProperty:MPMediaItemPropertyPersistentID]
                                        ? [[item valueForProperty:MPMediaItemPropertyPersistentID] unsignedLongLongValue]
                                        : 0;
    return [NSString stringWithFormat:@"%llu_%.0fx%.0f", (unsigned long long)pid, size.width, size.height];
}

- (nullable UIImage *)artworkForItem:(MPMediaItem *)item
                                size:(CGSize)size
                          completion:(void(^)(UIImage * _Nullable))completion {
    if (!item) {
        if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
        return nil;
    }

    NSString *key = [self keyForItem:item size:size];

    // 1. Cache hit — return immediately
    UIImage *cached = [self.cache objectForKey:key];
    if (cached) {
        if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(cached); });
        return cached;
    }

    // 2. Already loading — just register completion to be called when done
    //    (simple approach: re-check cache after a short delay via a serial queue)
    if (!completion) return nil;

    // 3. Kick off background load
    dispatch_async(self.queue, ^{
        // Double-check inside serial queue
        UIImage *img = [self.cache objectForKey:key];
        if (!img) {
            MPMediaItemArtwork *art = [item valueForProperty:MPMediaItemPropertyArtwork];
            if (art) {
                img = [art imageWithSize:size];
                if (img) {
                    NSUInteger cost = (NSUInteger)(size.width * size.height * 4);
                    [self.cache setObject:img forKey:key cost:cost];
                }
            }
        }
        UIImage *result = img; // capture
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result);
        });
    });

    return nil;
}

- (void)purge {
    [self.cache removeAllObjects];
}

@end
