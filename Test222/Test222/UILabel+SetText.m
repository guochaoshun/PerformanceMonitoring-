//
//  NSLabel+SetText.m
//  拖动手势
//
//  Created by 郭朝顺 on 2018/5/15星期二.
//  Copyright © 2018年 乐乐. All rights reserved.
//

#import "UILabel+SetText.h"
#import <objc/runtime.h>

@implementation UILabel (SetText)

+ (void)load {
    
    
    SEL origSel = @selector(setText:) ;
    SEL altSel = @selector(setTextHooked:) ;

    Method origMethod = class_getInstanceMethod(self, origSel);
    Method altMethod = class_getInstanceMethod(self, altSel);
    if (!origMethod || !altMethod) {
        return ;
    }
    // 交换实现
    method_exchangeImplementations(origMethod,altMethod);
    
}

/// 主要是解决 服务器有时返回NSNumber类型,但是用了NSString指针接收,在 label.text = @(num) 时崩溃
- (void) setTextHooked:(NSString *)string {
    
    if (string == nil) {
        string = @"";
    }
    if ([string isKindOfClass:[NSNumber class]]) {
        NSLog(@"怎么回事,小兄弟,传个Number过来,传统方法,推荐使用");
        string = string.description;
    }
    
    if ([string isKindOfClass:[NSString class]] && [string containsString:@"(null)"]) {
        string = [string stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    }
    
    [self setTextHooked:string.description] ;
    
}


@end
