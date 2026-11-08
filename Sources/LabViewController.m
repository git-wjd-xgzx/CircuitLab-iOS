//
//  LabViewController.m
//  CircuitLab
//
//  A tiny native shell around the self-contained experiment page.
//  UIWebView is used deliberately: it exists on iOS 4.3 and lets the
//  instrument face, needle animation and drag interaction stay in one
//  local HTML document.
//

#import "LabViewController.h"

@implementation LabViewController

- (void)loadView {
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    UIView *root = [[UIView alloc] initWithFrame:frame];
    root.backgroundColor = [UIColor colorWithRed:(13.0 / 255.0)
                                           green:(22.0 / 255.0)
                                            blue:(25.0 / 255.0)
                                           alpha:1.0];
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = root;
    [root release];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect bounds = self.view.bounds;
    webView = [[UIWebView alloc] initWithFrame:bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.backgroundColor = [UIColor colorWithRed:(13.0 / 255.0)
                                              green:(22.0 / 255.0)
                                               blue:(25.0 / 255.0)
                                              alpha:1.0];
    webView.opaque = YES;
    webView.scalesPageToFit = NO;
    webView.dataDetectorTypes = UIDataDetectorTypeNone;
    webView.delegate = self;
    webView.accessibilityLabel = @"电学实验室";

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    // UIScrollView-backed UIWebView arrived in iOS 5. Guard both compile
    // time and runtime so the same binary still starts on iOS 4.3.
    if ([webView respondsToSelector:@selector(scrollView)]) {
        webView.scrollView.bounces = NO;
        webView.scrollView.scrollEnabled = NO;
    }
#endif

    [self.view addSubview:webView];

    NSString *pagePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    if (pagePath) {
        // Load the document as a string and use a nil base URL. Everything
        // (styles, scripts, canvas artwork) is inline, so this avoids needing
        // NSURLRequest/CFNetwork at all — one less framework that changed
        // between iOS 4.3 and modern SDKs.
        NSError *readError = nil;
        NSString *page = [NSString stringWithContentsOfFile:pagePath
                                                   encoding:NSUTF8StringEncoding
                                                      error:&readError];
        (void)readError;
        if (page) {
            [webView loadHTMLString:page baseURL:nil];
        } else {
            [self showLoadFailure];
        }
    } else {
        [self showLoadFailure];
    }
}

- (void)viewDidUnload {
    webView.delegate = nil;
    [webView release];
    webView = nil;
    [super viewDidUnload];
}

- (void)webView:(UIWebView *)sender didFailLoadWithError:(NSError *)error {
    (void)sender;
    (void)error;
    [self showLoadFailure];
}

- (void)showLoadFailure {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds, 24.0, 80.0)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:(240.0 / 255.0)
                                     green:(230.0 / 255.0)
                                      blue:(210.0 / 255.0)
                                     alpha:1.0];
    label.font = [UIFont boldSystemFontOfSize:16.0];
    label.numberOfLines = 3;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    label.textAlignment = NSTextAlignmentCenter;
#else
    label.textAlignment = UITextAlignmentCenter;
#endif
    label.text = @"实验台加载失败\n请重新打开应用";
    [self.view addSubview:label];
    [label release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
#endif

- (void)dealloc {
    webView.delegate = nil;
    [webView release];
    [super dealloc];
}

@end
