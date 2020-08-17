//
//  CopyObj.m
//  Interview
//
//  Created by 一鸿温 on 8/6/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "CopyObj.h"

@implementation CopyObj

+ (instancetype)obj {
    return [[self alloc] init];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self.class allocWithZone:zone] init];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[self.class allocWithZone:zone] init];
}

@end
