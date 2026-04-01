// CoverFlowViewController.m
// Exact tannerv Cover Flow: dark background, 3D angled covers left/right,
// center cover large + upright, reflection below, album+artist below that.
#import "CoverFlowViewController.h"
#import "IPodLayout.h"
#import "NowPlayingViewController.h"

#define CF_BG [UIColor colorWithRed:0.06 green:0.06 blue:0.08 alpha:1]

@interface CoverFlowViewController ()<UIScrollViewDelegate>
@property(nonatomic,strong)NSArray<MPMediaItemCollection*>*albums;
@property(nonatomic,strong)NSMutableArray<UIImageView*>*covers;
@property(nonatomic,strong)UIView*cfView;        // dark cover flow area
@property(nonatomic,strong)UILabel*titleLbl;
@property(nonatomic,strong)UILabel*artistLbl;
@property(nonatomic,strong)ClickWheelView*wheel;
@property(nonatomic,assign)NSInteger cur;        // current album index
@property(nonatomic,assign)BOOL built;
@end

@implementation CoverFlowViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor=IPD_BODY_BG;
    self.cur=0; self.built=NO;
    // Load albums in background
    dispatch_async(dispatch_get_global_queue(0,0),^{
        MPMediaQuery*q=[MPMediaQuery albumsQuery];
        NSArray*c=q.collections;
        dispatch_async(dispatch_get_main_queue(),^{
            self.albums=c;
            [self buildCovers];
            [self layoutCovers:NO];
        });
    });
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; if(self.built)return; self.built=YES; [self buildUI];
}

-(void)buildUI {
    CGRect b=self.view.bounds;
    CGRect sr=IPDScreenRect(b);
    UIView*screen=IPDBuildScaffold(self.view);
    CGFloat sw=sr.size.width,sh=sr.size.height;

    // Header
    UILabel*li=nil;
    UIView*hdr=IPDHeader(sw,@"Cover Flow",nil,&li);
    [screen addSubview:hdr];

    // Cover flow area (dark, below header)
    self.cfView=[[UIView alloc]initWithFrame:CGRectMake(0,IPD_HDR_H,sw,sh-IPD_HDR_H)];
    self.cfView.backgroundColor=CF_BG;
    self.cfView.clipsToBounds=YES;
    [screen addSubview:self.cfView];

    // Album title + artist (bottom of screen)
    self.titleLbl=[[UILabel alloc]initWithFrame:CGRectMake(4,sh-IPD_HDR_H-26,sw-8,16)];
    self.titleLbl.font=[UIFont boldSystemFontOfSize:12];
    self.titleLbl.textColor=[UIColor whiteColor];
    self.titleLbl.textAlignment=NSTextAlignmentCenter;
    self.titleLbl.backgroundColor=[UIColor clearColor];
    [screen addSubview:self.titleLbl];

    self.artistLbl=[[UILabel alloc]initWithFrame:CGRectMake(4,sh-IPD_HDR_H-12,sw-8,12)];
    self.artistLbl.font=[UIFont systemFontOfSize:10];
    self.artistLbl.textColor=[UIColor colorWithWhite:0.65 alpha:1];
    self.artistLbl.textAlignment=NSTextAlignmentCenter;
    self.artistLbl.backgroundColor=[UIColor clearColor];
    [screen addSubview:self.artistLbl];

    self.wheel=[[ClickWheelView alloc]initWithFrame:IPDWheelRect(b)];
    self.wheel.delegate=self; [self.view addSubview:self.wheel];

    [self buildCovers];
    [self layoutCovers:NO];
}

-(void)buildCovers {
    if(!self.cfView||!self.albums.count) return;
    // Remove old covers
    for(UIImageView*v in self.covers) [v removeFromSuperview];
    self.covers=[NSMutableArray array];

    // Create cover image views
    NSInteger count=MIN((NSInteger)self.albums.count, 60); // cap for performance
    for(NSInteger i=0;i<count;i++){
        UIImageView*iv=[[UIImageView alloc]initWithFrame:CGRectZero];
        iv.contentMode=UIViewContentModeScaleAspectFill;
        iv.clipsToBounds=YES;
        iv.layer.borderColor=[UIColor colorWithWhite:0 alpha:0.5].CGColor;
        iv.layer.borderWidth=1;
        iv.backgroundColor=[UIColor colorWithWhite:0.1 alpha:1];
        iv.tag=i;
        [self.cfView addSubview:iv];
        [self.covers addObject:iv];

        // Load artwork async
        dispatch_async(dispatch_get_global_queue(0,0),^{
            MPMediaItemCollection*album=self.albums[i];
            MPMediaItemArtwork*art=[album.representativeItem valueForProperty:MPMediaItemPropertyArtwork];
            UIImage*img=art?[art imageWithSize:CGSizeMake(120,120)]:nil;
            dispatch_async(dispatch_get_main_queue(),^{
                if(i<(NSInteger)self.covers.count) self.covers[i].image=img;
            });
        });
    }
    [self updateLabels];
}

-(void)layoutCovers:(BOOL)animated {
    if(!self.cfView||!self.covers.count) return;
    CGFloat sw=self.cfView.bounds.size.width;
    CGFloat sh=self.cfView.bounds.size.height;
    CGFloat coverSize=MIN(sw*0.55f, sh*0.52f);
    CGFloat centerY=(sh-36)/2.0f; // center of flip area (leave room for reflection)
    CGFloat cx=sw/2;

    void(^doLayout)(void)=^{
        for(NSInteger i=0;i<(NSInteger)self.covers.count;i++){
            UIImageView*iv=self.covers[i];
            NSInteger diff=i-self.cur;
            if(labs(diff)>3){iv.hidden=YES;continue;}
            iv.hidden=NO;

            CGFloat cs=(diff==0)?coverSize:coverSize*0.72f;
            CGFloat x,angle,z;

            if(diff==0){
                x=cx; angle=0; z=0;
                iv.frame=CGRectMake(cx-cs/2, centerY-cs/2, cs, cs);
                iv.layer.transform=CATransform3DIdentity;
                iv.alpha=1;
            } else {
                // Side covers: angled ~55deg, stacked
                CGFloat dir=(diff>0)?1:-1;
                CGFloat gap=cs*0.18f;
                x=cx+dir*(coverSize*0.48f+gap*(CGFloat)labs(diff));
                angle=dir*(-55.0f*M_PI/180.0f);
                z=-100*labs(diff);
                iv.frame=CGRectMake(x-cs/2, centerY-cs/2, cs, cs);
                // 3D perspective transform
                CATransform3D t=CATransform3DIdentity;
                t.m34=-1.0/400.0;
                t=CATransform3DTranslate(t,0,0,z);
                t=CATransform3DRotate(t,angle,0,1,0);
                iv.layer.transform=t;
                iv.alpha=0.90f-0.15f*(CGFloat)(labs(diff)-1);
            }
        }
    };

    if(animated) [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:doLayout completion:nil];
    else doLayout();

    // Bring center to front
    if(self.cur<(NSInteger)self.covers.count)
        [self.cfView bringSubviewToFront:self.covers[self.cur]];

    [self updateLabels];
}

-(void)updateLabels {
    if(!self.albums.count||self.cur>=(NSInteger)self.albums.count) return;
    MPMediaItemCollection*album=self.albums[self.cur];
    MPMediaItem*rep=album.representativeItem;
    self.titleLbl.text=[rep valueForProperty:MPMediaItemPropertyAlbumTitle]?:@"";
    self.artistLbl.text=[rep valueForProperty:MPMediaItemPropertyArtist]?:@"";
}

#pragma mark - Wheel
-(void)wheelDidTrigger:(WheelAction)a {
    NSInteger n=(NSInteger)MIN(self.albums.count,(NSUInteger)self.covers.count);
    MPMusicPlayerController*p=MPMusicPlayerController.systemMusicPlayer;
    switch(a){
        
        case WheelActionPrev:
        case WheelActionScrollUp:
            if(self.cur>0){self.cur--;[self layoutCovers:YES];}break;
        
        case WheelActionNext:
        case WheelActionScrollDown:
            if(self.cur<n-1){self.cur++;[self layoutCovers:YES];}break;
        case WheelActionCenter: {
            // Play album
            MPMediaItemCollection*album=self.albums[self.cur];
            [p setQueueWithItemCollection:album]; [p play];
            [self.navigationController pushViewController:[NowPlayingViewController new] animated:YES];
            break;
        }
        case WheelActionPlayPause:
            p.playbackState==MPMusicPlaybackStatePlaying?[p pause]:[p play]; break;
        case WheelActionMenu:
            [self.navigationController popViewControllerAnimated:YES]; break;
        default:break;
    }
}
@end
