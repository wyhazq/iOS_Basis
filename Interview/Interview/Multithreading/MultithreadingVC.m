//
//  MultithreadingVC.m
//  Interview
//
//  Created by 一鸿温 on 8/8/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "MultithreadingVC.h"

#import <libkern/OSAtomic.h>
#import <os/lock.h>
#import <pthread/pthread.h>


static inline void dispatch_async_main(dispatch_block_t block) {
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
        block();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface MultithreadingVC ()

@property (nonatomic, strong) NSThread *thread;

@end

@implementation MultithreadingVC

- (void)dealloc {
    pthread_mutex_destroy(&pthreadLock);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.安全派发到主线程"]) {
        [self toMainThread];
    }
    else if ([cell.textLabel.text isEqualToString:@"2.派发类型"]) {
        [self dispatchType];
    }
    else if ([cell.textLabel.text isEqualToString:@"3.after"]) {
        [self after];
    }
    else if ([cell.textLabel.text isEqualToString:@"4.barrier"]) {
        [self barrier];
    }
    else if ([cell.textLabel.text isEqualToString:@"5.once"]) {
        [self once];
    }
    else if ([cell.textLabel.text isEqualToString:@"6.apply"]) {
        [self apply];
    }
    else if ([cell.textLabel.text isEqualToString:@"7.group"]) {
        [self group];
    }
    else if ([cell.textLabel.text isEqualToString:@"8.semaphore_async2sync"]) {
        [self semaphore_async2sync];
    }
    else if ([cell.textLabel.text isEqualToString:@"9.semaphore_lock"]) {
        [self semaphore_lock];
    }
    else if ([cell.textLabel.text isEqualToString:@"10.operation"]) {
        [self operation];
    }
    else if ([cell.textLabel.text isEqualToString:@"11.resident_thread"]) {
        [self residentThread];
    }
    else if ([cell.textLabel.text isEqualToString:@"12.lock"]) {
        [self lock];
    }
}

- (void)toMainThread {
    dispatch_async_main(^{
        NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
}

- (void)dispatchType {
    dispatch_queue_main_t mainQueue = dispatch_get_main_queue();
    dispatch_queue_t serialQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    //当前线程为主线程主队列
    NSLog(@"start.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    //1.当前队列 同步 当前队列：死锁
//    dispatch_sync(mainQueue, ^{
//
//    });
    
    //2.当前队列 异步 当前队列：接最后顺序执行
    dispatch_async(mainQueue, ^{
        NSLog(@"2.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
    
    //3.当前队列 同步 串行队列：优先执行
    dispatch_sync(serialQueue, ^{
        NSLog(@"3.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });

    //4.当前队列 异步 串行队列：新线程串行
    dispatch_async(serialQueue, ^{
        NSLog(@"4.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
    
    //5.当前队列 同步 并行队列：次优先于当前队列串行
    for (int i = 1; i < 4; i++) {
        dispatch_sync(concurrentQueue, ^{
            NSLog(@"5.%d\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        });
    }
    
    //6.当前队列 异步 并行队列：新线程并行
    for (int i = 1; i < 4; i++) {
        dispatch_async(concurrentQueue, ^{
            NSLog(@"6.%d\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        });
    }
    
    NSLog(@"end.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
}

- (void)after {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"两秒了");
    });
}

- (void)barrier {
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 1; i < 4; i++) {
        dispatch_async(concurrentQueue, ^{
            NSLog(@"%d\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        });
    }
    dispatch_barrier_async(concurrentQueue, ^{
        NSLog(@"\n------------------- barrier -------------------");
    });
    for (int i = 4; i < 7; i++) {
        dispatch_async(concurrentQueue, ^{
            NSLog(@"%d\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        });
    }
}

- (void)once {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"只执行一次");
    });
}

- (void)apply {
    dispatch_queue_t serialQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_global_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        dispatch_apply(100, globalQueue, ^(size_t i) {
            NSLog(@"%zu\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        });
    });
}

- (void)group {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_main_t mainQueue = dispatch_get_main_queue();
    
    for (int i = 1; i < 4; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            NSLog(@"%d.\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        });
    }
    
    dispatch_group_notify(group, mainQueue, ^{
        NSLog(@"end.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"start");

}

- (void)semaphore_async2sync {
    //异步转同步
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t serialQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(serialQueue, ^{
        NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
}

- (void)semaphore_lock {
    //加锁
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    __block int count = 0;
    for (int i = 1; i < 4; i++) {
        dispatch_async(concurrentQueue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
            dispatch_semaphore_signal(semaphore);
        });
    }
}

- (void)operation {
    NSBlockOperation *op0 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"0.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    }];
    op0.queuePriority= NSOperationQueuePriorityVeryLow;
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"1.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"2.\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    }];
    op2.queuePriority = NSOperationQueuePriorityHigh;
    
    NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
    opQueue.maxConcurrentOperationCount = 1;
    [opQueue addOperations:@[op0, op1, op2] waitUntilFinished:YES];
}

- (void)residentThread {
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(onThread) object:nil];
    [_thread start];
    [self performSelector:@selector(onResidentThread) onThread:self.thread withObject:nil waitUntilDone:YES];
}

- (void)onThread {
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
}

- (void)onResidentThread {
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
}

OSSpinLock spinLock = OS_SPINLOCK_INIT;

pthread_mutex_t pthreadLock;
pthread_mutexattr_t pthread_mutexattr;

os_unfair_lock_t unfairLock = &(OS_UNFAIR_LOCK_INIT);

void(^recursiveBlock)(int);

- (void)lock {
    __block int count = 0;
    
    dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    
    //1.OSSpinLock
//    for (int i = 0; i < 30; i++) {
//        dispatch_async(concurrentQueue, ^{
//            OSSpinLockLock(&spinLock);
//            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            OSSpinLockUnlock(&spinLock);
//        });
//    }
    
    //2.semaphore
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
//    for (int i = 0; i < 30; i++) {
//        dispatch_async(concurrentQueue, ^{
//            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            dispatch_semaphore_signal(semaphore);
//        });
//    }
    
    //3.pthread_mutex 非递归
//    pthread_mutex_init(&pthreadLock, NULL);
//    for (int i = 0; i < 30; i++) {
//        dispatch_async(concurrentQueue, ^{
//            pthread_mutex_lock(&pthreadLock);
//            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            pthread_mutex_unlock(&pthreadLock);
//        });
//    }
    
    //4.NSLock
//    NSLock *lock = [[NSLock alloc] init];
//    for (int i = 0; i < 30; i++) {
//        dispatch_async(concurrentQueue, ^{
//            [lock lock];
//            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            [lock unlock];
//        });
//    }
    
    //5.NSCondition
//    NSCondition *condition = [[NSCondition alloc] init];
//    dispatch_async(concurrentQueue, ^{
//        while (YES) {
//            [condition lock];
//            while (count == 0) {
//                [condition wait];
//            }
//            count--;
//            NSLog(@"消费一个");
//            [condition signal];
//            [condition unlock];
//        }
//    });
//    dispatch_async(concurrentQueue, ^{
//        while (YES) {
//            [condition lock];
//            while (count > 0) {
//                [condition wait];
//            }
//            count++;
//            NSLog(@"生产一个");
//            [condition signal];
//            [condition unlock];
//        }
//    });

    //6.pthread_mutex(recursive)
//    pthread_mutexattr_init(&pthread_mutexattr);
//    pthread_mutexattr_settype(&pthread_mutexattr, PTHREAD_MUTEX_RECURSIVE);
//    pthread_mutex_init(&pthreadLock, &pthread_mutexattr);
//    pthread_mutexattr_destroy(&pthread_mutexattr);
//    dispatch_async(concurrentQueue, ^{
//        static void(^recursiveBlock)(int) = ^(int acount) {
//            pthread_mutex_lock(&pthreadLock);
//            NSLog(@"%d\nThread:%@ \nQueue:%s", acount++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            if (acount < 30) {
//                recursiveBlock(acount);
//            }
//            pthread_mutex_unlock(&pthreadLock);
//        };
//        recursiveBlock(count);
//    });

    //7.os_unfair_lock
//    for (int i = 0; i < 30; i++) {
//        dispatch_async(concurrentQueue, ^{
//            os_unfair_lock_lock(unfairLock);
//            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            os_unfair_lock_unlock(unfairLock);
//        });
//    }
    
    //8.NSRecursiveLock
//    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc] init];
//    dispatch_async(concurrentQueue, ^{
//        recursiveBlock = ^(int acount) {
//            [recursiveLock lock];
//            NSLog(@"%d\nThread:%@ \nQueue:%s", acount++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//            if (acount < 30) {
//                recursiveBlock(acount);
//            }
//            [recursiveLock unlock];
//        };
//        recursiveBlock(count);
//    });
    
    //9.NSConditionLock
//    NSConditionLock *conditionLock = [[NSConditionLock alloc] initWithCondition:0];
//    dispatch_async(concurrentQueue, ^{
//        while (YES) {
//            [conditionLock lockWhenCondition:1];
//            count--;
//            NSLog(@"消费一个");
//            [conditionLock unlockWithCondition:0];
//        }
//    });
//    dispatch_async(concurrentQueue, ^{
//        while (YES) {
//            [conditionLock lockWhenCondition:0];
//            count++;
//            NSLog(@"生产一个");
//            [conditionLock unlockWithCondition:1];
//        }
//    });
    
    
    //10.@synchronized
//    for (int i = 0; i < 30; i++) {
//        @synchronized (self) {
//            NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//        }
//    }
//
//    dispatch_async(concurrentQueue, ^{
//        recursiveBlock = ^(int acount) {
//            @synchronized (self) {
//                NSLog(@"%d\nThread:%@ \nQueue:%s", acount++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
//                if (acount < 30) {
//                    recursiveBlock(acount);
//                }
//            }
//        };
//        recursiveBlock(count);
//    });
}

@end

