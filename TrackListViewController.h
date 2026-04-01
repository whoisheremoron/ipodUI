#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ClickWheelView.h"

@interface TrackListViewController : UIViewController <ClickWheelDelegate>
// Pass either an album collection OR a generic item array + title
@property (nonatomic, strong) MPMediaItemCollection *collection;  // album
@property (nonatomic, copy)   NSString              *listTitle;
@end
