#import "SettingsViewController.h"
#import "IPodLayout.h"
#import <MediaPlayer/MediaPlayer.h>

static NSString*const kH=@"com.ipodclassic.haptic";
static NSString*const kC=@"com.ipodclassic.clicksound";
static NSString*const kR=@"com.ipodclassic.repeat";
static NSString*const kS=@"com.ipodclassic.shuffle";
typedef NS_ENUM(NSInteger,SR){SHaptic=0,SClick,SRepeat,SShuffle,SCount};

@interface SettingsViewController()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)UITableView*table;
@property(nonatomic,strong)ClickWheelView*wheel;
@property(nonatomic,assign)NSInteger sel;
@property(nonatomic,assign)BOOL built;
@property(nonatomic,assign)BOOL haptic,click;
@property(nonatomic,assign)MPMusicRepeatMode repeat;
@property(nonatomic,assign)MPMusicShuffleMode shuffle;
@end
@implementation SettingsViewController
-(void)viewDidLoad{[super viewDidLoad];self.view.backgroundColor=IPD_BODY;self.built=NO;
    NSUserDefaults*d=NSUserDefaults.standardUserDefaults;
    self.haptic=[d objectForKey:kH]?[d boolForKey:kH]:YES;
    self.click =[d objectForKey:kC]?[d boolForKey:kC]:YES;
    self.repeat=(MPMusicRepeatMode)[d integerForKey:kR];
    self.shuffle=(MPMusicShuffleMode)[d integerForKey:kS];}
-(void)save{
    NSUserDefaults*d=NSUserDefaults.standardUserDefaults;
    [d setBool:self.haptic forKey:kH];[d setBool:self.click forKey:kC];
    [d setInteger:self.repeat forKey:kR];[d setInteger:self.shuffle forKey:kS];[d synchronize];
    MPMusicPlayerController*p=MPMusicPlayerController.systemMusicPlayer;
    p.repeatMode=self.repeat;p.shuffleMode=self.shuffle;}
-(void)viewDidLayoutSubviews{[super viewDidLayoutSubviews];if(self.built)return;self.built=YES;[self build];}
-(void)build{
    CGRect b=self.view.bounds; CGRect sr=IPDScreenRect(b);
    UIView*screen=IPDBuildScaffold(self.view);
    CGFloat sw=sr.size.width,sh=sr.size.height;
    UIView*hdr=IPDHeader(sw,@"Settings",nil,nil);[screen addSubview:hdr];
    self.table=[[UITableView alloc]initWithFrame:CGRectMake(0,IPD_HDR_H,sw,sh-IPD_HDR_H) style:UITableViewStylePlain];
    self.table.backgroundColor=IPD_SCREEN;self.table.separatorColor=IPD_SEP;
    self.table.separatorInset=UIEdgeInsetsZero;self.table.layoutMargins=UIEdgeInsetsZero;
    self.table.dataSource=self;self.table.delegate=self;
    self.table.scrollEnabled=NO;self.table.rowHeight=IPD_ROW_H;
    self.table.showsVerticalScrollIndicator=NO;self.table.tableFooterView=[UIView new];
    [screen addSubview:self.table];
    [self.table selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.wheel=[[ClickWheelView alloc]initWithFrame:IPDWheelRect(b)];self.wheel.delegate=self;[self.view addSubview:self.wheel];}
-(NSString*)lbl:(NSInteger)r{switch(r){case SHaptic:return@"Haptic Feedback";case SClick:return@"Click Sound";case SRepeat:return@"Repeat";case SShuffle:return@"Shuffle";default:return@"";}}
-(NSString*)val:(NSInteger)r{
    switch(r){case SHaptic:return self.haptic?@"On":@"Off";case SClick:return self.click?@"On":@"Off";
    case SRepeat:switch(self.repeat){case MPMusicRepeatModeOne:return@"One";case MPMusicRepeatModeAll:return@"All";default:return@"Off";}
    case SShuffle:return self.shuffle==MPMusicShuffleModeOff?@"Off":@"On";default:return@"";}}
-(NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)s{return SCount;}
-(UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)ip{
    UITableViewCell*c=[tv dequeueReusableCellWithIdentifier:@"s"];
    if(!c){c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"s"];
    c.backgroundColor=IPD_SCREEN;c.textLabel.font=[UIFont systemFontOfSize:13];
    c.detailTextLabel.font=[UIFont systemFontOfSize:12];c.separatorInset=UIEdgeInsetsZero;c.layoutMargins=UIEdgeInsetsZero;
    UIView*sv=[UIView new];sv.backgroundColor=IPD_SEL;c.selectedBackgroundView=sv;}
    BOOL s=(ip.row==self.sel);
    c.textLabel.text=[self lbl:ip.row];c.textLabel.textColor=s?UIColor.whiteColor:IPD_TXT;
    c.detailTextLabel.text=[self val:ip.row];c.detailTextLabel.textColor=s?[UIColor colorWithWhite:0.88 alpha:1]:IPD_SUBTXT;
    return c;}
-(void)tog{
    switch(self.sel){
        case SHaptic:self.haptic=!self.haptic;if(self.haptic)[[UIImpactFeedbackGenerator.alloc initWithStyle:UIImpactFeedbackStyleLight]impactOccurred];break;
        case SClick:self.click=!self.click;break;
        case SRepeat:switch(self.repeat){case MPMusicRepeatModeNone:self.repeat=MPMusicRepeatModeOne;break;case MPMusicRepeatModeOne:self.repeat=MPMusicRepeatModeAll;break;default:self.repeat=MPMusicRepeatModeNone;}break;
        case SShuffle:self.shuffle=(self.shuffle==MPMusicShuffleModeOff)?MPMusicShuffleModeSongs:MPMusicShuffleModeOff;break;}
    [self save];[self.table reloadData];[self sync];}
-(void)moveTo:(NSInteger)i{self.sel=MAX(0,MIN(i,SCount-1));[self sync];}
-(void)sync{
    for(NSInteger i=0;i<SCount;i++){NSIndexPath*ip=[NSIndexPath indexPathForRow:i inSection:0];UITableViewCell*c=[self.table cellForRowAtIndexPath:ip];BOOL s=(i==self.sel);
    if(s){[self.table selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionNone];c.textLabel.textColor=UIColor.whiteColor;c.detailTextLabel.textColor=[UIColor colorWithWhite:0.88 alpha:1];}
    else{[self.table deselectRowAtIndexPath:ip animated:NO];c.textLabel.textColor=IPD_TXT;c.detailTextLabel.textColor=IPD_SUBTXT;}}}
-(void)wheelDidTrigger:(WheelAction)a{
    switch(a){case WheelActionScrollUp:case WheelActionPrev:if(self.sel>0)[self moveTo:self.sel-1];break;
    case WheelActionScrollDown:case WheelActionNext:if(self.sel<SCount-1)[self moveTo:self.sel+1];break;
    case WheelActionCenter:case WheelActionPlayPause:[self tog];IPDHaptic();break;
    case WheelActionMenu:[self.navigationController popViewControllerAnimated:YES];break;default:break;}}
@end
