//
//  LXDAppFluecyMonitor.m
//  LXDAppFluecyMonitor
//
//  Created by linxinda on 2017/3/22.
//  Copyright © 2017年 Jolimark. All rights reserved.
//

#import "LXDAppFluecyMonitor.h"
#import "LXDBacktraceLogger.h"
#import <mach/mach_time.h>
#import <QuartzCore/QuartzCore.h>

@interface LXDAppFluecyMonitor ()

@property (nonatomic, assign) int timeOut;
@property (nonatomic, assign) BOOL isMonitoring;

@property (nonatomic, assign) CFRunLoopObserverRef observer;
@property (nonatomic, assign) CFRunLoopActivity currentActivity;

@property (nonatomic, strong) dispatch_queue_t queue;


@end


static void lxdRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void * info) {
    SHAREDMONITOR.currentActivity = activity;

    /* Run Loop Observer Activities */
//    typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
//        kCFRunLoopEntry = (1UL << 0),    // 进入RunLoop循环(这里其实还没进入)
//        kCFRunLoopBeforeTimers = (1UL << 1),  // RunLoop 要处理timer了
//        kCFRunLoopBeforeSources = (1UL << 2), // RunLoop 要处理source了
//        kCFRunLoopBeforeWaiting = (1UL << 5), // RunLoop要休眠了
//        kCFRunLoopAfterWaiting = (1UL << 6),   // RunLoop醒了
//        kCFRunLoopExit = (1UL << 7),           // RunLoop退出（和kCFRunLoopEntry对应）
//        kCFRunLoopAllActivities = 0x0FFFFFFFU
//    };

    static uint64_t beforeSource = 0;
    static uint64_t beforeWaiting = 0;
    static uint64_t afterWaiting = 0;

    CACurrentMediaTime();
    switch (activity) {
        case kCFRunLoopEntry:{
            //            NSLog(@"runloop entry");

        }
            break;

        case kCFRunLoopBeforeTimers: {
            //            NSLog(@"runloop before timers");

        }
            break;

        case kCFRunLoopBeforeSources: {
//            NSLog(@"runloop before sources");
            beforeSource = mach_absolute_time();
        }
            break;

        case kCFRunLoopBeforeWaiting: {
//            NSLog(@"runloop before waiting");
            beforeWaiting = mach_absolute_time();
            if (beforeWaiting - beforeSource > 20*NSEC_PER_USEC) {
                NSLog(@"事件循环卡顿---1");
                dispatch_async(SHAREDMONITOR.queue, ^{
                    [LXDBacktraceLogger lxd_logMain];
                });
//                [LXDBacktraceLogger lxd_logMain];
            }
            if (beforeWaiting - afterWaiting > 100*NSEC_PER_USEC) {
                NSLog(@"整体循环卡顿");
                dispatch_async(SHAREDMONITOR.queue, ^{
                    [LXDBacktraceLogger lxd_logMain];
                });
//                [LXDBacktraceLogger lxd_logMain];
            }
//            NSLog(@"%@\t\t%@",@(beforeWaiting - beforeSource), @(beforeWaiting - afterWaiting));

        }
            break;

        case kCFRunLoopAfterWaiting: {
//            NSLog(@"runloop after waiting");
            afterWaiting = mach_absolute_time();
        }
            break;

        case kCFRunLoopExit: {
//            NSLog(@"runloop exit");

        }
            break;

        default:
            break;
    }
}



@implementation LXDAppFluecyMonitor


#pragma mark - Singleton override
+ (instancetype)sharedMonitor {
    static LXDAppFluecyMonitor * sharedMonitor;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedMonitor = [[super allocWithZone: NSDefaultMallocZone()] init];
        sharedMonitor.queue = dispatch_queue_create("LXDAppFluecyMonitor", DISPATCH_QUEUE_SERIAL);
    });
    return sharedMonitor;
}

+ (instancetype)allocWithZone: (struct _NSZone *)zone {
    return [self sharedMonitor];
}

- (void)dealloc {
    [self stopMonitoring];
}


#pragma mark - Public
- (void)startMonitoring {
    if (_isMonitoring) {
        return;
    }
    _isMonitoring = YES;
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)self,
        NULL,
        NULL
    };
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &lxdRunLoopObserverCallback, &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);

}

- (void)stopMonitoring {
    if (!_isMonitoring) { return; }
    _isMonitoring = NO;

    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = nil;
}



@end

