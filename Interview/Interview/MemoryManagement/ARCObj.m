//
//  ARCObj.m
//  Interview
//
//  Created by 一鸿温 on 8/6/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "ARCObj.h"

@interface NSObject (ARCObj)

@property (nonatomic, readonly) NSUInteger arc_retainCount;

@end

@implementation NSObject (ARCObj)

- (NSUInteger)arc_retainCount {
    return CFGetRetainCount((__bridge  CFTypeRef)(self));
}

@end

@implementation ARCObj

+ (void)fourPrinciples {
    NSLog(@"-------------- ARC ---------------");

    [self generateObj];
    [self otherGenerateObj];
    [self cannotReleaseNotOwnObj];
    
}

//1.自己生成的对象，自己持有
+ (void)generateObj {
    NSLog(@"1.自己生成的对象，自己持有");

    NSObject *obj0 = [[NSObject alloc] init];
    NSLog(@"obj0 count:%lu", obj0.arc_retainCount);

    NSObject *obj1 = [NSObject new];
    NSLog(@"obj1 count:%lu", obj1.arc_retainCount);
    
    NSObject *copyObj = [[NSArray alloc] initWithObjects:@"1", nil];
    
    NSObject *obj2 = copyObj.copy; //浅拷贝，引用计数增加
    NSLog(@"obj2 count:%lu", obj2.arc_retainCount);
    
    NSObject *obj3 = copyObj.mutableCopy; //深拷贝，引用计数不变，但引用指向的堆内存变了
    NSLog(@"obj3 count:%lu", obj3.arc_retainCount);
    
    NSLog(@"copyObj count:%lu", copyObj.arc_retainCount);
}

//2.非自己生成的对象，自己也能持有
+ (void)otherGenerateObj {
    NSLog(@"2.非自己生成的对象，自己也能持有");
    
    NSObject *obj0;
    @autoreleasepool {
        obj0 = [NSArray arrayWithObject:@"1"];
        NSLog(@"obj0 count:%lu", obj0.arc_retainCount);
    }
    NSLog(@"obj0 count:%lu", obj0.arc_retainCount);
    
    //3.不再需要自己持有的对象时释放
    NSLog(@"3.不再需要自己持有的对象时释放");
}

//4.非自己持有的对象无法释放
+ (void)cannotReleaseNotOwnObj {
    NSLog(@"4.非自己持有的对象无法释放");
    NSObject *obj0 = [NSArray arrayWithObject:@"1"];
//    [obj0 release];
}

@end
