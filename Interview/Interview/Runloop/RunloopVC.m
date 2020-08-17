//
//  RunloopVC.m
//  Interview
//
//  Created by 一鸿温 on 8/13/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "RunloopVC.h"
#import "NSTimer+Block.h"
#import "CADisplayLink+Block.h"

@interface RunloopVC ()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSThread *thread;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation RunloopVC
{
    unsigned int count;
    CFTimeInterval timestamp;
}

- (void)dealloc {
    [self.timer invalidate];
    self.timer = nil;
    [self.displayLink invalidate];
    self.displayLink = nil;
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    count = 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.Timer"]) {
        _timer = [NSTimer countdownTimerWithInterval:1 times:60 block:^(NSTimeInterval leftSeconds) {
            NSLog(@"%lf", leftSeconds);
        }];
        [self.timer start];
    }
    else if ([cell.textLabel.text isEqualToString:@"2.resident_thread"]) {
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(onThread:) object:nil];
        [self.thread start];
        [self performSelector:@selector(onResidentThread:) onThread:self.thread withObject:self.thread waitUntilDone:NO];
    }
    else if ([cell.textLabel.text isEqualToString:@"3.Observer"]) {
        CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 2000008, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            NSLog(@"%@", [self runLoopActivityName:activity]);
        });
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopDefaultMode);
        CFRelease(observer);
    }
    else if ([cell.textLabel.text isEqualToString:@"4.CADisplayLink"]) {
        __weak typeof(self) weakSelf = self;
        _displayLink = [CADisplayLink displayLinkWithBlock:^(CADisplayLink * _Nonnull displayLink) {
            [weakSelf onDisplayLink:displayLink];
        }];
        [self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    }
}

- (void)onThread:(NSThread *)thread {
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    [NSRunLoop.currentRunLoop addPort:NSMachPort.port forMode:NSDefaultRunLoopMode];
    [NSRunLoop.currentRunLoop run];
}

- (void)onResidentThread:(NSThread *)thread {
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
}

- (NSString *)runLoopActivityName:(CFRunLoopActivity)activity {
    return @{
        @(kCFRunLoopEntry): @"kCFRunLoopEntry",
        @(kCFRunLoopBeforeTimers): @"kCFRunLoopBeforeTimers",
        @(kCFRunLoopBeforeSources): @"kCFRunLoopBeforeSources",
        @(kCFRunLoopBeforeWaiting): @"kCFRunLoopBeforeWaiting",
        @(kCFRunLoopAfterWaiting): @"kCFRunLoopAfterWaiting",
        @(kCFRunLoopExit): @"kCFRunLoopExit",
        @(kCFRunLoopAllActivities): @"kCFRunLoopAllActivities",
    }[@(activity)];
}

- (void)onDisplayLink:(CADisplayLink *)displayLink {
    if (timestamp == 0) {
        timestamp = displayLink.timestamp;
        return;
    }
    count++;
    if (displayLink.timestamp - timestamp >= 1) {
        NSLog(@"%u", count);
        count = 0;
        timestamp = 0;
    }
}

@end
