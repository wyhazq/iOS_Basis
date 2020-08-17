//
//  NSTimer+Block.m
//  Interview
//
//  Created by 一鸿温 on 8/13/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "NSTimer+Block.h"
#import <objc/runtime.h>

@interface NSTimer (Block_Private)

@property (nonatomic, assign) NSTimeInterval leftSeconds;

@end

@implementation NSTimer (Block)

+ (instancetype)countdownTimerWithInterval:(NSTimeInterval)seconds times:(NSTimeInterval)totalSeconds block:(void (^)(NSTimeInterval))block {
    NSTimer *timer = [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(onCountdownTimer:) userInfo:block repeats:YES];
    timer.leftSeconds = totalSeconds;
    return timer;
}

+ (void)onCountdownTimer:(NSTimer *)timer {
    if (timer.userInfo) {
        void (^block)(NSTimeInterval) = timer.userInfo;
        if (block) {
            block(timer.leftSeconds--);
        }
    }
}

- (void)start {
    [NSRunLoop.currentRunLoop addTimer:self forMode:NSRunLoopCommonModes];
}

- (void)setLeftSeconds:(NSTimeInterval)leftSeconds {
    objc_setAssociatedObject(self, @selector(leftSeconds), @(leftSeconds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)leftSeconds {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

@end
