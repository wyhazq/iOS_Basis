//
//  NSTimer+Block.h
//  Interview
//
//  Created by 一鸿温 on 8/13/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (Block)

+ (instancetype)countdownTimerWithInterval:(NSTimeInterval)seconds times:(NSTimeInterval)totalSeconds block:(void (^)(NSTimeInterval leftSeconds))block;

- (void)start;

@end

NS_ASSUME_NONNULL_END
