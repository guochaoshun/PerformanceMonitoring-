//
//  PerformanceMonitoring.h
//  Test222
//
//  Created by 珠珠 on 2019/10/26.
//  Copyright © 2019 zhuzhu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 性能监控,监测屏幕帧数,cpu使用,内存使用,及时发现卡顿
@interface PerformanceMonitoring : NSObject

+(instancetype) defaultManager ;
- (void)startMonitoring ;
- (void)stopMonitoring ;

@end

NS_ASSUME_NONNULL_END
