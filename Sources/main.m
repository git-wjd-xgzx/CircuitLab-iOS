//
//  main.m
//  CircuitLab
//
//  iOS 4.3+ entry point.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int result = UIApplicationMain(argc, argv, nil, @"AppDelegate");
    [pool release];
    return result;
}
