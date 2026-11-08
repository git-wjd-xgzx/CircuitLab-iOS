//
//  AppDelegate.m
//  CircuitLab
//

#import "AppDelegate.h"
#import "LabViewController.h"

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;

    // applicationFrame already excludes the status bar on iOS 4.3–6.
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    window = [[UIWindow alloc] initWithFrame:frame];
    window.backgroundColor = [UIColor blackColor];

    labViewController = [[LabViewController alloc] init];
    window.rootViewController = labViewController;
    [window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    (void)application;
    // The page is a single lightweight document; nothing to purge.
}

- (void)dealloc {
    [labViewController release];
    [window release];
    [super dealloc];
}

@end
