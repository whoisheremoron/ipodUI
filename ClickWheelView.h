#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WheelAction) {
    WheelActionScrollUp,
    WheelActionScrollDown,
    WheelActionCenter,
    WheelActionMenu,
    WheelActionNext,
    WheelActionPrev,
    WheelActionPlayPause
};

@protocol ClickWheelDelegate <NSObject>
- (void)wheelDidTrigger:(WheelAction)action;
@end

@interface ClickWheelView : UIView
@property (nonatomic, weak) id<ClickWheelDelegate> delegate;
@end
