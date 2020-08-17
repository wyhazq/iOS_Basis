//
//  RuntimeVC.m
//  Interview
//
//  Created by 一鸿温 on 8/4/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "RuntimeVC.h"
#import <objc/runtime.h>

void xxx(id self, SEL _cmd) {
    NSLog(@"xxx");
}

static void swizzleMethod(Class cls, SEL originalSEL, SEL swizzleSEL) {
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    Method swizzleMethod = class_getInstanceMethod(cls, swizzleSEL);
    
    BOOL isAdd = class_addMethod(cls, originalSEL, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (isAdd) {
        class_replaceMethod(cls, swizzleSEL, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
}

@interface TestClass : NSObject

@end

@implementation TestClass

- (void)xxx {
    NSLog(@"xxx");
}

@end

@interface RuntimeVC (Interview)

@property (nonatomic, copy) NSString *addString;

@end

@interface RuntimeVC ()

@end

@implementation RuntimeVC

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.为什么OC是动态语言"]) {
        [self dynamickOC:cell.textLabel.text];
    }
    else if ([cell.textLabel.text isEqualToString:@"2.消息发送流程"]) {
        [self performSelector:NSSelectorFromString(@"xxx")];
//        [self.class performSelector:NSSelectorFromString(@"xxx")];
    }
    else if ([cell.textLabel.text isEqualToString:@"3.方法交换"]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class cls = self.class;
            swizzleMethod(cls, @selector(original), @selector(swizz_original));
        });
        [self original];
//        [self performSelector:NSSelectorFromString(@"original")];
    }
    else if ([cell.textLabel.text isEqualToString:@"4.关联对象"]) {
        self.addString = @"4.关联对象";
        NSLog(@"%@", self.addString);
    }
}

//    动态语言是在运行时确定数据类型的语言。
- (void)dynamickOC:(NSArray *)obj {
    NSLog(@"%@", obj.class);
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *methodName = NSStringFromSelector(sel);
    if ([methodName isEqualToString:@"xxx"]) {
        NSLog(@"6.尝试动态解析方法 resolveMethod");
        class_addMethod(self.class, sel, (IMP)xxx, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    NSString *methodName = NSStringFromSelector(sel);
    if ([methodName isEqualToString:@"xxx"]) {
        NSLog(@"6.尝试动态解析方法 resolveMethod");
//        class_addMethod(object_getClass(self), sel, (IMP)xxx, "v@:");
//        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"7.尝试转发此消息 forwardingTargetForSelector");
    NSString *methodName = NSStringFromSelector(aSelector);
    if ([methodName isEqualToString:@"xxx"]) {
//        return TestClass.alloc.init;
    }
    
    return nil;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSLog(@"8.返回方法签名");
    NSString *methodName = NSStringFromSelector(aSelector);
    if ([methodName isEqualToString:@"xxx"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"将消息打包成 NSInvocation，尝试完整的消息转发 forwardInvocation");
    NSLog(@"来到 forwardInvocation 这一步，不管有没有处理，都不会Crash，没有则Crash！");
    [anInvocation invokeWithTarget:TestClass.alloc.init];
}

- (void)original {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)swizz_original {
    [self swizz_original];
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


@end

@implementation RuntimeVC (Interview)

- (void)setAddString:(NSString *)addString {
    objc_setAssociatedObject(self, @selector(addString), addString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)addString {
    return objc_getAssociatedObject(self, _cmd);
}

@end

