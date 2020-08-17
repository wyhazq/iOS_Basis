//
//  MRCObj.m
//  Interview
//
//  Created by 一鸿温 on 8/6/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "MRCObj.h"

@implementation MRCObj

+ (void)fourPrinciples {
    NSLog(@"-------------- MRC ---------------");

    [self generateObj];
    [self otherGenerateObj];
    [self cannotReleaseNotOwnObj];
    
}

//1.自己生成的对象，自己持有
+ (void)generateObj {
    NSLog(@"1.自己生成的对象，自己持有");

    NSObject *obj0 = [[NSObject alloc] init];
    NSLog(@"obj0 count:%lu", [obj0 retainCount]);
    [obj0 release];

    NSObject *obj1 = [NSObject new];
    NSLog(@"obj1 count:%lu", [obj1 retainCount]);
    [obj1 release];
    
    NSObject *copyObj = [[NSArray alloc] initWithObjects:@"1", nil];
    
    NSObject *obj2 = copyObj.copy; //浅拷贝，引用计数增加
    NSLog(@"obj2 count:%lu", [obj2 retainCount]);
    [obj2 release];
    
    NSObject *obj3 = copyObj.mutableCopy; //深拷贝，引用计数不变，但引用指向的堆内存变了
    NSLog(@"obj3 count:%lu", [obj3 retainCount]);
    [obj3 release];
    
    NSLog(@"copyObj count:%lu", [copyObj retainCount]);
    [copyObj release];
    
}

//2.非自己生成的对象，自己也能持有
+ (void)otherGenerateObj {
    NSLog(@"2.非自己生成的对象，自己也能持有");
    
    NSObject *obj0;
    @autoreleasepool {
        obj0 = [NSArray arrayWithObject:@"1"];
        [obj0 retain];
    }
    NSLog(@"obj0 count:%lu", [obj0 retainCount]);
    
    //3.不再需要自己持有的对象时释放
    NSLog(@"3.不再需要自己持有的对象时释放");
    [obj0 release];
}

//4.非自己持有的对象无法释放
+ (void)cannotReleaseNotOwnObj {
    NSLog(@"4.非自己持有的对象无法释放");
    NSObject *obj0 = [NSArray arrayWithObject:@"1"];
//    [obj0 release];
}

@end
