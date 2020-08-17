//
//  CADisplayLink+Block.h
//  Interview
//
//  Created by 一鸿温 on 8/13/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CADisplayLink (Block)

+ (CADisplayLink *)displayLinkWithBlock:(void(^)(CADisplayLink *displayLink))block;

@end

NS_ASSUME_NONNULL_END
