//
//  PerformanceMonitoring.m
//  Test222
//
//  Created by 珠珠 on 2019/10/26.
//  Copyright © 2019 zhuzhu. All rights reserved.
//

#import "PerformanceMonitoring.h"
#import <UIKit/UIKit.h>
#import "mach/mach.h"

@interface PerformanceMonitoring ()

@property (nonatomic,strong) CADisplayLink * link  ;

@end


@implementation PerformanceMonitoring

+(instancetype) defaultManager {
    static dispatch_once_t onceToken;
    static PerformanceMonitoring * manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[PerformanceMonitoring alloc] init];
    });
    return manager;
}

- (void)startMonitoring {
    
    [self link];
    
}

- (void)stopMonitoring {
    
    [_link invalidate];
    _link = nil;

    UIWindow * keyWindow = [UIApplication sharedApplication].keyWindow ;
    UILabel * resultLabel = [keyWindow viewWithTag:3852];
    [resultLabel removeFromSuperview];
    
}

- (CADisplayLink *)link {
    if (_link == nil) {
        CADisplayLink * link = [CADisplayLink displayLinkWithTarget:self selector:@selector(screenRefresh:)];
        [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        link.preferredFramesPerSecond = 60;
        _link = link;
        
    }
    return _link;
}


- (void)screenRefresh:(CADisplayLink *)link {
    
    static CFTimeInterval lastTime = 0.0;
    static int count = 0;
    if (lastTime == 0) {
        lastTime = link.timestamp ;
        return;
    }
    count ++;
    double fps = 0;
    // 1秒内不重复计算
    if (link.timestamp - lastTime<=1.0) {
        return;
    }
    // 超过一秒了,计算下帧数
    fps = count/(link.timestamp - lastTime);
    //    NSLog(@"%lf %lf %lf %lf",fps,link.duration,link.timestamp,link.targetTimestamp);
    count = 0;
    lastTime = link.timestamp ;

    [self showResultWithFPS:fps];

    // 这个每次都做 除法运算,每次都更新UI,比较费性能,cpu使用率会高2%左右
//    static CFTimeInterval lastTime = 0.0;
//    if (lastTime == 0) {
//        lastTime = link.timestamp ;
//        return;
//    }
//    double fps = 0;
//    if (link.timestamp - lastTime>0) {
//        fps = 1/(link.timestamp - lastTime);
//    }
////    NSLog(@"%lf %lf %lf %lf",fps,link.duration,link.timestamp,link.targetTimestamp);
//
//    lastTime = link.timestamp ;
//
//    [self showResultWithFPS:fps];
}


- (void)showResultWithFPS:(double)fps {
    
    UIWindow * keyWindow = [UIApplication sharedApplication].keyWindow ;
    
    UILabel * resultLabel = [keyWindow viewWithTag:3852];
    if (resultLabel == nil) {
        resultLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 44, 300, 44)];
        resultLabel.tag = 3852;
        resultLabel.backgroundColor = [UIColor redColor];
        [keyWindow addSubview:resultLabel];
    }
    
    // 用透明度表明性能状态,>=100,说明可能存在卡顿 100-fps + self.cpuUsage + self.usedMemoryInMB/10
    double cpu = self.cpuUsage;
    double mem = self.usedMemoryInMB;
    CGFloat alpha = (100-fps + cpu + mem/10)/100;
    resultLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:alpha];
    resultLabel.text = [NSString stringWithFormat:@"FPS:%.1lf \t内存:%.1lfMB \tCPU:%.1lf%% ",fps,mem ,cpu];
    
}



- (CGFloat)usedMemoryInMB{
    vm_size_t memory = usedMemory();
    return memory / 1024.0 / 1024.0;
}

- (CGFloat)cpuUsage{
    float cpu = cpu_usage();
    return cpu;
}
vm_size_t usedMemory(void) {

    // 这个方法得出的与xcode最接近
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if(task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count) != KERN_SUCCESS) {
        return 0;
    }
    return (double)vmInfo.phys_footprint;

    // 腾讯的GT应该是采用了这个,但是这个和xcode的相差甚远
//    task_basic_info_data_t taskInfo;
//    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
//    kern_return_t kernReturn = task_info(mach_task_self(),
//                                         TASK_BASIC_INFO, (task_info_t)&taskInfo, &infoCount);
//
//    if(kernReturn != KERN_SUCCESS) {
//        return 0;
//    }
//    return taskInfo.resident_size;
    

}

float cpu_usage()
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    // for each thread
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    }
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}


@end
