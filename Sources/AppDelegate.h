//
//  AppDelegate.h
//  CircuitLab
//

#import <UIKit/UIKit.h>

@class LabViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    LabViewController *labViewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
