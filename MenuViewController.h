#import <UIKit/UIKit.h>
#import "ClickWheelView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface MenuItem : NSObject
@property (nonatomic, copy)   NSString  *title;
@property (nonatomic, copy)   NSString  *subtitle;     // artist name, description etc
@property (nonatomic, strong) UIImage   *artworkImage; // thumbnail shown in row
@property (nonatomic, copy)   void (^action)(UINavigationController *);
/// Called on main queue after async artwork is loaded — MenuViewController uses this to reload the row
@property (nonatomic, copy)   void (^onArtworkLoaded)(void);
+ (instancetype)title:(NSString *)title action:(void(^)(UINavigationController *))action;
// Convenience with subtitle + artwork
+ (instancetype)title:(NSString *)title subtitle:(NSString *)sub artwork:(UIImage *)art action:(void(^)(UINavigationController *))action;
@end

@interface MenuViewController : UIViewController <ClickWheelDelegate>
@property (nonatomic, copy)   NSString            *menuTitle;
@property (nonatomic, strong) NSArray<MenuItem *> *items;
@property (nonatomic, strong) UITableView         *table;
@end
