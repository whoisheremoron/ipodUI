#import "AppDelegate.h"
#import "RootViewController.h"
#import "IPDMediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor colorWithRed:0.70 green:0.70 blue:0.70 alpha:1.0];

    MPMediaLibraryAuthorizationStatus status = [MPMediaLibrary authorizationStatus];
    if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
        [[IPDMediaLibrary shared] preloadIfNeeded];
    } else if (status == MPMediaLibraryAuthorizationStatusNotDetermined) {
        [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus s){
            if (s == MPMediaLibraryAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[IPDMediaLibrary shared] preloadIfNeeded];
                });
            }
        }];
    }

    RootViewController *root = [[RootViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    nav.navigationBarHidden = YES;
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
