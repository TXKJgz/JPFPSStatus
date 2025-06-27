//
//  JPFPSStatus.m
//  JPFPSStatus
//
//  Created by coderyi on 16/6/4.
//  Copyright © 2016年 http://coderyi.com . All rights reserved.
//  @ https://github.com/joggerplus/JPFPSStatus

#import "JPFPSStatus.h"

@interface JPFPSStatus (){
    CADisplayLink *displayLink;
    NSTimeInterval lastTime;
    NSUInteger count;
}
@property(nonatomic,copy) void (^fpsHandler)(NSInteger fpsValue);

@end

@implementation JPFPSStatus
@synthesize fpsLabel;

- (void)dealloc {
    [displayLink setPaused:YES];
    [displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

+ (JPFPSStatus *)sharedInstance {
    static JPFPSStatus *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[JPFPSStatus alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationDidBecomeActiveNotification)
                                                     name: UIApplicationDidBecomeActiveNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillResignActiveNotification)
                                                     name: UIApplicationWillResignActiveNotification
                                                   object: nil];
        
        // Track FPS using display link
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
        [displayLink setPaused:YES];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        // fpsLabel
        fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 40, 50, 20)];
        BOOL isiPhoneX = (([[UIScreen mainScreen] bounds].size.width == 375.f && [[UIScreen mainScreen] bounds].size.height == 812.f) || ([[UIScreen mainScreen] bounds].size.height == 375.f && [[UIScreen mainScreen] bounds].size.width == 812.f));
        if (isiPhoneX) {
            fpsLabel.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width-50)/2+50, 24, 50, 20);
        }
        fpsLabel.font=[UIFont boldSystemFontOfSize:12];
        fpsLabel.textColor=[UIColor colorWithRed:0.33 green:0.84 blue:0.43 alpha:1.00];
        fpsLabel.backgroundColor=[UIColor clearColor];
        fpsLabel.textAlignment=NSTextAlignmentRight;
        fpsLabel.tag=101;

    }
    return self;
}

- (void)displayLinkTick:(CADisplayLink *)link {
    if (lastTime == 0) {
        lastTime = link.timestamp;
        return;
    }
    
    count++;
    NSTimeInterval interval = link.timestamp - lastTime;
    if (interval < 1) return;
    lastTime = link.timestamp;
    float fps = count / interval;
    count = 0;
    
    NSString *text = [NSString stringWithFormat:@"%d FPS",(int)round(fps)];
    [fpsLabel setText: text];
    if (_fpsHandler) {
        _fpsHandler((int)round(fps));
    }
    
    [fpsLabel.superview bringSubviewToFront:fpsLabel];
}


- (UIWindow *)keyWindow {
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {

                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }

                // 退而求其次，拿第一个 window
                if (windowScene.windows.count > 0) {
                    return windowScene.windows.firstObject;
                }
            }
        }
    }

    // iOS 13 以下或 fallback
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    if ([appDelegate respondsToSelector:@selector(window)]) {
        return appDelegate.window;
    }

    return nil;
}

- (void)open {
    
    NSArray *rootVCViewSubViews=[[UIApplication sharedApplication].delegate window].rootViewController.view.subviews;
    for (UIView *label in rootVCViewSubViews) {
        if ([label isKindOfClass:[UILabel class]]&& label.tag==101) {
            return;
        }
    }

    [displayLink setPaused:NO];
    UIWindow *keyWindow = [self keyWindow];
    [keyWindow addSubview:fpsLabel];
    [keyWindow bringSubviewToFront:fpsLabel];

    // [[((NSObject <UIApplicationDelegate> *)([UIApplication sharedApplication].delegate)) window].rootViewController.view addSubview:fpsLabel];
}

- (void)openWithHandler:(void (^)(NSInteger fpsValue))handler{
    [[JPFPSStatus sharedInstance] open];
    _fpsHandler=handler;
}

- (void)close {
    
    [displayLink setPaused:YES];

    NSArray *rootVCViewSubViews=[[UIApplication sharedApplication].delegate window].rootViewController.view.subviews;
    for (UIView *label in rootVCViewSubViews) {
        if ([label isKindOfClass:[UILabel class]]&& label.tag==101) {
            [label removeFromSuperview];
            return;
        }
    }
    
}

- (void)applicationDidBecomeActiveNotification {
    [displayLink setPaused:NO];
}

- (void)applicationWillResignActiveNotification {
    [displayLink setPaused:YES];
}

@end
