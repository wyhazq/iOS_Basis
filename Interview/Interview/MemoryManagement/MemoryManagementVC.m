//
//  MemoryManagementVC.m
//  Interview
//
//  Created by 一鸿温 on 8/6/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "MemoryManagementVC.h"
#import "MRCObj.h"
#import "ARCObj.h"
#import "CopyObj.h"

@interface MemoryManagementVC ()

@property (nonatomic, copy) void (^mlBlock)(void);

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation MemoryManagementVC

- (void)dealloc {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self willDealloc];
    });
}

- (void)willDealloc {
    NSLog(@"Memory Leak");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.四大原则"]) {
        [MRCObj fourPrinciples];
        [ARCObj fourPrinciples];
    }
    else if ([cell.textLabel.text isEqualToString:@"2.TaggedPointer"]) {
        [self taggedPointer];
    }
    else if ([cell.textLabel.text isEqualToString:@"3.浅拷贝深拷贝"]) {
        [self shallowCopyDeepCopy];
    }
    else if ([cell.textLabel.text isEqualToString:@"4.MemoryLeak"]) {
        [self memoryLeak];
    }
}

- (void)taggedPointer {    
    NSMutableString *mstring = [NSMutableString string];
    for (NSUInteger i = 0; i < 10; i++) {
        [mstring appendFormat:@"%lu", i];
        NSString *string = mstring.copy;
        NSLog(@"%p %@ %@", string, string, string.class);
    }
}

- (void)shallowCopyDeepCopy {
    NSString *shallowStr = [NSString stringWithFormat:@"1234567890"];
    NSLog(@"shallowCopy: \n%p \n%p", shallowStr, shallowStr.copy);
    NSLog(@"deepCopy: \n%p \n%p", shallowStr, shallowStr.mutableCopy);
    
    CopyObj *obj = [CopyObj obj];
    ARCObj *obj1 = [CopyObj obj];
    NSLog(@"deepCopy: \n%p \n%p \n%p", obj, obj.copy, obj.mutableCopy);
}

- (void)memoryLeak {
    self.mlBlock = ^{
        NSLog(@"%@", self);
    };
    
    _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)onTimer:(NSTimer *)timer {
    
}


@end
