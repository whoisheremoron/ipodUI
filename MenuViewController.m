// MenuViewController.m — tannerv-style split layout on main, full-list on submenus
// Main menu (iPod): LEFT=list (50%), RIGHT=now-playing artwork
#import <MediaPlayer/MediaPlayer.h>
// Submenus: full-width list with artwork rows
#import "MenuViewController.h"
#import "IPodLayout.h"
#import "IPDMenuCell.h"
#import "IPDArtworkCache.h"

@implementation MenuItem
+(instancetype)title:(NSString*)t action:(void(^)(UINavigationController*))a {
    MenuItem*i=[MenuItem new];i.title=t;i.action=a;return i;
}
+(instancetype)title:(NSString*)t subtitle:(NSString*)sub artwork:(UIImage*)art action:(void(^)(UINavigationController*))a {
    MenuItem*i=[MenuItem new];i.title=t;i.subtitle=sub;i.artworkImage=art;i.action=a;return i;
}
@end

@interface MenuViewController()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)UIView*screen;
@property(nonatomic,strong)UIImageView*nowArtwork;
@property(nonatomic,strong)ClickWheelView*wheel;
@property(nonatomic,assign)NSInteger sel;
@property(nonatomic,assign)BOOL built;
@property(nonatomic,strong)MPMusicPlayerController*player;
@end

@implementation MenuViewController

-(void)setItems:(NSArray<MenuItem*>*)items {
    _items=items;
    // Wire up async artwork callbacks — each one reloads only its own row
    __weak MenuViewController*weakSelf=self;
    for(NSUInteger i=0;i<items.count;i++){
        NSUInteger idx=i;
        items[i].onArtworkLoaded=^{
            MenuViewController*s=weakSelf; if(!s||!s.table) return;
            NSIndexPath*ip=[NSIndexPath indexPathForRow:(NSInteger)idx inSection:0];
            if(idx<(NSUInteger)s.items.count)
                [s.table reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
        };
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=IPD_BODY_BG;
    self.sel=0; self.built=NO;
    self.player=MPMusicPlayerController.systemMusicPlayer;
}
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; if(self.built)return; self.built=YES; [self build];
}
-(void)viewWillAppear:(BOOL)a {
    [super viewWillAppear:a];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateArtwork)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.player];
    [self.player beginGeneratingPlaybackNotifications];
    [self updateArtwork];
    // Update header play state
    [self updateHeaderPlayState];
}
-(void)viewWillDisappear:(BOOL)a {
    [super viewWillDisappear:a];
    [self.player endGeneratingPlaybackNotifications];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.player];
}

-(BOOL)isRoot { return [self.menuTitle isEqualToString:@"iPod"] || self.menuTitle==nil; }

-(void)build {
    CGRect b=self.view.bounds;
    CGRect sr=IPDScreenRect(b);
    self.screen=IPDBuildScaffold(self.view);
    CGFloat sw=sr.size.width, sh=sr.size.height;

    // Header
    UILabel *li=nil;
    UIView*hdr=IPDHeader(sw, self.menuTitle?:@"iPod", nil, &li);
    if([self isRoot]) li.text=@"";  // no back arrow on root
    [self.screen addSubview:hdr];

    CGFloat ty=IPD_HDR_H;

    if ([self isRoot]) {
        // ── Root: split layout — list LEFT 52%, artwork RIGHT 48% ──────────
        CGFloat listW = floorf(sw * 0.52f);
        CGFloat artW  = sw - listW;

        self.table=[[UITableView alloc]initWithFrame:CGRectMake(0,ty,listW,sh-ty) style:UITableViewStylePlain];
        [self setupTable:self.table width:listW];
        [self.screen addSubview:self.table];

        // Right artwork panel
        UIView*artPanel=[[UIView alloc]initWithFrame:CGRectMake(listW,ty,artW,sh-ty)];
        artPanel.backgroundColor=[UIColor colorWithWhite:0.05 alpha:1];
        [self.screen addSubview:artPanel];

        self.nowArtwork=[[UIImageView alloc]initWithFrame:artPanel.bounds];
        self.nowArtwork.contentMode=UIViewContentModeScaleAspectFill;
        self.nowArtwork.clipsToBounds=YES;
        [artPanel addSubview:self.nowArtwork];

        // Vertical divider
        UIView*div=[[UIView alloc]initWithFrame:CGRectMake(listW-0.5f,ty,0.5f,sh-ty)];
        div.backgroundColor=IPD_SEP; [self.screen addSubview:div];

    } else {
        // ── Submenus: full width list ─────────────────────────────────────
        self.table=[[UITableView alloc]initWithFrame:CGRectMake(0,ty,sw,sh-ty) style:UITableViewStylePlain];
        [self setupTable:self.table width:sw];
        [self.screen addSubview:self.table];
    }

    if(self.items.count)
        [self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                animated:NO scrollPosition:UITableViewScrollPositionNone];

    self.wheel=[[ClickWheelView alloc]initWithFrame:IPDWheelRect(b)];
    self.wheel.delegate=self; [self.view addSubview:self.wheel];
}

-(void)setupTable:(UITableView*)tv width:(CGFloat)w {
    tv.backgroundColor=IPD_SCREEN; tv.separatorColor=IPD_SEP;
    tv.separatorInset=UIEdgeInsetsZero; tv.layoutMargins=UIEdgeInsetsZero;
    tv.dataSource=self; tv.delegate=self;
    tv.scrollEnabled=NO; tv.rowHeight=IPD_ROW_H;
    tv.showsVerticalScrollIndicator=NO; tv.tableFooterView=[UIView new];
}

-(void)updateArtwork {
    if(!self.nowArtwork) return;
    MPMediaItem*item=self.player.nowPlayingItem;
    if(!item){ self.nowArtwork.image=nil; self.nowArtwork.backgroundColor=[UIColor colorWithWhite:0.05 alpha:1]; return; }
    CGSize sz=self.nowArtwork.bounds.size;
    UIImage*cached=[[IPDArtworkCache shared] artworkForItem:item size:sz completion:^(UIImage*img){
        self.nowArtwork.image=img;
        self.nowArtwork.backgroundColor=[UIColor colorWithWhite:img?0:0.05 alpha:1];
    }];
    self.nowArtwork.image=cached;
    self.nowArtwork.backgroundColor=[UIColor colorWithWhite:cached?0:0.05 alpha:1];
}

-(void)updateHeaderPlayState {
    // Update ⏸/▶ in header
    UILabel*ps=(UILabel*)[self.screen.subviews.firstObject viewWithTag:77];
    if(!ps) return;
    BOOL pl=self.player.playbackState==MPMusicPlaybackStatePlaying;
    ps.text=pl?@"▶":@"⏸";
}

#pragma mark - Table

-(NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s { return(NSInteger)self.items.count; }

-(UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)ip {
    IPDMenuCell*c=(IPDMenuCell*)[tv dequeueReusableCellWithIdentifier:@"m"];
    if(!c) c=[[IPDMenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"m"];
    MenuItem*item=self.items[ip.row];
    [c setTitle:item.title subtitle:item.subtitle artwork:item.artworkImage
      hasAction:(item.action!=nil) selected:(ip.row==self.sel)];
    return c;
}

-(void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)ip {
    NSInteger prev=self.sel;
    self.sel=ip.row;
    [self refreshRow:prev];
    [self refreshRow:self.sel];
    MenuItem*item=self.items[ip.row];
    if(item.action){IPDHaptic();item.action(self.navigationController);}
}

-(void)moveTo:(NSInteger)i {
    NSInteger prev=self.sel;
    NSInteger n=(NSInteger)self.items.count;
    self.sel=MAX(0,MIN(i,n-1));
    [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.sel inSection:0]
                      atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [self refreshRow:prev];
    [self refreshRow:self.sel];
    [self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.sel inSection:0]
                            animated:NO scrollPosition:UITableViewScrollPositionNone];
}
-(void)refreshRow:(NSInteger)i {
    if(i<0||i>=(NSInteger)self.items.count) return;
    NSIndexPath*ip=[NSIndexPath indexPathForRow:i inSection:0];
    IPDMenuCell*c=(IPDMenuCell*)[self.table cellForRowAtIndexPath:ip];
    if(!c) return;
    MenuItem*item=self.items[i];
    [c setTitle:item.title subtitle:item.subtitle artwork:item.artworkImage
      hasAction:(item.action!=nil) selected:(i==self.sel)];
}
-(void)sync {
    [self.table reloadData];
    if(self.items.count)
        [self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.sel inSection:0]
                                animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - Wheel
-(void)wheelDidTrigger:(WheelAction)a {
    NSInteger n=(NSInteger)self.items.count;
    switch(a){
        case WheelActionScrollUp:case WheelActionPrev:
            if(self.sel>0)[self moveTo:self.sel-1]; break;
        case WheelActionScrollDown:case WheelActionNext:
            if(self.sel<n-1)[self moveTo:self.sel+1]; break;
        case WheelActionCenter:{
            MenuItem*item=self.items[self.sel];
            if(item.action){IPDHaptic();item.action(self.navigationController);}break;}
        case WheelActionPlayPause:
            // Play/pause works from any menu
            if(self.player.playbackState==MPMusicPlaybackStatePlaying)[self.player pause];
            else[self.player play];
            [self updateHeaderPlayState]; break;
        case WheelActionMenu:
            [self.navigationController popViewControllerAnimated:YES]; break;
        default:break;
    }
}
@end
