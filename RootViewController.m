#import "RootViewController.h"
#import "IPodLayout.h"
#import "MenuViewController.h"
#import "NowPlayingViewController.h"
#import "TrackListViewController.h"
#import "SettingsViewController.h"
#import "CoverFlowViewController.h"
#import "IPDMediaLibrary.h"
#import "IPDArtworkCache.h"
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>

static CGSize const kThumbSize = {36, 36}; // IPD_ROW_H-8

// ── Animator: slide only within the screen rect ───────────────────────────
@interface IPDSlideAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property(nonatomic,assign) BOOL pushing;
@end
@implementation IPDSlideAnimator
-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)ctx{return 0.22;}
-(void)animateTransition:(id<UIViewControllerContextTransitioning>)ctx {
    UIViewController*from=[ctx viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController*to  =[ctx viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView*container=[ctx containerView];

    // We animate only the *screen* subview of each VC's view.
    // Screen is always the second subview (index 1: bezel at 0, screen at 1)
    // but to be safe we find it by its background color / position.
    UIView*fromScreen=[self screenIn:from.view];
    UIView*toScreen  =[self screenIn:to.view];

    // Ensure both VCs' views fill the container
    from.view.frame=container.bounds;
    to.view.frame=container.bounds;
    [container addSubview:to.view];

    if(!fromScreen||!toScreen){
        // Fallback: no animation
        [ctx completeTransition:YES]; return;
    }

    CGFloat sw=fromScreen.bounds.size.width;
    CGFloat dir=self.pushing?1:-1;

    // Start position for incoming screen
    CGRect toStart=toScreen.frame;
    toStart.origin.x+=sw*dir;
    toScreen.frame=toStart;

    CGRect fromEnd=fromScreen.frame;
    fromEnd.origin.x-=sw*dir;

    [UIView animateWithDuration:[self transitionDuration:ctx]
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        toScreen.frame=CGRectOffset(toStart,-sw*dir,0);
        fromScreen.frame=fromEnd;
    } completion:^(BOOL fin){
        fromScreen.frame=CGRectOffset(fromEnd,sw*dir,0); // restore
        [ctx completeTransition:fin];
    }];
}
-(UIView*)screenIn:(UIView*)root {
    // Screen is the UIView with white background and cornerRadius clipped
    for(UIView*v in root.subviews)
        if(v.clipsToBounds && v.layer.cornerRadius>0) return v;
    // fallback
    return root.subviews.count>1 ? root.subviews[1] : nil;
}
@end

// ── Nav delegate ──────────────────────────────────────────────────────────
@interface IPDNavDelegate : NSObject <UINavigationControllerDelegate>
@end
@implementation IPDNavDelegate
-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController*)nav
                                 animationControllerForOperation:(UINavigationControllerOperation)op
                                              fromViewController:(UIViewController*)from
                                                toViewController:(UIViewController*)to {
    IPDSlideAnimator*a=[IPDSlideAnimator new];
    a.pushing=(op==UINavigationControllerOperationPush);
    return a;
}
@end

@implementation RootViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    // Embed nav inside self
    MenuViewController*root=[[MenuViewController alloc]init];
    root.menuTitle=@"iPod";
    root.items=[self mainItems];
    UINavigationController*nav=[[UINavigationController alloc]initWithRootViewController:root];
    nav.navigationBarHidden=YES;
    nav.view.frame=self.view.bounds;
    nav.view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    // Custom transition: slide only within screen rect
    IPDNavDelegate*nd=[IPDNavDelegate new];
    nav.delegate=nd;
    objc_setAssociatedObject(self, "navDelegate", nd, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addChildViewController:nav]; [self.view addSubview:nav.view]; [nav didMoveToParentViewController:self];
}

-(NSArray<MenuItem*>*)mainItems {
    return @[
        [MenuItem title:@"Cover Flow" action:^(UINavigationController*nav){
            IPDHaptic(); [nav pushViewController:[CoverFlowViewController new] animated:YES];
        }],
        [MenuItem title:@"Music" action:^(UINavigationController*nav){
            [self showMusicMenu:nav];
        }],
        [MenuItem title:@"Settings" action:^(UINavigationController*nav){
            IPDHaptic(); [nav pushViewController:[SettingsViewController new] animated:YES];
        }],
        [MenuItem title:@"Now Playing" action:^(UINavigationController*nav){
            IPDHaptic(); [nav pushViewController:[NowPlayingViewController new] animated:YES];
        }],
    ];
}

-(void)showMusicMenu:(UINavigationController*)nav {
    MenuViewController*vc=[[MenuViewController alloc]init];
    vc.menuTitle=@"Music";
    vc.items=@[
        [MenuItem title:@"All Songs" action:^(UINavigationController*nav){
            IPDHaptic();
            MPMusicPlayerController*p=MPMusicPlayerController.systemMusicPlayer;
            [p setQueueWithQuery:[MPMediaQuery songsQuery]]; [p play];
            [nav pushViewController:[NowPlayingViewController new] animated:YES];
        }],
        [MenuItem title:@"Albums"    action:^(UINavigationController*nav){[self showAlbums:nav];}],
        [MenuItem title:@"Artists"   action:^(UINavigationController*nav){[self showArtists:nav];}],
        [MenuItem title:@"Playlists" action:^(UINavigationController*nav){[self showPlaylists:nav];}],
        [MenuItem title:@"Songs"     action:^(UINavigationController*nav){[self showSongs:nav];}],
        [MenuItem title:@"Genres"    action:^(UINavigationController*nav){[self showGenres:nav];}],
    ];
    [nav pushViewController:vc animated:YES];
}

// ── Helper: push a MenuVC with a loading placeholder, build items async ────
-(void)pushAsyncMenu:(NSString*)title nav:(UINavigationController*)nav
               build:(void(^)(void(^done)(NSArray<MenuItem*>*)))builder {
    MenuViewController*vc=[[MenuViewController alloc]init];
    vc.menuTitle=title;
    vc.items=@[[MenuItem title:@"Loading…" action:nil]];
    [nav pushViewController:vc animated:YES];
    builder(^(NSArray<MenuItem*>*items){
        dispatch_async(dispatch_get_main_queue(),^{
            vc.items=items.count?items:@[[MenuItem title:[NSString stringWithFormat:@"No %@",title] action:nil]];
            [vc.table reloadData];
            if(vc.items.count)[vc.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                    animated:NO scrollPosition:UITableViewScrollPositionNone];
        });
    });
}

// ── Albums ─────────────────────────────────────────────────────────────────
-(void)showAlbums:(UINavigationController*)nav {
    [self pushAsyncMenu:@"Albums" nav:nav build:^(void(^done)(NSArray<MenuItem*>*)){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSArray*collections=[IPDMediaLibrary shared].isLoaded
                ? [IPDMediaLibrary shared].albums
                : [MPMediaQuery albumsQuery].collections ?: @[];
            NSMutableArray*items=[NSMutableArray arrayWithCapacity:collections.count];
            for(MPMediaItemCollection*album in collections){
                MPMediaItem*rep=album.representativeItem;
                NSString*name=[rep valueForProperty:MPMediaItemPropertyAlbumTitle]?:@"Unknown";
                NSString*artist=[rep valueForProperty:MPMediaItemPropertyArtist]?:@"";
                MPMediaItemCollection*c=album;
                MenuItem*mi=[MenuItem title:name subtitle:artist artwork:nil action:^(UINavigationController*n){
                    IPDHaptic();
                    TrackListViewController*tl=[TrackListViewController new];
                    tl.collection=c; tl.listTitle=name; [n pushViewController:tl animated:YES];
                }];
                // Async artwork — set nil now, load in bg
                [[IPDArtworkCache shared] artworkForItem:rep size:kThumbSize completion:^(UIImage*img){
                    mi.artworkImage=img; if(mi.onArtworkLoaded)mi.onArtworkLoaded();
                }];
                [items addObject:mi];
            }
            done(items);
        });
    }];
}

// ── Artists ────────────────────────────────────────────────────────────────
-(void)showArtists:(UINavigationController*)nav {
    [self pushAsyncMenu:@"Artists" nav:nav build:^(void(^done)(NSArray<MenuItem*>*)){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSArray*collections=[IPDMediaLibrary shared].isLoaded
                ? [IPDMediaLibrary shared].artists
                : [MPMediaQuery artistsQuery].collections ?: @[];
            NSMutableArray*items=[NSMutableArray arrayWithCapacity:collections.count];
            for(MPMediaItemCollection*a in collections){
                MPMediaItem*rep=a.representativeItem;
                NSString*name=[rep valueForProperty:MPMediaItemPropertyArtist]?:@"Unknown";
                MPMediaItemCollection*captured=a;
                MenuItem*mi=[MenuItem title:name subtitle:nil artwork:nil action:^(UINavigationController*n){
                    IPDHaptic(); [self showArtistAlbums:name collection:captured nav:n];
                }];
                [[IPDArtworkCache shared] artworkForItem:rep size:kThumbSize completion:^(UIImage*img){
                    mi.artworkImage=img; if(mi.onArtworkLoaded)mi.onArtworkLoaded();
                }];
                [items addObject:mi];
            }
            done(items);
        });
    }];
}

-(void)showArtistAlbums:(NSString*)artist collection:(MPMediaItemCollection*)col nav:(UINavigationController*)nav {
    NSMutableDictionary<NSString*,NSMutableArray*>*dict=[NSMutableDictionary dictionary];
    NSMutableArray*order=[NSMutableArray array];
    for(MPMediaItem*item in col.items){
        NSString*album=[item valueForProperty:MPMediaItemPropertyAlbumTitle]?:@"Unknown Album";
        if(!dict[album]){dict[album]=[NSMutableArray array];[order addObject:album];}
        [dict[album] addObject:item];
    }
    [self pushAsyncMenu:artist nav:nav build:^(void(^done)(NSArray<MenuItem*>*)){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSMutableArray*items=[NSMutableArray array];
            [items addObject:[MenuItem title:@"All Songs" action:^(UINavigationController*n){
                IPDHaptic();
                TrackListViewController*tl=[TrackListViewController new];
                tl.collection=col; tl.listTitle=artist; [n pushViewController:tl animated:YES];
            }]];
            for(NSString*album in order){
                MPMediaItemCollection*ac=[MPMediaItemCollection collectionWithItems:dict[album]];
                NSString*cap=album;
                MenuItem*mi=[MenuItem title:cap subtitle:nil artwork:nil action:^(UINavigationController*n){
                    IPDHaptic();
                    TrackListViewController*tl=[TrackListViewController new];
                    tl.collection=ac; tl.listTitle=cap; [n pushViewController:tl animated:YES];
                }];
                [[IPDArtworkCache shared] artworkForItem:ac.representativeItem size:kThumbSize completion:^(UIImage*img){
                    mi.artworkImage=img; if(mi.onArtworkLoaded)mi.onArtworkLoaded();
                }];
                [items addObject:mi];
            }
            done(items);
        });
    }];
}

// ── Playlists ──────────────────────────────────────────────────────────────
-(void)showPlaylists:(UINavigationController*)nav {
    [self pushAsyncMenu:@"Playlists" nav:nav build:^(void(^done)(NSArray<MenuItem*>*)){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSArray*collections=[IPDMediaLibrary shared].isLoaded
                ? [IPDMediaLibrary shared].playlists
                : [MPMediaQuery playlistsQuery].collections ?: @[];
            NSMutableArray*items=[NSMutableArray arrayWithCapacity:collections.count];
            for(MPMediaItemCollection*pl in collections){
                NSString*name=([pl isKindOfClass:[MPMediaPlaylist class]]?((MPMediaPlaylist*)pl).name:nil)?:@"Untitled";
                MPMediaItem*first=pl.items.firstObject;
                MPMediaItemCollection*cap=pl;
                MenuItem*mi=[MenuItem title:name subtitle:@"" artwork:nil action:^(UINavigationController*n){
                    IPDHaptic();
                    MPMediaItemCollection*c=[MPMediaItemCollection collectionWithItems:cap.items];
                    TrackListViewController*tl=[TrackListViewController new];
                    tl.collection=c; tl.listTitle=name; [n pushViewController:tl animated:YES];
                }];
                [[IPDArtworkCache shared] artworkForItem:first size:kThumbSize completion:^(UIImage*img){
                    mi.artworkImage=img; if(mi.onArtworkLoaded)mi.onArtworkLoaded();
                }];
                [items addObject:mi];
            }
            done(items);
        });
    }];
}

// ── Songs ──────────────────────────────────────────────────────────────────
-(void)showSongs:(UINavigationController*)nav {
    [self pushAsyncMenu:@"Songs" nav:nav build:^(void(^done)(NSArray<MenuItem*>*)){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSArray*songs=[IPDMediaLibrary shared].isLoaded
                ? [IPDMediaLibrary shared].songs
                : [MPMediaQuery songsQuery].items ?: @[];
            MPMediaItemCollection*all=[MPMediaItemCollection collectionWithItems:songs];
            NSMutableArray*items=[NSMutableArray arrayWithCapacity:songs.count];
            for(NSUInteger i=0;i<songs.count;i++){
                MPMediaItem*song=songs[i]; NSUInteger idx=i;
                NSString*title=[song valueForProperty:MPMediaItemPropertyTitle]?:@"Unknown";
                NSString*artist=[song valueForProperty:MPMediaItemPropertyArtist]?:@"";
                MenuItem*mi=[MenuItem title:title subtitle:artist artwork:nil action:^(UINavigationController*n){
                    IPDHaptic();
                    MPMusicPlayerController*p=MPMusicPlayerController.systemMusicPlayer;
                    MPMusicPlayerMediaItemQueueDescriptor*d=[[MPMusicPlayerMediaItemQueueDescriptor alloc]initWithItemCollection:all];
                    d.startItem=songs[idx]; [p setQueueWithDescriptor:d]; [p play];
                    [n pushViewController:[NowPlayingViewController new] animated:YES];
                }];
                [[IPDArtworkCache shared] artworkForItem:song size:kThumbSize completion:^(UIImage*img){
                    mi.artworkImage=img; if(mi.onArtworkLoaded)mi.onArtworkLoaded();
                }];
                [items addObject:mi];
            }
            done(items);
        });
    }];
}

// ── Genres ─────────────────────────────────────────────────────────────────
-(void)showGenres:(UINavigationController*)nav {
    [self pushAsyncMenu:@"Genres" nav:nav build:^(void(^done)(NSArray<MenuItem*>*)){
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
            NSArray*collections=[IPDMediaLibrary shared].isLoaded
                ? [IPDMediaLibrary shared].genres
                : [MPMediaQuery genresQuery].collections ?: @[];
            NSMutableArray*items=[NSMutableArray arrayWithCapacity:collections.count];
            for(MPMediaItemCollection*g in collections){
                MPMediaItem*rep=g.representativeItem;
                NSString*name=[rep valueForProperty:MPMediaItemPropertyGenre]?:@"Unknown";
                MPMediaItemCollection*cap=g;
                [items addObject:[MenuItem title:name action:^(UINavigationController*n){
                    IPDHaptic();
                    TrackListViewController*tl=[TrackListViewController new];
                    tl.collection=cap; tl.listTitle=name; [n pushViewController:tl animated:YES];
                }]];
            }
            done(items);
        });
    }];
}
@end
