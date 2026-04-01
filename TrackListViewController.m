#import "TrackListViewController.h"
#import "NowPlayingViewController.h"
#import "IPodLayout.h"
#import "IPDMenuCell.h"
#import "IPDArtworkCache.h"

@interface TrackListViewController()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)NSArray<MPMediaItem*>*tracks;
@property(nonatomic,strong)UITableView*table;
@property(nonatomic,strong)ClickWheelView*wheel;
@property(nonatomic,assign)NSInteger sel;
@property(nonatomic,assign)BOOL built;
@property(nonatomic,strong)UIImage*albumArt;
@end

@implementation TrackListViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=IPD_BODY_BG;
    self.tracks=self.collection.items?:@[];
    self.built=NO;
    self.albumArt=nil; // will load async below
    MPMediaItem*first=self.tracks.firstObject;
    if(first){
        CGSize sz=CGSizeMake(IPD_ROW_H-8,IPD_ROW_H-8);
        [[IPDArtworkCache shared] artworkForItem:first size:sz completion:^(UIImage*img){
            self.albumArt=img;
        }];
    }
}
-(void)viewDidLayoutSubviews{[super viewDidLayoutSubviews];if(self.built)return;self.built=YES;[self build];}

-(void)build {
    CGRect b=self.view.bounds; CGRect sr=IPDScreenRect(b);
    UIView*screen=IPDBuildScaffold(self.view);
    CGFloat sw=sr.size.width,sh=sr.size.height;

    // Header with album thumb
    UIView*hdr=[[UIView alloc]initWithFrame:CGRectMake(0,0,sw,IPD_HDR_H)];
    CAGradientLayer*g=[CAGradientLayer layer];g.frame=hdr.bounds;
    g.colors=@[(__bridge id)IPD_HDR_TOP.CGColor,(__bridge id)IPD_HDR_BOT.CGColor];
    g.locations=@[@0,@1];[hdr.layer addSublayer:g];
    CALayer*bl=[CALayer layer];bl.frame=CGRectMake(0,IPD_HDR_H-0.5f,sw,0.5f);
    bl.backgroundColor=IPD_HDR_BORDER.CGColor;[hdr.layer addSublayer:bl];

    // Thumb
    CGFloat ts=IPD_HDR_H-6;
    UIImageView*th=[[UIImageView alloc]initWithFrame:CGRectMake(3,(IPD_HDR_H-ts)/2,ts,ts)];
    th.contentMode=UIViewContentModeScaleAspectFill;th.clipsToBounds=YES;
    th.layer.cornerRadius=2;th.image=self.albumArt;
    th.backgroundColor=[UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1];
    if(!self.albumArt){UILabel*n=[[UILabel alloc]initWithFrame:th.bounds];n.text=@"♪";n.font=[UIFont systemFontOfSize:ts*0.6];n.textColor=[UIColor colorWithWhite:1 alpha:0.2];n.textAlignment=NSTextAlignmentCenter;[th addSubview:n];}
    [hdr addSubview:th];

    UILabel*ttl=[[UILabel alloc]initWithFrame:CGRectMake(ts+8,0,sw-ts-50,IPD_HDR_H)];
    ttl.text=self.listTitle?:@"Album";ttl.font=[UIFont boldSystemFontOfSize:13];
    ttl.textColor=IPD_HDR_TXT;ttl.backgroundColor=[UIColor clearColor];[hdr addSubview:ttl];

    // Battery
    CGFloat bx=sw-36;
    UIView*bo=[[UIView alloc]initWithFrame:CGRectMake(bx,8,24,13)];bo.layer.borderColor=[UIColor colorWithWhite:0.35 alpha:1].CGColor;bo.layer.borderWidth=1.2f;bo.layer.cornerRadius=2;bo.backgroundColor=[UIColor clearColor];[hdr addSubview:bo];
    UIView*bf=[[UIView alloc]initWithFrame:CGRectMake(bx+1,9,18,11)];bf.backgroundColor=[UIColor colorWithRed:0.2 green:0.75 blue:0.2 alpha:1];bf.layer.cornerRadius=1;[hdr addSubview:bf];
    UIView*bn=[[UIView alloc]initWithFrame:CGRectMake(bx+25,12,3,6)];bn.backgroundColor=[UIColor colorWithWhite:0.35 alpha:1];bn.layer.cornerRadius=1;[hdr addSubview:bn];
    [screen addSubview:hdr];

    self.table=[[UITableView alloc]initWithFrame:CGRectMake(0,IPD_HDR_H,sw,sh-IPD_HDR_H) style:UITableViewStylePlain];
    self.table.backgroundColor=IPD_SCREEN;self.table.separatorColor=IPD_SEP;
    self.table.separatorInset=UIEdgeInsetsZero;self.table.layoutMargins=UIEdgeInsetsZero;
    self.table.dataSource=self;self.table.delegate=self;
    self.table.rowHeight=IPD_ROW_H;self.table.showsVerticalScrollIndicator=YES;
    self.table.tableFooterView=[UIView new];[screen addSubview:self.table];

    if(self.tracks.count)[self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];

    self.wheel=[[ClickWheelView alloc]initWithFrame:IPDWheelRect(b)];
    self.wheel.delegate=self;[self.view addSubview:self.wheel];
}

-(NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s{return(NSInteger)self.tracks.count;}
-(UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)ip {
    IPDMenuCell*c=(IPDMenuCell*)[tv dequeueReusableCellWithIdentifier:@"t"];
    if(!c) c=[[IPDMenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"t"];
    MPMediaItem*item=self.tracks[ip.row];
    NSString*title=[item valueForProperty:MPMediaItemPropertyTitle]?:@"Unknown";
    NSNumber*dur=[item valueForProperty:MPMediaItemPropertyPlaybackDuration];
    NSString*sub=@"";
    if(dur&&dur.doubleValue>0) sub=[NSString stringWithFormat:@"%d:%02d",(int)dur.doubleValue/60,(int)dur.doubleValue%60];
    BOOL sel=(ip.row==self.sel);
    // Try cache first, kick async load if missing
    CGSize sz=CGSizeMake(IPD_ROW_H-8,IPD_ROW_H-8);
    UIImage*img=[[IPDArtworkCache shared] artworkForItem:item size:sz completion:^(UIImage*loaded){
        // Reload just this cell when image arrives
        IPDMenuCell*cell=(IPDMenuCell*)[tv cellForRowAtIndexPath:ip];
        if(cell) {
            cell.thumbView.image=loaded;
            cell.thumbView.hidden=(loaded==nil && sub.length==0);
            [cell setNeedsLayout];
        }
    }];
    if(!img) img=self.albumArt; // album-level fallback
    [c setTitle:title subtitle:sub artwork:img hasAction:YES selected:sel];
    return c;
}
-(void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)ip{self.sel=ip.row;[self play];}
-(void)moveTo:(NSInteger)i{
    NSInteger prev=self.sel;
    self.sel=MAX(0,MIN(i,(NSInteger)self.tracks.count-1));
    [self.table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.sel inSection:0]
                      atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    // O(1): only refresh the two affected rows
    [self refreshRow:prev];
    [self refreshRow:self.sel];
    [self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.sel inSection:0]
                            animated:NO scrollPosition:UITableViewScrollPositionNone];
}
-(void)refreshRow:(NSInteger)i {
    if(i<0||i>=(NSInteger)self.tracks.count) return;
    NSIndexPath*ip=[NSIndexPath indexPathForRow:i inSection:0];
    IPDMenuCell*c=(IPDMenuCell*)[self.table cellForRowAtIndexPath:ip];
    if(!c) return;
    MPMediaItem*item=self.tracks[i];
    NSString*title=[item valueForProperty:MPMediaItemPropertyTitle]?:@"Unknown";
    NSNumber*dur=[item valueForProperty:MPMediaItemPropertyPlaybackDuration];
    NSString*sub=dur&&dur.doubleValue>0
        ? [NSString stringWithFormat:@"%d:%02d",(int)dur.doubleValue/60,(int)dur.doubleValue%60]
        : @"";
    CGSize sz=CGSizeMake(IPD_ROW_H-8,IPD_ROW_H-8);
    UIImage*img=[[IPDArtworkCache shared] artworkForItem:item size:sz completion:nil]?:self.albumArt;
    [c setTitle:title subtitle:sub artwork:img hasAction:YES selected:(i==self.sel)];
}
-(void)sync{
    // Full reload — called only after items set or table reload
    [self.table reloadData];
    if(self.tracks.count)
        [self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.sel inSection:0]
                                animated:NO scrollPosition:UITableViewScrollPositionNone];
}
-(void)play{
    if(!self.collection||self.sel>=(NSInteger)self.tracks.count)return;
    IPDHaptic();
    MPMusicPlayerController*p=MPMusicPlayerController.systemMusicPlayer;
    MPMusicPlayerMediaItemQueueDescriptor*d=[[MPMusicPlayerMediaItemQueueDescriptor alloc]initWithItemCollection:self.collection];
    d.startItem=self.tracks[self.sel];[p setQueueWithDescriptor:d];[p play];
    [self.navigationController pushViewController:[NowPlayingViewController new] animated:YES];
}
-(void)wheelDidTrigger:(WheelAction)a{
    switch(a){
        case WheelActionScrollUp:case WheelActionPrev:if(self.sel>0)[self moveTo:self.sel-1];break;
        case WheelActionScrollDown:case WheelActionNext:if(self.sel<(NSInteger)self.tracks.count-1)[self moveTo:self.sel+1];break;
        case WheelActionPlayPause:{MPMusicPlayerController*p=MPMusicPlayerController.systemMusicPlayer;p.playbackState==MPMusicPlaybackStatePlaying?[p pause]:[p play];break;}
        case WheelActionCenter:[self play];break;
        case WheelActionMenu:[self.navigationController popViewControllerAnimated:YES];break;
        default:break;
    }
}
@end
