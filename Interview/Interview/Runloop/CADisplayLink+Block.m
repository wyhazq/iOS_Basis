//
//  CADisplayLink+Block.m
//  Interview
//
//  Created by 一鸿温 on 8/13/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "CADisplayLink+Block.h"
#import <objc/runtime.h>

@implementation CADisplayLink (Block)

+ (CADisplayLink *)displayLinkWithBlock:(void (^)(CADisplayLink *))block {
    objc_setAssociatedObject(self, @selector(onDisplayLink:), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
}

+ (void)onDisplayLink:(CADisplayLink *)displayLink {
    void (^block)(CADisplayLink *) = objc_getAssociatedObject(self, _cmd);
    if (block) {
        block(displayLink);
    }
}

@end
