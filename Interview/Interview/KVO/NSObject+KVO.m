//
//  NSObject+KVO.m
//  Interview
//
//  Created by 一鸿温 on 8/11/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface KVOObject : NSObject

@property (nonatomic, strong) NSMutableDictionary *kvoDict;

@end

@implementation KVOObject

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    void(^block)(id newValue) = self.kvoDict[keyPath];
    id newValue = change[NSKeyValueChangeNewKey];
    if (block) {
        block(newValue);
    }
}

- (NSMutableDictionary *)kvoDict {
    if (!_kvoDict) {
        _kvoDict = [NSMutableDictionary dictionary];
    }
    return _kvoDict;
}

@end

void kvo_setKey(id self, SEL _cmd, id key) {
    Class subClass = [self class];
    struct objc_super super = {
        .receiver = self,
        .super_class = class_getSuperclass(subClass)
    };
    
    ((void(*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&super, _cmd, key);
    
    void(^block)(id newValue) = objc_getAssociatedObject(self, _cmd);
    if (block) {
        block(key);
    }
}

@interface NSObject (KVO_Private)

@property (nonatomic, strong) KVOObject *kvoObj;

@end

@implementation NSObject (KVO)

- (void)kvo_keyPath:(NSString *)keyPath block:(void(^)(id newValue))block {
    if (self.kvoObj.kvoDict[keyPath]) {
        return;
    }
    self.kvoObj.kvoDict[keyPath] = block;
    
    [self addObserver:self.kvoObj forKeyPath:keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)kvo_remove {
    NSString *className = NSStringFromClass(self.class);
    if ([className hasPrefix:@"KVO_"]) {
        object_setClass(self, class_getSuperclass(self.class));
        objc_disposeClassPair(NSClassFromString(className));
    }
    NSMutableDictionary *kvoDict = self.kvoObj.kvoDict;
    if (kvoDict.count > 0) {
        [kvoDict.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self removeObserver:self.kvoObj forKeyPath:obj];
        }];
    }
}

- (void)mykvo_keyPath:(NSString *)keyPath block:(void(^)(id newValue))block {
    Class class = self.class;
    NSString *className = NSStringFromClass(class);
    Class subClass;
    if (![className hasPrefix:@"KVO_"]) {
        NSString *subClassName = [@"KVO_" stringByAppendingString:className];
        subClass = objc_allocateClassPair(class, subClassName.UTF8String, 0);
        objc_registerClassPair(subClass);
    }
    else {
        subClass = class;
    }
    
    NSString *setSELName = [NSString stringWithFormat:@"set%@:", [keyPath stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[keyPath substringToIndex:1].uppercaseString]];
    SEL setSEL = NSSelectorFromString(setSELName);
    class_addMethod(subClass, setSEL, (IMP)kvo_setKey, "v@:@");
    
    object_setClass(self, subClass);
    
    objc_setAssociatedObject(self, setSEL, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (KVOObject *)kvoObj {
    KVOObject *kvoObj = objc_getAssociatedObject(self, _cmd);
    if (!kvoObj) {
        kvoObj = [[KVOObject alloc] init];
        objc_setAssociatedObject(self, _cmd, kvoObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return kvoObj;
}

@end
