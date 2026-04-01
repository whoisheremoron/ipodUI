// NowPlayingViewController.m — exact tannerv Now Playing layout
// Header: gray, "Now Playing" left-aligned, ⏸ + battery right
// Content: [artwork ~40%w] | [title bold \n artist \n album]
// Progress: spinner-icon | [==blue-knob==] | -remaining
#import "NowPlayingViewController.h"
#import "IPodLayout.h"
#import <MediaPlayer/MediaPlayer.h>

@interface NowPlayingViewController()
@property(nonatomic,strong)UILabel*stateIcon;
@property(nonatomic,strong)UIImageView*artwork;
@property(nonatomic,strong)UILabel*songLbl,*artistLbl,*albumLbl;
@property(nonatomic,strong)UIView*barTrack,*barFill,*barThumb;
@property(nonatomic,strong)UILabel*timeR;
@property(nonatomic,strong)UILabel*scrubLbl;
@property(nonatomic,strong)ClickWheelView*wheel;
@property(nonatomic,strong)MPMusicPlayerController*player;
@property(nonatomic,strong)NSTimer*timer;
@property(nonatomic,assign)CGFloat bX,bW,bY,bH;
@property(nonatomic,assign)NSInteger scrubSpeed;
@property(nonatomic,assign)BOOL built;
@end

@implementation NowPlayingViewController
-(void)viewDidLoad {
    [super viewDidLoad]; self.view.backgroundColor=IPD_BODY_BG;
    self.player=MPMusicPlayerController.systemMusicPlayer; self.built=NO;
}
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews]; if(self.built)return; self.built=YES;
    [self build]; [self refresh]; [self startTimer];
}
-(void)viewWillAppear:(BOOL)a {
    [super viewWillAppear:a];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(trackChanged)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:self.player];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stateChanged)
        name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:self.player];
    [self.player beginGeneratingPlaybackNotifications];
    [self refresh]; [self tick];
}
-(void)viewWillDisappear:(BOOL)a {
    [super viewWillDisappear:a];
    [self.timer invalidate]; self.timer=nil;
    [self.player endGeneratingPlaybackNotifications];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

-(void)build {
    CGRect b=self.view.bounds;
    CGRect sr=IPDScreenRect(b);
    UIView*screen=IPDBuildScaffold(self.view);
    CGFloat sw=sr.size.width,sh=sr.size.height;

    // Header — gray with "Now Playing" and state icon
    UILabel*li=nil;
    UIView*hdr=IPDHeader(sw,@"Now Playing",nil,&li);
    li.text=@""; // no back arrow text — just invisible
    self.stateIcon=(UILabel*)[hdr viewWithTag:77];
    [screen addSubview:hdr];

    // ── Layout (exactly like tannerv screenshot 4) ─────────────────────
    // Screen area: IPD_HDR_H → sh
    // Top padding: 8
    // Artwork: left, nearly full height of content
    // Right of artwork: song / artist / album stacked
    // Progress bar: near bottom

    CGFloat pad=8, contentTop=IPD_HDR_H+pad;
    CGFloat progRowH=24;
    CGFloat contentH=sh-contentTop-progRowH-pad;

    // Artwork — square, left, 40% of screen width
    CGFloat artS=MIN(floorf(sw*0.40f), contentH);
    CGFloat artX=pad, artY=contentTop+(contentH-artS)/2.0f;

    UIView*artBg=[[UIView alloc]initWithFrame:CGRectMake(artX,artY,artS,artS)];
    artBg.backgroundColor=[UIColor colorWithWhite:0.08 alpha:1];
    artBg.clipsToBounds=YES;
    // Shadow
    artBg.layer.shadowColor=UIColor.blackColor.CGColor;
    artBg.layer.shadowOffset=CGSizeMake(1,3); artBg.layer.shadowRadius=5; artBg.layer.shadowOpacity=0.5;
    artBg.layer.masksToBounds=NO;
    [screen addSubview:artBg];

    self.artwork=[[UIImageView alloc]initWithFrame:CGRectMake(0,0,artS,artS)];
    self.artwork.contentMode=UIViewContentModeScaleAspectFill;
    self.artwork.clipsToBounds=YES;
    [artBg addSubview:self.artwork];

    UILabel*note=[[UILabel alloc]initWithFrame:CGRectMake(0,0,artS,artS)];
    note.text=@"♪";note.font=[UIFont systemFontOfSize:artS*0.4];
    note.textColor=[UIColor colorWithWhite:1 alpha:0.10];note.textAlignment=NSTextAlignmentCenter;note.tag=999;
    [artBg addSubview:note];

    // Track info — right of artwork, vertically centred
    CGFloat infoX=artX+artS+10, infoW=sw-infoX-pad;
    // Block height: 2×16 (song) + 3 + 14 (artist) + 3 + 13 (album) = 65
    CGFloat blockH=65;
    CGFloat blockY=artY+(artS-blockH)/2.0f;

    self.songLbl=[[UILabel alloc]initWithFrame:CGRectMake(infoX,blockY,infoW,34)];
    self.songLbl.font=[UIFont boldSystemFontOfSize:13];
    self.songLbl.textColor=IPD_TXT; self.songLbl.numberOfLines=2;
    self.songLbl.lineBreakMode=NSLineBreakByWordWrapping;
    [screen addSubview:self.songLbl];

    self.artistLbl=[[UILabel alloc]initWithFrame:CGRectMake(infoX,blockY+37,infoW,14)];
    self.artistLbl.font=[UIFont systemFontOfSize:11]; self.artistLbl.textColor=IPD_SUBTXT;
    self.artistLbl.lineBreakMode=NSLineBreakByTruncatingTail;
    [screen addSubview:self.artistLbl];

    self.albumLbl=[[UILabel alloc]initWithFrame:CGRectMake(infoX,blockY+53,infoW,13)];
    self.albumLbl.font=[UIFont systemFontOfSize:10]; self.albumLbl.textColor=IPD_SUBTXT;
    self.albumLbl.lineBreakMode=NSLineBreakByTruncatingTail;
    [screen addSubview:self.albumLbl];

    // ── Progress row ────────────────────────────────────────────────────
    // iPod Classic style: elapsed | [======flat bar======] | -remaining
    // NO thumb knob, NO spinner circle — just a plain filled line
    CGFloat progY=sh-progRowH;
    CGFloat barThk=4;
    CGFloat timeLblW=36;

    // Elapsed time (left)
    UILabel*timeL=[[UILabel alloc]initWithFrame:CGRectMake(pad,progY,timeLblW,progRowH)];
    timeL.font=[UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightRegular];
    timeL.textColor=IPD_SUBTXT; timeL.textAlignment=NSTextAlignmentLeft;
    timeL.text=@"0:00"; timeL.tag=55; [screen addSubview:timeL];

    // Time remaining (right)
    self.timeR=[[UILabel alloc]initWithFrame:CGRectMake(sw-timeLblW-pad,progY,timeLblW,progRowH)];
    self.timeR.font=[UIFont monospacedDigitSystemFontOfSize:10 weight:UIFontWeightRegular];
    self.timeR.textColor=IPD_SUBTXT; self.timeR.textAlignment=NSTextAlignmentRight;
    self.timeR.text=@"-0:00"; [screen addSubview:self.timeR];

    self.bX=pad+timeLblW+4;
    self.bW=sw-self.bX-(timeLblW+4+pad);
    self.bY=progY+(progRowH-barThk)/2.0f;
    self.bH=barThk;

    self.barTrack=[[UIView alloc]initWithFrame:CGRectMake(self.bX,self.bY,self.bW,self.bH)];
    self.barTrack.backgroundColor=[UIColor colorWithWhite:0.72 alpha:1];
    self.barTrack.layer.cornerRadius=self.bH/2;
    [screen addSubview:self.barTrack];

    self.barFill=[[UIView alloc]initWithFrame:CGRectMake(self.bX,self.bY,0,self.bH)];
    self.barFill.backgroundColor=IPD_PROGRESS;
    self.barFill.layer.cornerRadius=self.bH/2;
    [screen addSubview:self.barFill];

    // No thumb knob — iPod Classic uses a flat bar only
    self.barThumb=nil;

    self.scrubLbl=[[UILabel alloc]initWithFrame:CGRectMake(pad,progY-14,sw-pad*2,12)];
    self.scrubLbl.font=[UIFont systemFontOfSize:9];self.scrubLbl.textColor=IPD_SUBTXT;
    self.scrubLbl.textAlignment=NSTextAlignmentCenter;self.scrubLbl.alpha=0;
    [screen addSubview:self.scrubLbl];

    // Wheel
    self.wheel=[[ClickWheelView alloc]initWithFrame:IPDWheelRect(b)];
    self.wheel.delegate=self; [self.view addSubview:self.wheel];
}

-(void)refresh {
    MPMediaItem*item=self.player.nowPlayingItem;
    UIView*note=[self.artwork.superview viewWithTag:999];
    if(!item){
        self.songLbl.text=@"Not Playing";self.artistLbl.text=@"";self.albumLbl.text=@"";
        self.artwork.image=nil;if(note)note.hidden=NO;
        self.timeR.text=@"-0:00";[self fillRatio:0];
        if(self.stateIcon)self.stateIcon.text=@"⏸";return;
    }
    self.songLbl.text=[item valueForProperty:MPMediaItemPropertyTitle]?:@"Unknown";
    self.artistLbl.text=[item valueForProperty:MPMediaItemPropertyArtist]?:@"";
    self.albumLbl.text=[item valueForProperty:MPMediaItemPropertyAlbumTitle]?:@"";
    MPMediaItemArtwork*art=[item valueForProperty:MPMediaItemPropertyArtwork];
    UIImage*img=art?[art imageWithSize:self.artwork.bounds.size]:nil;
    self.artwork.image=img;if(note)note.hidden=(img!=nil);
}
-(void)startTimer {
    [self.timer invalidate];
    self.timer=[NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(tick) userInfo:nil repeats:YES];
}
-(void)tick {
    BOOL pl=(self.player.playbackState==MPMusicPlaybackStatePlaying);
    if(self.stateIcon)self.stateIcon.text=pl?@"▶":@"⏸";
    MPMediaItem*item=self.player.nowPlayingItem;if(!item)return;
    NSNumber*dN=[item valueForProperty:MPMediaItemPropertyPlaybackDuration];
    if(!dN||dN.doubleValue<=0)return;
    NSTimeInterval d=dN.doubleValue,c=self.player.currentPlaybackTime;
    // Elapsed time label (tag 55)
    UILabel*timeL=(UILabel*)[self.view.subviews.lastObject viewWithTag:55];
    // Search in screen subviews
    if(!timeL){
        for(UIView*sv in self.view.subviews)
            for(UIView*ssv in sv.subviews)
                if(ssv.tag==55){timeL=(UILabel*)ssv;break;}
    }
    if(timeL) timeL.text=[self fmt:c];
    self.timeR.text=[NSString stringWithFormat:@"-%@",[self fmt:d-c]];
    [self fillRatio:(CGFloat)MAX(0,MIN(1,c/d))];
}
-(void)fillRatio:(CGFloat)r {
    CGFloat w=MAX(0,self.bW*r);
    self.barFill.frame=CGRectMake(self.bX,self.bY,w,self.bH);
    // No thumb to update
}
-(NSString*)fmt:(NSTimeInterval)t{if(t<0)t=0;return[NSString stringWithFormat:@"%d:%02d",(int)t/60,(int)t%60];}
-(void)trackChanged{dispatch_async(dispatch_get_main_queue(),^{[self refresh];[self tick];});}
-(void)stateChanged{dispatch_async(dispatch_get_main_queue(),^{[self tick];});}
-(NSTimeInterval)seekAmt{switch(self.scrubSpeed){case 0:return 5;case 1:return 2;case 2:return 0.5;default:return 0.1;}}
-(void)showScrub{
    NSArray*l=@[@"High-Speed Scrubbing",@"Fine Scrubbing",@"Finer Scrubbing",@"Finest Scrubbing"];
    self.scrubLbl.text=l[self.scrubSpeed];
    [UIView animateWithDuration:0.1 animations:^{self.scrubLbl.alpha=1;}];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideScrub) object:nil];
    [self performSelector:@selector(hideScrub) withObject:nil afterDelay:1.8];
}
-(void)hideScrub{[UIView animateWithDuration:0.3 animations:^{self.scrubLbl.alpha=0;}];}
-(void)wheelDidTrigger:(WheelAction)a {
    NSTimeInterval dur=[[self.player.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    switch(a){
        case WheelActionPlayPause:
            self.player.playbackState==MPMusicPlaybackStatePlaying?[self.player pause]:[self.player play];break;
        case WheelActionNext:[self.player skipToNextItem];break;
        case WheelActionPrev:
            self.player.currentPlaybackTime>2?(self.player.currentPlaybackTime=0):[self.player skipToPreviousItem];break;
        case WheelActionScrollDown:
            self.player.currentPlaybackTime=MIN(self.player.currentPlaybackTime+[self seekAmt],dur);
            [self showScrub];[self tick];break;
        case WheelActionScrollUp:
            self.player.currentPlaybackTime=MAX(0,self.player.currentPlaybackTime-[self seekAmt]);
            [self showScrub];[self tick];break;
        case WheelActionCenter:self.scrubSpeed=(self.scrubSpeed+1)%4;[self showScrub];break;
        case WheelActionMenu:[self.navigationController popViewControllerAnimated:YES];break;
        default:break;
    }
}
@end
