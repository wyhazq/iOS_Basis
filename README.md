# iOS_Basis



## 目录

### [**一、iOS**](#一、iOS)

#### [0.内存管理](#0.内存管理)
​    [四大原则](#四大原则)
​    [ARC处理方式](#ARC处理方式)
​    [底层实现](#底层实现)
​    [浅拷贝和深拷贝](#浅拷贝和深拷贝)
​    [内存泄漏常见场景](#内存泄漏常见场景)
​    [内存泄漏检测](#内存泄漏检测)

#### [1.block](#1.block)
​    [常见类型](#常见类型)
​    [拷贝到堆上](#拷贝到堆上)
​    [不会拷贝到堆上](#不会拷贝到堆上)
​    [捕获](#捕获)
​    [block修饰符原理](#block修饰符原理)
​    [block循环引用](#block循环引用)

#### [2.多线程](#2.多线程)
​    [线程与队列关系](#线程与队列关系)
​    [6种情况](#6种情况)
​    [dispatch_barrier](#dispatch_barrier)
​    [dispatch_after](#dispatch_after)
​    [dispatch_once](#dispatch_once)
​    [dispatch_apply](#dispatch_apply)
​    [dispatch_group](#dispatch_group)
​    [dispatch_semaphore](#dispatch_semaphore)
​    [NSOperation](#NSOperation)
​    [常驻线程](#常驻线程)
​    [线程安全](#线程安全)
​    [线程调度](#线程调度)
​    [线程状态](#线程状态)
​    [锁](#锁)

#### [3.KVO](#3.KVO)
​    [系统实现](#系统实现)
​    [手动触发](#手动触发)
​    [封装系统实现](#封装系统实现)
​    [自己实现](#自己实现)

#### [4.KVC](#4.KVC)
​    [原理](#原理)

#### [5.runtime](#5.runtime)
​    [入口函数](#入口函数)
​    [什么是runtime](#什么是runtime)
​    [结构](#结构)
​    [消息发送](#消息发送)
​    [动态解析](#动态解析)
​    [消息转发](#消息转发)
​    [方法调换](#方法调换)
​    [关联对象](#关联对象)
​    [category](#category)
​    [runtime与内存管理](#runtime与内存管理)

#### [6.runloop](#6.runloop)

​    [结构](#结构)
​    [流程](#流程)	
​    [应用](#应用)	
​    [CADisplayLink](#CADisplayLink)
​    [触摸事件响应](#触摸事件响应)

#### [7.各种优化](#7.各种优化)
​    [界面卡顿优化](#界面卡顿优化)		
​    [启动流程和优化](#启动流程和优化) 
​    [WebView优化](#WebView优化)

#### [8.调试LLDB](#8.调试LLDB)

#### [9.缓存](9.缓存)

#### [10.编译、构建](#10.编译、构建)

#### [11.三方库](#11.三方库)

#### [12.UIKit](#12.UIKit)

#### [13.Fundation](#13.Fundation)


### [**二、网络**](#二、网络)

#### [1.TCP](#1.TCP)

#### [2.HTTP](#2.HTTP)

#### [3.HTTPS](#3.HTTPS)

#### [4.HTTPDNS](#4.HTTPDNS)

#### [5.网络优化](#5.网络优化)



### [**三、架构**](#三、架构)

#### [0.组件化](#0.组件化)

#### [1.打包](#1.打包)

#### [2.项目架构分层](#2.项目架构分层)

#### [3.Hybrid](#Hybrid)

#### [4.热更新](#4.热更新)



### [**四、算法**](#四、算法)

​    [复杂度](#复杂度)		
​    [链表](#链表)		
​    [二叉树](#二叉树)		
​    [排序](#排序)

## 一、iOS



### 0.内存管理

``` objective-c
iOS内存管理分为 ARC 和 MRC。两者从内存管理的本质上讲没有区别，都是通过引用计数机制管理内存，引用计数为0时释放对象。不同的是，在 ARC 中内存管理由编译器和 runtime 协同完成。
```

#### 四大原则

``` objective-c
1.自己生成的对象，自己持有
2.非自己生成的对象，自己也能持有
3.不再需要自己持有的对象时释放
4.非自己持有的对象无法释放
```

#### ARC处理方式

``` objective-c
1.alloc，new，copy，mutableCopy 生成的对象，编译器会在作用域结束时插入release的释放代码，深拷贝不会增加引用计数，但会拷贝一份新的堆内存
2.weak 指向的对象被释放时，weak 指针被赋值为 nil
3.autorelese 对象，类方法生成的对象，交由 autoreleasePool 去管理，加入到 autoreleasePool 中的对象会延迟释放，在 autoreleasePool 释放时，加入里面的全部对象都会释放。主线程 AutoreleasePool 创建是在 RunLoop事件开始之前(push)，AutoreleasePool 释放是在一个RunLoop事件即将结束之前(pop)。注意如果遇到内存短时暴增的情况，例如循环多次创建对象时，最好手动加上一个 autoreleasePool。
4.unsafe_unretain，不纳入ARC的管理，需要自己手动管理，用于兼容iOS4的，现在已经很少用到。
```

#### 底层实现

``` objective-c
程序运行过程中生成的所有对象都会通过其内存地址映射到 table_buf 中相应的 SideTable 实例上
```

#### SideTable

``` objective-c
1.strong，引用计数会保存在对象 ISA 指针的 extra_rc 上，extra_rc + 1 等于引用计数，19位，一般都足够用。不够用时，extra_rc 值会减半，存储到 SideTable 的引用计数表(RefcountMap)中，key 为 object 内存地址取负，value 为引用计数值。
2.weak，weak 指针的地址会保存在 SideTable 的弱引用表中，key 为 object 内存地址， value 为 weak 指针数组，当 object 被释放时，会根据 object 的地址取得 weak_table_t 中 *weak_entry_t 的哈希值，找到所有对应的 weak 指针，将他们置为 nil, 然后 将 weak_entry_t 移除出 weak_table。
SideTable {
    //引用计数
    RefcountMap {
        -obj0: rc0,
        -obj1: rc1
    }
    //弱引用
    weak_table_t {
        weak_entry_t [
            //obj0
            weak_entry_t_0 {
                weak_referrer_t[weak_r_0, weak_r_1]
            },
            //obj1
            weak_entry_t_1 {
                weak_referrer_t[weak_r_0, weak_r_1]
            },
        ]
    }
}
```

#### AutoreleasePool

``` objective-c
自动释放池是一个个 AutoreleasePoolPage 组成的一个 page 是 4096 字节大小,每个 AutoreleasePoolPage 以双向链表连接起来形成一个自动释放池，内部是一个栈。
  - 创建：autoreleasePoolPush 时会加入一个边界对象
  - 加入：当对象调用 autorelease 方法时，会将对象加入 AutoreleasePoolPage 的栈中
  - 销毁：pop 时是传入边界对象,然后对 page 中从栈顶到边界对象出栈并发送 release 消息

AutoreleasePoolPage {
    *parent //pre page
    *child  //next page
    stack [
        obj11
        obj10
        POOL_BOUNDARY_1 //@autoreleasepool_1 {}
        obj01
        obj00
        POOL_BOUNDARY_0 //@autoreleasepool_0 {}
    ]
}
```

#### 浅拷贝和深拷贝

``` objective-c
copy方法利用基于NSCopying方法约定，由各类实现的copyWithZone:方法生成并持有对象的副本。
mutableCopy方法利用基于NSMutableCopying方法约定，由各类实现的mutableCopyWithZone:方法生成并持有对象的副本。
  - 浅拷贝：堆内存地址不变
  - 深拷贝：堆内存地址变了，拷贝了多一份新对象出来
  - 集合：集合对象是深拷贝，集合内元素是浅拷贝
  
NSString 的内存标识符为 strong 的话，外部可能会将 NSMutableString 赋给 NSString，不会造成安全问题，但如果不希望对象改变的话，建议使用 copy。
NSMutableString 的内存标识符不能为 copy，否则赋值之后会变成 NSString，可能造成闪退。
```

##### instancetype

``` objective-c
关联返回类型，会返回一个方法所在类类型的对象，如果类型不同，编译器会返回警告。
```

#### 内存泄漏常见场景

``` objective-c
1.两个对象互相持有或者几个对象间形成循环引用链
  
2.block 与对象间互相持有
self.mlBlock = ^{
    NSLog(@"%@", self);
};

3.NSTimer 的target持有了 self, WeakProxy 转发可以解决
_timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
```

#### 内存泄漏检测

##### MLeaksFinder 找到内存泄漏对象

``` objective-c
1.通过运行时 hook 系统的 viewdidDisappear 等页面消失的方法，在 hook 的方法里面调用添加的willDealloc（）方法。
2.NSObject的 willDealloc（）方法会有一个延迟执行 2s 的 alert 弹框，如果 2s 以后对象被释放，系统会把对象指针设置为nil，2s 以后也就不会有弹框出现，所以根据 2s 以后有没有弹框来判断对象有没有正确的释放。
3.最后会有一个 proxy 实例 objc_setAssociatedObject 在 object 上，如果上述弹窗提示未被释放的对象最后又释放了，则会调用 proxy 实例的 dealloc 方法，然后弹窗提示用户对象最终还是释放了，避免了错误的判断。

```

##### FBRetainCycleDetector 检测是否有循环引用

``` objective-c
1.找出 Object（ Timer 类型因为 Target 需要区别对待 ），每个 Object associate 的 Object，Block 这几种类型的 Strong Reference。
2.最开始就是自身，把 Self 作为根节点，沿着各个 Reference 遍历，如果形成了环，则存在循环依赖。
```

### 参考

> 1.[内存管理](https://juejin.im/post/5abe543bf265da23784064dd#heading-46) 
>
> 2.[内存管理深入](https://juejin.im/post/5ddbf5a551882572fa6a909bhttps://juejin.im/post/5ddbf5a551882572fa6a909b) 
>
> 3.[AutoreleasePool原理](https://juejin.im/post/5b052282f265da0b7156a2aa)  
>
> 4.[MLeaksFinder / FBRetainCycleDetector 分析](https://juejin.im/post/5b80fdacf265da437a469986#heading-4)



### 1.block

``` objective-c
带有自动变量的匿名函数，block也是一个对象
```



#### 常见类型

``` objective-c
1._NSConcreteStackBlock    不被强引用持有的block	
2._NSConcreteMallocBlock   常见的block
3._NSConcreteGlobalBlock   全局block

int globalBlock1_a;
void(^globalBlock1)(void) = ^{globalBlock1_a;};

- (void(^)(void))blockType:(void(^)(void))stackBlock1 {
    int a;
    __weak void(^stackBlock)(void) = ^{a;};
    self.stackBlock = ^{a;};
    NSLog(@"%@", stackBlock);
    NSLog(@"%@", stackBlock1);
    NSLog(@"%@", self.stackBlock);
    
    void(^mallocBlock)(void) = ^{a;};
    self.mallocBlock = ^{a;};
    NSLog(@"%@", mallocBlock);
    NSLog(@"%@", self.mallocBlock);
    
    void(^globalBlock)(void) = ^{};
    NSLog(@"%@", globalBlock);
    NSLog(@"%@", globalBlock1);
    
    return stackBlock;
}
```

#### 拷贝到堆上

``` objective-c
1.将block赋值给__strong指针时(强引用)
2.block作为Cocoa API方法名含有UsingBlock的方法参数时
3.block作为GCD API的方法参数时
```

#### 不会拷贝到堆上

``` objective-c
1.block作为函数的参数，除了作为GCD的参数和UsingBlock的情况
2.将block赋值给__weak指针时(弱引用)
```

#### 捕获

``` objective-c
1.block内部用到才捕获
2.自动变量，不带 __block 修饰，捕获值；带 __block 修饰，包装成一个对象，捕获其地址。
```

#### block修饰符原理 

``` objective-c
__block int a = 1;
NSLog(@"init:%p", &a);       //*stack
void(^block)(void) = ^{
    a = 2;
    NSLog(@"block:%p", &a);  //*heap
};
block();
NSLog(@"end:%p", &a);        //*heap

转换为

//1. 栈上生成一个对象block_obj_a，内部含指向自身的指针forwarding
block_obj_a {
    block_obj_a *forwarding;
    int a;
};
Block block = ^ {
    //2.对象block_obj_a被拷贝到堆上，栈上对象block_obj_a的forwarding指针指向堆上的block_obj_a对象，堆上的block_obj_a的forwarding指针指向自己，无论如何，forwarding就是指向堆上的block_obj_a
    //3.后续的所有操作都是栈上block_obj_a.forwarding(找到堆上的block_obj_a).value = xxx
		block_obj_a.forwarding.a = 2
}
NSLog(@"%d", block_obj_a.forwarding.a);
```

#### block循环引用

``` objective-c
1.循环引用，加__weak解决
2.GCD的block不会产生循环引用，queue在执行完block后会将block置为nil，防止循环引用。
```



### 2.多线程

#### 线程与队列关系

``` objective-c
一个线程可以包含多个队列

主线程和主队列：主线程执行的不一定是主队列的任务，可能是其他队列任务；主队列的任务一定会放在主线程执行。使用是否是主队列的判断来替代是否是主线程，是更严谨的做法，因为有一些Framework代码如MapKit，不仅会要求代码在主线程执行，还要求在主队列。
```

#### 安全派发到主线程

``` objective-c
static inline void dispatch_async_main(dispatch_block_t block) {
		if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
				block();
		} 
  	else {
				dispatch_async(dispatch_get_main_queue(), block);
    }
}
```

#### 派发类型

|                    | 当前队列             | 串行队列             | 并行队列             |
| ------------------ | -------------------- | -------------------- | -------------------- |
| 同步(不会开新线程) | 串行队列会死锁       | 最优先于当前队列串行 | 次优先于当前队列串行 |
| 异步               | 当前线程队列最后执行 | 子线程、并行         | 新线程并行           |

``` objective-c
dispatch_queue_main_t mainQueue = dispatch_get_main_queue();
dispatch_queue_t serialQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_SERIAL);
dispatch_queue_t concurrentQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_CONCURRENT);
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
```

#### dispatch_after 

``` objective-c
//延时
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    NSLog(@"两秒了");
});
```

#### dispatch_barrier 

``` objective-c
dispatch_queue_t concurrentQueue = dispatch_queue_create("concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
for (int i = 1; i < 4; i++) {
    dispatch_async(concurrentQueue, ^{
        NSLog(@"%d\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
}
//dispatch_barrier_async 栏栅将异步并行任务分割，也可用做互斥锁的用途
dispatch_barrier_async(concurrentQueue, ^{
    NSLog(@"\n------------------- barrier -------------------");
});
for (int i = 4; i < 7; i++) {
    dispatch_async(concurrentQueue, ^{
        NSLog(@"%d\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
}
```

#### dispatch_once 

``` objective-c
//单次执行
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    NSLog(@"只执行一次");
});

1.原子性判断block是否被执行(long的0按位取反)，执行过则return
2.没执行过则调用dispatch_once的执行方法，内部会先原子性判断token的指针是否为NULL，true则将tail插入vval链表中，执行block，并标记block已执行。
3.同时其他线程进入，判断token的指针不为空，则将线程信息插入vval链表中，线程进入等待状态
4.block执行完后，会唤醒链表中等待的线程
  
死锁：dispatch_once 内部再调用同一个 dispatch_once 会造成死锁，循环递归调用了，信号量无法释放，一直阻塞线程。
```

#### dispatch_apply 

``` objective-c
//迭代派发，如果是在当前队列派发到别的并行队列时，则会创建新线程
dispatch_async(concurrentQueue, ^{
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    dispatch_apply(100, concurrentQueue, ^(size_t i) {
        NSLog(@"%zu\nThread:%@ \nQueue:%s", i, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    });
});
```

#### GlobalQueue

``` objective-c
//并行队列
dispatch_queue_global_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
```

#### dispatch_group 

``` objective-c
//队列组：组内所有任务执行完后，才执行dispatch_group_notify
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
//dispatch_group_wait 可以阻塞当前线程，等待group执行完成，看情况需不需要阻塞线程来使用
dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
NSLog(@"start");
```

#### dispatch_semaphore

信号量小于0时阻塞当前线程，信号量可以由一个线程获取，然后由不同的线程释放。

##### 异步转同步

``` objective-c
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
dispatch_queue_t serialQueue = dispatch_queue_create("syncQueue", DISPATCH_QUEUE_SERIAL);
dispatch_async(serialQueue, ^{
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    dispatch_semaphore_signal(semaphore); //unlock
});
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER); //lock
NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
```

##### 加锁

``` objective-c
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
```

#### NSOperation

``` objective-c
//基于GCD封装
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
```

#### 常驻线程

``` objective-c
//线程执行完就会退出，如果想复用线程，需要常驻
_thread = [[NSThread alloc] initWithTarget:self selector:@selector(onThread) object:nil];
[_thread start];
[self performSelector:@selector(onResidentThread) onThread:self.thread withObject:nil waitUntilDone:YES];

- (void)onThread {
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
}

- (void)onResidentThread {
    NSLog(@"\nThread:%@ \nQueue:%s", NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
}
```

#### 锁

1.OSSpinLock, 自旋锁，会产生优先级翻转反转问题，已弃用，全部替换为os_unfair_lock。

``` objective-c
#import <libkern/OSAtomic.h>

OSSpinLock spinLock = OS_SPINLOCK_INIT;

for (int i = 0; i < 30; i++) {
    dispatch_async(concurrentQueue, ^{
        OSSpinLockLock(&spinLock);
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        OSSpinLockUnlock(&spinLock);
    });
}
```

2.semaphore, 信号量，可用作锁

``` objective-c
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
for (int i = 0; i < 30; i++) {
    dispatch_async(concurrentQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        dispatch_semaphore_signal(semaphore);
    });
}
```

3.pthread_mutex, 互斥锁

``` objective-c
#import <pthread/pthread.h>

pthread_mutex_t pthreadLock;

pthread_mutex_init(&pthreadLock, NULL);
for (int i = 0; i < 30; i++) {
    dispatch_async(concurrentQueue, ^{
        pthread_mutex_lock(&pthreadLock);
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        pthread_mutex_unlock(&pthreadLock);
    });
}

pthread_mutex_destroy(&pthreadLock);
```

4.NSLock

``` objective-c
NSLock *lock = [[NSLock alloc] init];
for (int i = 0; i < 30; i++) {
    dispatch_async(concurrentQueue, ^{
        [lock lock];
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        [lock unlock];
    });
}
```

5.NSCondition

``` objective-c
NSCondition *condition = [[NSCondition alloc] init];
dispatch_async(concurrentQueue, ^{
    while (YES) {
        [condition lock];
        while (count == 0) {
            [condition wait];
        }
        count--;
        NSLog(@"消费一个");
        [condition signal];
        [condition unlock];
    }
});
dispatch_async(concurrentQueue, ^{
    while (YES) {
        [condition lock];
        while (count > 0) {
            [condition wait];
        }
        count++;
        NSLog(@"生产一个");
        [condition signal];
        [condition unlock];
    }
});
```

6.pthread_mutex(recursive)

``` objective-c
#import <pthread/pthread.h>

pthread_mutex_t pthreadLock;
pthread_mutexattr_t pthread_mutexattr;

pthread_mutexattr_init(&pthread_mutexattr);
pthread_mutexattr_settype(&pthread_mutexattr, PTHREAD_MUTEX_RECURSIVE);
pthread_mutex_init(&pthreadLock, &pthread_mutexattr);
pthread_mutexattr_destroy(&pthread_mutexattr);
dispatch_async(concurrentQueue, ^{
    static void(^recursiveBlock)(int) = ^(int count) {
        pthread_mutex_lock(&pthreadLock);
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        if (count < 30) {
            recursiveBlock(count);
        }
        pthread_mutex_unlock(&pthreadLock);
    };
    recursiveBlock(count);
});
```

7.os_unfair_lock, 互斥锁，iOS10以后代替OSSpinLock

``` objective-c
#import <os/lock.h>

os_unfair_lock_t unfairLock = &(OS_UNFAIR_LOCK_INIT);

for (int i = 0; i < 30; i++) {
    dispatch_async(concurrentQueue, ^{
        os_unfair_lock_lock(unfairLock);
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        os_unfair_lock_unlock(unfairLock);
    });
}
```

8.NSRecursiveLock

``` objective-c
NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc] init];
dispatch_async(concurrentQueue, ^{
    recursiveBlock = ^(int acount) {
        [recursiveLock lock];
        NSLog(@"%d\nThread:%@ \nQueue:%s", acount++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
        if (acount < 30) {
            recursiveBlock(acount);
        }
        [recursiveLock unlock];
    };
    recursiveBlock(count);
});
```

9.NSConditionLock

``` objective-c
NSConditionLock *conditionLock = [[NSConditionLock alloc] initWithCondition:0];
dispatch_async(concurrentQueue, ^{
    while (YES) {
        [conditionLock lockWhenCondition:1];
        count--;
        NSLog(@"消费一个");
        [conditionLock unlockWithCondition:0];
    }
});
dispatch_async(concurrentQueue, ^{
    while (YES) {
        [conditionLock lockWhenCondition:0];
        count++;
        NSLog(@"生产一个");
        [conditionLock unlockWithCondition:1];
    }
});
```

10.@synchronized

``` objective-c
for (int i = 0; i < 30; i++) {
    @synchronized (self) {
        NSLog(@"%d\nThread:%@ \nQueue:%s", count++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
    }
}

//recursive
dispatch_async(concurrentQueue, ^{
    recursiveBlock = ^(int acount) {
        @synchronized (self) {
            NSLog(@"%d\nThread:%@ \nQueue:%s", acount++, NSThread.currentThread, dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL));
            if (acount < 30) {
                recursiveBlock(acount);
            }
        }
    };
    recursiveBlock(count);
});
```





#### 线程安全

``` objective-c
1.atomic只能保证get,set的时候线程安全，但不是真正的线程安全。atomic只是在get,set的时候加上锁，但一个线程在读，另外的几个线程在写的时候，读到的值并不确定，也有可能读的时候被另一个线程释放了。
spinlock_t& slotlock = PropertyLocks[slot];
slotlock.lock();
oldValue = *slot;
*slot = newValue;        
slotlock.unlock();
  
2.OSSpinLock 不再安全
优先级倒置，又称优先级反转、优先级逆转、优先级翻转，是一种不希望发生的任务调度状态。在该种状态下，一个高优先级任务间接被一个低优先级任务所抢先(preemtped)，使得两个任务的相对优先级被倒置。
这往往出现在一个高优先级任务等待访问一个被低优先级任务正在使用的临界资源，从而阻塞了高优先级任务；同时，该低优先级任务被一个次高优先级的任务所抢先，从而无法及时地释放该临界资源。这种情况下，该次高优先级任务获得执行权。
我们看到很多本来使用 OSSpinLock 的知名项目，都改用了其它方式替代，比如 pthread_mutex 和 dispatch_semaphore 。
那为什么其它的锁，就不会有优先级反转的问题呢？如果按照上面的想法，其它锁也可能出现优先级反转。
原因在于，其它锁出现优先级反转后，高优先级的任务不会忙等。因为处于等待状态的高优先级任务，没有占用时间片，所以低优先级任务一般都能进行下去，从而释放掉锁。
```

#### 线程调度

``` objective-c
为了帮助理解，要提一下有关线程调度的概念。
无论多核心还是单核，我们的线程运行总是 "并发" 的。
当 cpu 数量大于等于线程数量，这个时候是真正并发，可以多个线程同时执行计算。
当 cpu 数量小于线程数量，总有一个 cpu 会运行多个线程，这时候"并发"就是一种模拟出来的状态。操作系统通过不断的切换线程，每个线程执行一小段时间，让多个线程看起来就像在同时运行。这种行为就称为 "线程调度（Thread Schedule）"。
```

#### 线程状态

``` objective-c
在线程调度中，线程至少拥有三种状态 : 运行(Running),就绪(Ready),等待(Waiting)。
  
1.线程拥有的执行时间，称为 时间片 (Time Slice)，时间片 用完时，进入 Ready 状态。
2.如果在 Running 状态，时间片没有用完，就开始等待某一个事件（通常是 IO 或 同步 ），则进入 Waiting 状态。
4.如果有线程从 Running 状态离开，调度系统就会选择一个 Ready 的线程进入 Running 状态。
4.Waiting 的线程等待的事件完成后，就会进入 Ready 状态。
```

#### 参考

> [GCD详尽总结](https://juejin.im/post/5a90de68f265da4e9b592b40)
>
> [常驻线程](https://juejin.im/post/5bc5d506e51d450e6867e427)
>
> [谈iOS的锁](https://juejin.im/post/5a8fdb1c5188257a856f55a8)
>
> [深入浅出 GCD 之 dispatch_once](https://xiaozhuanlan.com/topic/7916538240)
>
> [GCD源码吐血分析(1)](https://blog.csdn.net/u013378438/article/details/81031938)
>
> [GCD源码吐血分析(2)](https://blog.csdn.net/u013378438/article/details/81076116)
>
> [深入浅出 GCD 之 dispatch_semaphore](https://xiaozhuanlan.com/topic/4365017982)



###3.KVO

#### 系统实现

``` objective-c
1.动态生成目标Class的子类NSKVONotifying_Class.
2.动态添加属性的set方法和实现
3.self指针指向子类NSKVONotifying_Class
4.等待外部调用属性的set方法
5.set方法内部依次调用super的willChangeValueForKey，set方法，didChangeValueForKey
6.didChangeValueForKey方法内部会调用Observer的observeValueForKeyPath:ofObject:change:context:方法
7.dealloc时removeObserver，内部self指针指向父类Class
```

#### 手动触发

``` objective-c
1.属性已被添加观察者
2.自己调用willChangeValueForKey和didChangeValueForKey方法即可在不改变属性值的情况下手动触发KVO，两个方法缺一不可。
```

#### 封装系统实现

``` objective-c
1.创建观察者代理类，为了方便将触发观察后的回调方法转换成block
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
  
2.创建NSObject分类，添加封装方法和移除方法
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
    NSMutableDictionary *kvoDict = self.kvoObj.kvoDict;
    if (kvoDict.count > 0) {
        [kvoDict.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self removeObserver:self.kvoObj forKeyPath:obj];
        }];
    }
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
```



#### 自己实现

``` objective-c
1.动态生成目标Class的子类KVO_Class.
2.动态添加属性的set方法和实现
3.self指针指向子类KVO_Class
4.关联对象保存观察回调block
5.等待外部调用属性的set方法
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

6.set方法内部调用super的set方法
7.获取保存在在关联对象中的block，执行block
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

8.dealloc时将self指针指向父类Class，移除动态生成的子类KVO_Class
- (void)kvo_remove {
    NSString *className = NSStringFromClass(self.class);
    if ([className hasPrefix:@"KVO_"]) {
        object_setClass(self, class_getSuperclass(self.class));
        objc_disposeClassPair(NSClassFromString(className));
    }
}
```

#### 不触发KVO

``` objective-c
1.修改成员变量不会触发，不走 set 方法
2.观察 readonly 不触发，没有 set 方法
```

#### 参考

[探寻KVO本质](https://juejin.im/post/5adab70cf265da0b736d37a8)



###4.KVC

#### 原理

setter顺序

``` objective-c
1.方法顺序: set<Key>:, _set<Key>: 
2.ivar顺序: accessInstanceVariablesDirectly returns YES 时，_<key>, _is<Key>, <key>, is<Key>
3.找不到: setValue:forUndefinedKey:
```

getter顺序

``` objective-c
1.方法顺序: get<Key>, <key>, is<Key>, _<key>
2.ivar顺序: accessInstanceVariablesDirectly returns YES 时，_<key>, _is<Key>, <key>, is<Key>
3.找不到: valueForUndefinedKey:
```

[Key-Value Coding Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/SearchImplementation.html#//apple_ref/doc/uid/20000955-CJBBBFFA)



### 5.runtime

#### 入口函数

``` objective-c
_objc_init
```

#### 什么是runtime

``` objective-c
1.OC 是一门动态语言，与 C++ 这种静态语言不同，静态语言的各种数据结构在编译期已经决定了，不能够被修改。而动态语言却可以使我们在程序运行期，动态的修改一个类的结构，如修改方法实现，绑定实例变量等
2.OC作为动态语言，它总会想办法将静态语言在编译期决定的事情，推迟到运行期来做。所以，仅有编译器是不够的，它需要一个运行时系统(runtime system)，这也就是OC的runtime系统的意义，它是OC运行框架的基石
3.所谓的runtime黑魔法，只是基于OC各种底层数据结构上的应用
```

#### 为什么OC是动态语言？

``` objective-c
1.动态语言是在运行时确定数据类型的语言，静态语言是编译器确定，这两者的区别
2.OC 是在 C 的基础上加上 Runtime 形成的一门面向对象语言，OC 的数据类型是在运行期确定的
  
例如一个 id 类型的对象 obj，调用 class 方法，会调用 objc_msgSend(obj, SEL(class))，会先获取 obj 对象的类，在从类的方法列表中找到 class 方法，然后调用，这些都是在运行期由 Runtime 去做的

所以OC是动态语言
```

#### 结构

``` objective-c
- objc_class 包含 cache_t 和 核心 class_rw_t (read write)
- class_rw_t 包含 类不可修改的原始核心 class_ro_t (read only) 和可以被 runtime 扩展的 method, property, protocol
- realizeClass 可将 Category 中定义的各种扩展附加到 class 上，在 class 没有调用 realizeClass 之前，不是真正完整的类
- objc_class 继承于objc_object， 因此，类可以看做是一类特殊的对象
- 64位下，ISA指针每一位或几位都表示了关于当前对象的信息，包含引用计数，是否被弱引用等，32位下代表的是一个 class 指针
- 元类，类对象的类，存储类方法和属性的结构，object_getClass(self) 获取，类对象self.class获取到的是 self，获取不到元类
- id objc_object *指针
```

#### 消息发送

``` objective-c
1.首先调用 id objc_msgSend(id self, SEL cmd, ...)
2.如果 obj 为 nil, return
3.获取 obj 的类，类方法则获取元类，
4.尝试在类的方法缓存列表中找 selector，尝试在类的方法列表中找 selector
5.尝试父类的方法缓存列表中找 selector，尝试在父类的方法列表中找 selector，直到NSObject
6.尝试动态解析方法 resolveMethod
7.尝试转发此消息 forwardingTargetForSelector
8.返回方法签名，将消息打包成 NSInvocation，尝试完整的消息转发 forwardInvocation
9.消息转发失败，Crash，记录日志
  
[super selector] objc_msgSendSuper(objc_super, SEL) 跳过第四步，super 并不代表某个确定的对象，区别就是从父类开始找 imp，消息的接收者还是当前类实例
```

#### 动态解析

``` objective-c
// 动态解析实例方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *methodName = NSStringFromSelector(sel);
    if ([methodName isEqualToString:@"xxx"]) {
        class_addMethod(self.class, sel, (IMP)xxx, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

// 动态解析类方法
+ (BOOL)resolveClassMethod:(SEL)sel {
    NSString *methodName = NSStringFromSelector(sel);
    if ([methodName isEqualToString:@"xxx"]) {
        class_addMethod(object_getClass(self), sel, (IMP)xxx, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
```

#### 消息转发

快速转发

``` objective-c
- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSString *methodName = NSStringFromSelector(aSelector);
    if ([methodName isEqualToString:@"xxx"]) {
        return TestClass.alloc.init;
    }
    
    return nil;
}
```

完整转发

``` objective-c
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSString *methodName = NSStringFromSelector(aSelector);
    if ([methodName isEqualToString:@"xxx"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"来到 forwardInvocation 这一步，不管有没有处理，都不会Crash，没有则Crash！");
    [anInvocation invokeWithTarget:TestClass.alloc.init];
}
```

#### 方法交换

``` objective-c
//1.获取 Class，元类 object_getClass(self)
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    Class cls = self.class;
    swizzleMethod(cls, @selector(original), @selector(swizz_original));
});

void swizzleMethod(Class cls, SEL originalSEL, SEL swizzleSEL) {
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    Method swizzleMethod = class_getInstanceMethod(cls, swizzleSEL);
    
    //2.给类添加方法，实现为交互方法的实现，添加成功说明类里没有原方法(这种情况一般父类有原方法)
    BOOL isAdd = class_addMethod(cls, originalSEL, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (isAdd) {
        //3.替换类的交换方法的实现，实现为原方法的实现，如果类里没有交换方法，实际调用 class_addMethod
        class_replaceMethod(cls, swizzleSEL, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
    else {
        //4.如果类里面有原方法，直接交换
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
}
```

#### 关联对象

``` objective-c
- (void)setAddString:(NSString *)addString {
    objc_setAssociatedObject(self, @selector(addString), addString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)addString {
    return objc_getAssociatedObject(self, _cmd);
}

// 底层实现
AssociationsManager {
    AssociationsHashMap { //单例
        Obj : ObjectAssociationMap {
            propertyKey0 : propertyValue0,
            propertyKey1 : propertyValue1
        }
    }
}
```

#### category

``` objective-c
1.加载：runtime 会分别将 category 结构体中的 instanceMethods, protocols，instanceProperties 添加到 target class 的实例方法列表，协议列表，属性列表中，会将 category 结构体中的 classMethods 添加到 target class 所对应的元类的实例方法列表中。其本质就相当于 runtime 在运行时期，修改了 target class 的结构。经过这一番修改，category 中的方法，就变成了 target class 方法列表中的一部分
2.category 可以覆盖原方法实现的原因是，category 的方法是插入到 methodlist 的头部的
3.+load 的调用是在 cateogry 加载之后的。因此，在 +load 方法中，是可以调用 category 方法的
4.category 不支持添加成员变量，因为 category 可以在运行时动态地为已有类添加新行为，category 是运行期决定的，而成员变量的内存布局在编译器就决定好了，如果支持在运行期添加成员变量的话，会破坏类原有的布局，造成可怕后果
```

#### runtime与内存管理

``` objective-c
1.Tagged Pointer，指针中包含真实的值，用于优化存储空间，内存由系统管理。
2.isa指针，指针中包含标志位nonpointer，奇数表示启用isa优化；has_assoc表示是否有关联对象；has_cxx_dtor表示对象是否有c++或者ARC析构函数；weakly_referenced表示是否被弱引用；has_sidetable_rc表示引用计数是否过大，过大要借用sidetable存储；extra_rc表示引用计数-1。
3.存：存在extra_rc中，不够用是extra_rc减半存到sidetable中
4.取：先取extra_rc的值 + 1，判断sidetable中是否有引用计数，有则取出来相加
```

#### ISA

| 成员              | 位    | 含义                                                         |
| ----------------- | ----- | ------------------------------------------------------------ |
| nonpointer        | 1bit  | 标志位。1(奇数)表示开启了isa优化，0(偶数)表示没有启用isa优化。所以，我们可以通过判断isa是否为奇数来判断对象是否启用了isa优化。 |
| has_assoc         | 1bit  | 标志位。表明对象是否有关联对象。没有关联对象的对象释放的更快。 |
| has_cxx_dtor      | 1bit  | 标志位。表明对象是否有C++或ARC析构函数。没有析构函数的对象释放的更快。 |
| shiftcls          | 33bit | 类指针的非零位。                                             |
| magic             | 6bit  | 固定为0x1a，用于在调试时区分对象是否已经初始化。             |
| weakly_referenced | 1bit  | 标志位。用于表示该对象是否被别的对象弱引用。没有被弱引用的对象释放的更快。 |
| deallocating      | 1bit  | 标志位。用于表示该对象是否正在被释放。                       |
| has_sidetable_rc  | 1bit  | 标志位。用于标识是否当前的引用计数过大，无法在isa中存储，而需要借用sidetable来存储。（这种情况大多不会发生） |
| extra_rc          | 19bit | 对象的引用计数减1。比如，一个object对象的引用计数为7，则此时extra_rc的值为6。 |



### 6.runloop

> 事件循环，当没有事件时，RunLoop 会进入休眠状态，有事件发生时， RunLoop 会去找对应的 Handler 处理事件。RunLoop 可以让线程在需要做事的时候忙起来，不需要的话就让线程休眠。



#### 结构

``` objective-c
1.线程, runloop, authreleasePool, 1:1:1
2.authreleasePool 在 runloop.entry 后创建, runloop.exit 之前销毁
3.runloop 包含：commonModes, commonModes 包含 defaultMode, eventTrackingMode 等
4.每个 mode 包含：source，observer, timer
5.runloop 与 GCD：除了 dispatch_mian, 其他由 libDispatch 驱动
thread {
    runloop {
        @authreleasePool {
            commonModes {
                defaultMode {
                    source
                    observer
                    timer
                }
                eventTrackingMode
            }
        }
    }
}
```

#### 流程

``` objective-c
1.通知Observer，即将进入runloop    //entry
do {
  2.通知Observer，即将触发Timer回调    //beforeTimer
  3.通知Observer，即将触发Source0回调    //beforeSources
  4.触发Source0回调
  5.如果有Source1，跳到9，同被唤醒时的处理一样(handle_msg)
  6.通知Observer，线程即将进入休眠   //beforeWaiting
  7.调用mach_msg等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。(大部分时间处于这里，等待被唤醒，唤醒入口)（被唤醒：基于 port 的 Source 的事件；timer；dispatch_main，手动唤醒；runloop超时；）
  8.通知Observer:，runloop的线程刚刚被唤醒了    //afterWaiting
  9.处理唤醒runloop的消息(timer，dispatch_main，source1)，然后跳回2
} whild(退出 == false) （进入loop时参数说处理完事件就返回；超时；外部停止；source，timer，observer一个都没有了；）
10.通知Observer，runloop即将退出    //exit
```

#### 应用
Timer

``` objective-c
_timer = [NSTimer countdownTimerWithInterval:1 times:60 block:^(NSTimeInterval leftSeconds) {
    NSLog(@"%lf", leftSeconds);
}];
[self.timer start]; //addToRunloop
```

常驻线程

observer

``` objective-c
//可观察beforeWaiting，优先级调到最低，作为启动完成后的一个通知，或者主线程的所有事情做完后的一个通知
CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 2000008, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
    NSLog(@"%@", [self runLoopActivityName:activity]);
});
CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopDefaultMode);
```

#### CADisplayLink

CADisplayLink是一个执行频率（fps）和屏幕刷新相同（可以修改preferredFramesPerSecond改变刷新频率）的定时器，它也需要加入到RunLoop才能执行。与NSTimer类似，CADisplayLink同样是基于CFRunloopTimerRef实现，底层使用mk_timer（可以比较加入到RunLoop前后RunLoop中timer的变化）。和NSTimer相比它精度更高（尽管NSTimer也可以修改精度），不过和NStimer类似的是如果遇到大任务它仍然存在丢帧现象。通常情况下CADisaplayLink用于构建帧动画，看起来相对更加流畅，而NSTimer则有更广泛的用处。

``` objective-c
__weak typeof(self) weakSelf = self;
_displayLink = [CADisplayLink displayLinkWithBlock:^(CADisplayLink * _Nonnull displayLink) {
    [weakSelf onDisplayLink:displayLink];
}];
[self.displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];

- (void)onDisplayLink:(CADisplayLink *)displayLink {
    if (timestamp == 0) {
        timestamp = displayLink.timestamp;
        return;
    }
    count++;
    if (displayLink.timestamp - timestamp >= 1) {
        NSLog(@"%u", count); //得到1秒的刷新次数，即FPS
        count = 0;
        timestamp = 0;
    }
}
```

#### 触摸事件响应

``` objective-c
1. 苹果注册了一个Source1来接收系统事件
2. 一个触摸事件发生后，IOKit会生成一个IOHIDEvent事件并由SpringBoard接收
3. 接收后通过mach port发送给在前台运行的App
4. App的runloop接收到触摸事件后触发回调，调用_UIApplicationHandleEventQueue进行分发
5. _UIApplicationHandleEventQueue会把触摸事件打包成UIEvent，发送给UIWindow
6. UIWindow里分两种情况处理，看是UIGesture还是触摸事件UITouch
7. UIGesture识别成功后将action发送到对应的target，结束
8. touch事件会沿着响应链查找响应者，找到之后把事件发送给响应者，结束
9. 找不到响应者则不作处理
```



### 7.各种优化



#### 界面卡顿优化



#### 检测卡顿

``` objective-c
YYFPSLabel，用CADisplayLink实现的，原理是计算一秒内CADisplayLink的trick次数
```

#### CPU

``` objective-c
1.布局
  1.1 布局排版放到后台线程，提前计算好并缓存
  1.2 复杂的视图不要用Autolayout
  1.3 减少对frame/bounds/transform的修改，避免调整视图层次、添加和移除视图
2.渲染
  2.1 文本控件排版和绘制都是在主线程进行的，当显示大量文本时，CPU 的压力会非常大。对此解决方案只有一个，那就是自定义文本控件，用 TextKit 或最底层的 CoreText 对文本异步绘制。
  2.2 CALayer 被提交到 GPU 前，CGImage 中的数据才会得到解码。这一步是发生在主线程的，并且不可避免。如果想要绕开这个机制，常见的做法是在后台线程先把图片绘制到 CGBitmapContext 中，然后从 Bitmap 直接创建图片。目前常见的网络图片库都自带这个功能。
3.对象
  3.1 不需要响应触摸的，用CALayer代替，复用代价小的类，尽量使用缓存池复用
  3.2 对象能放到后台线程去释放，则放到后台。小 Tip：给对象赋值nil, 捕获到 block 中，然后扔到后台队列去随便发送个消息以避免编译器警告，就可以让对象在后台线程销毁了。
4.线程
  4.1 利用线程池控制线程数量，防止线程重复创建和释放
5.runloop
  5.1 监听runloop的时间，在runloop处理完所有事情后，进入休眠之前(beforeWaiting)，把任务提交到主线程去执行
```

#### GPU

``` objective-c
1.图层合成
  1.1 尽量减少在短时间内大量图片的显示，尽可能将多张图片合成为一张进行显示。尽量不要让图片和视图的大小超过 GPU 的最大纹理尺寸4096×4096。
  1.2 应用应当尽量减少视图数量和层次，并在不透明的视图里标明 opaque 属性以避免无用的 Alpha 通道合成。当然，这也可以用上面的方法，把多个视图预先渲染为一张图片来显示。
2.离屏渲染
  2.1 对于只需要圆角的某些场合，也可以用一张已经绘制好的圆角图片覆盖到原本视图上面来模拟相同的视觉效果。最彻底的解决办法，就是把需要显示的图形在后台线程绘制为图片，避免使用圆角、阴影、遮罩等属性。(避免离屏渲染)
```



#### 启动流程和优化



#### main函数之前

``` objective-c
1. 加载可执行文件。（App里的所有.o文件）
2. 加载动态链接库，进行rebase指针调整和bind符号绑定。
3. ObjC的runtime初始化。 包括：ObjC相关Class的注册、category注册、selector唯一性检查等。
4. 初始化。 包括：执行+load()方法、用attribute((constructor))修饰的函数的调用、创建C++静态全局变量等。
5. 调用main函数
```

#### main函数之后

``` objective-c
1. UIApplicationMain
   1. 创建UIApplication对象
   2. 创建UIApplication的delegate对象
   3. 创建MainRunloop
   4. delegate对象开始处理(监听)系统事件(没有storyboard)
2. 根据Info.plist获得最主要storyboard的文件名,加载最主要的storyboard(有storyboard)
3. 程序启动完毕的时候, 就会调用代理的application:didFinishLaunchingWithOptions:方法
4. 在application:didFinishLaunchingWithOptions:中创建UIWindow
创建和设置UIWindow的rootViewController
5. 显示第一个窗口
```



#### 优化

main之前

``` objective-c
1. 减少使用 +load()方法
2. 优化类、方法、全局变量。减少加载启动后不会去使用的类或方法；少用C++全局变量；
3. 二进制重排？
```

main之后

``` objective-c
1. 优化首屏渲染前的功能初始化，SDK初始化那些
2. 优化主线程耗时操作，防止屏幕卡顿。首先检查首屏渲染前，主线程上的耗时操作。将耗时操作滞后或异步处理。 通常的耗时操作有：网络加载、编辑、存储图片和文件等资源。 针对耗时操作做相对应的优化即可。
3. 可以放到启动完成后的任务尽量放到启动完成后，利用runloop的observer实现
```

#### WebView优化

``` objective-c
- 预加载WebView
- 优化JSBridge
- 解耦交互
- 封装JSSDK, 统一接口和交互协议
- 拦截器传输大文件
- 离线包
```

### 8.调试LLDB

``` objective-c
控制台
a.p 打印 | 改变值，p == e --，po == e -o --
b.p/x 16进制，p/t 2进制，p/c /s 字符和字符串
c.e可以声明变量和赋值
d.LLDB无法确定返回的类型，加个强转即可
e.快捷键 continue(c)，step over(n)，step into(s)，step out(执行完当前函数)，thread return(立刻返回)

断点：
a.符号断点，在断点栏添加Symbolic
b.condition，可以为变量添加断点条件
c.action，可以添加断点时的表达式，比如打印，赋值等
```

### 9.缓存

``` objective-c
内存缓存，一般由NSCache实现，可设置数目和大小限制，超过会受到内存警告通知，线程安全类。
```

### 10.编译、构建

### 11.三方库

#### SDWebImage

``` objective-c
1.根据传入URL查询内存缓存中是否有图片，有则读取，回调
2.没有则查询磁盘缓存中是否有图片，有则读取，解码，绘制获取图片，加入内存缓存，回调
3.没有则开始下载图片
4.下载完成后解码，绘制获取图片
5.存到内存缓存和磁盘缓存中，回调
内存缓存由NSCache来实现，可以设置最大大小和数目，收到内存警告时会清除内存缓存
```

### 12.UIKit

``` objective-c
1.UIView是CALayer的delegate，是CALayer的封装，同时继承与UIResponder，负责响应交互；CALayer负责显示和动画。
2.UIButton继承链：UIControl UIView UIResponder NSObject
3.target-action：将一个动作发送给一个目标处理，原理上还是消息发送 
4.UIEvent事件：触摸，动效(设备摇动)，远程控制，按压
```

#### layoutSubviews

``` objective-c
//调用时机
1.addSubview
2.修改frame
3.setNeedsLayout
4.主动调用
```

#### 图片显示流程

``` objective-c
1.CPU (解码)
  1.1 计算frame
  1.2 解码(解压)
2.GPU (渲染)
  2.1 顶点变换计算
  2.2 光栅化
  2.3 获取颜色值
  2.4 渲染到缓冲区
  2.5 显示到屏幕
```

#### 图片解码

``` objective-c
+ (CGImageRef)CGImageCreateDecoded:(CGImageRef)cgImage {
    if (!cgImage) {
        return NULL;
    }
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGColorSpaceRef colorSpace;
    if (@available(iOS 9.0, *)) {
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
    if (!context) {
        return NULL;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return newImageRef;
}
```

#### 防止离屏渲染

``` objective-c
1.应用AsyncDisplayKit(Texture)作为主要渲染框架，对于文字和图片的异步渲染操作交由框架来处理。
2.对于图片的圆角，统一采用“precomposite”的策略，也就是不经由容器来做剪切，而是预先使用CoreGraphics为图片裁剪圆角
3.对于视频的圆角，由于实时剪切非常消耗性能，我们会创建四个白色弧形的layer盖住四个角，从视觉上制造圆角的效果
4.对于view的圆形边框，如果没有backgroundColor，可以放心使用cornerRadius来做
5.对于所有的阴影，使用shadowPath来规避离屏渲染
6.对于特殊形状的view，使用layer mask并打开shouldRasterize来对渲染结果进行缓存
7.对于模糊效果，不采用系统提供的UIVisualEffect，而是另外实现模糊效果（CIGaussianBlur），并手动管理渲染结果
```





### 13.Fundation

``` objective-c
- NSHashTable，可存弱引用的Set
- NSMapTable，可存弱引用的Dictionary
```

### 14.安全

``` objective-c
1.混淆
2.越狱检测
3.App完整性检测
4.BundleID监测
5.HTTPS
6.大额金额利用短信验证码等手段辅助
```



## 二、网络

| 层         | 协议 |
| ---------- | ---- |
| 应用层     | HTTP |
| 表示层     |      |
| 会话层     |      |
| 传输层     | TCP  |
| 网络层     | IP   |
| 数据链路层 |      |
| 物理层     |      |


### 1.TCP

#### 三次握手

``` objective-c
1.客户端发送SYN+(随机数a)到服务器（你好，听到吗）
2.服务器发送SYN+(随机数b)，ACK(a+1)到客户端（嗯嗯，你好，你能听到吗）
3.客户端发送ACK(b+1)到服务器（嗯嗯）
正常通讯
```

#### 为什么需要三次握手

``` objective-c
第二次握手后，客户端可以确认第一次握手的请求报文服务器已经收到，但此时服务器无法确认自己发出的确认报文客户端是否已经收到，所以需要进行第三次握手。TCP是可靠的连接，三次握手是保证双端连接可用的最小次数。
```

#### 四次挥手

``` objective-c
1.客户端发送FIN(随机数a)，ACK(随机数b)到服务器（再见）
2.服务器发送ACK(a+1)到客户端（嗯嗯）
3.服务器发送FIN(随机数b)到客户端（再见）
4.客户端发送ACK(b+1)到服务器（嗯嗯）
结束通讯
```

#### 问什么需要四次挥手

``` objective-c
TCP是全双工，两端之间可同时互相发送信息。

第一次挥手客户端发送断开连接请求（FIN报文）给服务器，代表客户端不会再发送数据报文了，但仍可以接收数据报文。
第二次挥手服务端可能还有相应的数据报文需要发送，因此需要先发送ACK报文，告知客户端已收到，避免客户端继续发送FIN报文。
第三次挥手服务器在处理完数据报文后，便发送给FIN报文给客户端。
第四次挥手客户端接收到FIN报文后，发送ACK报文给服务器，以断开TCP连接。
```



### 2.HTTP



#### HTTP 1.1

``` objective-c
1.keep-alive
2.pipeline（需要服务器支持）

```

#### HTTP 2.0

``` objective-c
1.重用tcp连接
2.多路复用
3.二进制传输
4.服务器推送
```



### 3.HTTPS

``` objective-c
1.客户端向服务器发起请求
2.服务器返回证书、加密公钥
3.客户端验证服务器证书的有效性(颁发机构（验证CA，再验证数字签名），host，过期时间等)
4.客户端生成随机值，用服务器公钥加密后传给服务器（RSA(随机值)，AES(HASH(握手消息))，AES(握手消息)）
5.服务器用私钥解密后，得到随机值（解密HASH值，解密握手消息，HASH(握手消息) == HASH值？）
6.使用随机值进行对称加密传输数据
```

##### 为什么数据传输使用对称加密?

``` objective-c
首先，因为非对称加解密的效率相对较低，而HTTP应用场景中通常端与端之间存在大量的交互，因此为了提升效率，数据传输使用对称加密。

另外，在HTTPS的场景中，只有服务端保存了私钥，一对公私钥只能实现单向的加解密，所以 HTTPS 中内容传输加密采取的是对称加密，而不是非对称加密。
```

##### 客户端怎样校验证书合法性

``` objective-c
客户端通常会校验证书的域名、有效期、根证书等进行校验。服务端返回的是一个证书链，末端是CA签发生成的证书，合法的根证书会内置到操作系统。

证书有效性通常是用过OCSP （在线证书状态协议 Online Certificate Status Protocol）来校验。它替代了证书注销列表（CRL），注销列表存在一些缺点，如：必须经常在客户端下载以确保列表的更新。

OCSP是IETF颁布的用于检查数字证书在某一交易时间是否有效的标准。该协议规定了服务器和客户端应用程序的通讯语法。OCSP给用户到期的证书一个宽限期，这样他们就可以在更新以前的一段时间内继续访问服务器。

参考[OCSP概览](%5BOCSP%E6%A6%82%E8%A7%88%5D(https://help.trustasia.com/what-is-ocsp/)。
```

##### 使用HTTPS为什么还是可以抓包

``` objective-c
HTTPS优点: 保证了传输安全，防止传输过程被监听、防止数据被窃取，可以确认网站的真实性。

HTTPS 传输的数据是加密的，常规下抓包工具代理请求后抓到的包内容是加密状态，无法直接查看。通常 HTTPS 抓包工具的使用方法是会生成一个证书，用户需要手动把证书安装到客户端中，然后终端发起的所有请求通过该证书完成与抓包工具的交互。

另外一般情况下，HTTPS中只会做单向的证书校验，如果存在双向校验也可以避免被抓包。
```

### 4.HTTPDNS

``` objective-c
解析域名，IP直连，防止域名劫持
```

### 5.网络优化

``` objective-c
速度：HTTPDNS、连接多路复用、数据压缩
弱网：提升连接成功率，指定最合适的超时时间，调优TCP参数，使用TCP优化算法。（mars实现了前两个）还有控制网络请求并发数。
安全：HTTPS
```



## 三、架构



### 0.组件化

使用子工程，每个子工程都是一个静态库 + bundle，子工程依赖对应的Pod三方库，主工程与子工程间通过路由进行通信

#### 静态库与动态库的区别
1. 静态库编译器就被链接到目标代码中，而动态库是程序运行的时候才被载入
2. 动态可以被多个程序共享，静态库不行

### 1.打包

fastlane



### 2.项目架构分层

### MVC，MVP，MVVM



### 3.Hybrid



### 4.热更新

#### 轻量级热更新方案

JavaScriptCore + Aspects，将Aspects的各个方法注入到JSContext中

1. JS调用注入的替换方法，传入ClassName，Selector，function。
2. OC收到后调用Aspects方法，接收到回调之后
3. 执行JS传过来的function，传入Aspects回调的参数



#### Aspects原理

1. 动态生成子类，把类的isa指针指向子类，block包装成对象
2. 把子类的`forwardInvocation`的IMP替换成`__ASPECTS_ARE_BEING_CALLED__`
3. 子类添加方法Aspects_XX，IMP为原方法的实现
4. 替换子类XX方法的IMP为`forwardInvocation`
5. 外部调用XX方法时，会直接进入转发流程，然后调用`__ASPECTS_ARE_BEING_CALLED__`
6. `__ASPECTS_ARE_BEING_CALLED__`内部会把传过来的invocation的selector(XX)替换为Aspects_XX
7. 包装好，根据切入时机调用外部回调



#### JSPatch

1. `UIView.alloc().init()` 替换成 `UIView.__c('alloc')().__c('init')()`
2. 添加和替换方法，原方法指向`forwardInvocation`到自定义的JPXXX方法，然后再调用JS



## 基础细节

### 1. 如何重写对象的 `- isEqual:`方法

```objective-c
@interface Person : NSObject
@property(copy, nonatomic) NSString *name;
@property(assign, nonatomic) NSUInteger age;
@end
  
@implementation Person

@end
```

以上面的代码为例，首先重写判断相等的方法:

```objective-c
- (BOOL)isEqual:(id)object {
  	// 指针相等，肯定相等
    if (self == object) {
        return YES;
    }
    
  	// 过滤非同类型的对比，减少类型转换带来的消耗
    if (![object isKindOfClass:[Person class]]) {
        return NO;
    }
    
    return [self isEqualToPerson:(Person *)object];
}

- (BOOL)isEqualToPerson:(Person *)person {
  	// 做参数有效性校验
    if (!person) {
        return NO;
    }
    
  	// 关键属性校验
  	BOOL hasSameName = [self.name isEqualToString:person.name];
  	BOOL hasSameAge = (self.age == person.age);
    BOOL result = (hasSameName && hasSameAge);
    return result;
}
```

上面的代码完成了对 `Person` 的 `- isEqual:` 方法的重写。

当有一个新的类 `GoodPerson` 继承自 `Person` 时，也需要重写 `- isEqual:` 方法，且需要调用父类的方法来判断是否相等:

```objective-c
- (BOOL)isEqual: (id)object
{
    // 父类判断不相等，则不相等
    if(![super isEqual: object]) {
        return NO;
    }
    
    // 父类已判定相等，子类属性对比
    GoodPerson *p = (GoodPerson *)object;
    return [self.birthday isEqual:p.birthday];
}
```



`NSSet` 、`NSDictionary` 中，无论有多少个对象，都能以很快的速度查找到我们想要的指定对象，这依赖于 `hash` 。当对象被加入到 `NSSet` 等 Hash Table 中，或者作为 `NSDictionary` 的 `key` 时， 会调用对象的 `- hash` 方法。

>A hash table is basically a big array with special indexing. Objects are placed into an array with an index that corresponds to their hash. The hash is essentially a pseudorandom number generated from the object's properties. The idea is to make the index random enough to make it unlikely for two objects to have the same hash, but have it be fully reproducible. When an object is inserted, the hash is used to determine where it goes. When an object is looked up, its hash is used to determine where to look.
>
>In more formal terms, the hash of an object is defined such that two objects have an identical hash if they are equal. Note that the reverse is not true, and can't be: two objects can have an identical hash and not be equal. You want to try to avoid this as much as possible, because when two unequal objects have the same hash (called a *collision*) then the hash table has to take special measures to handle this, which is slow. However, it's provably impossible to avoid it completely.

两个对象如果相等，那么它们的 `hash` 值必然相同，因此，当重写 `- isEqual:` 时，必须也重写 `- hash` 方法，可以使用异或 `XOR` 来快速生成多个属性结合后的 `hash` 值。

```
- (NSUInteger)hash
{
    return [_name hash] ^ _age;
}
```

参考:

- [**Implementing Equality and Hashing**](**https://www.mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html**)
- [Equality](https://nshipster.com/equality/)



## 四、算法

### 复杂度

logn:对数复杂度，while(i < n) { i = 2 * i }。



### 链表

```c
typedef struct ListNode {
    struct ListNode *next;
    int value;
} ListNode;
```

1. 创建链表
   
   ``` c
ListNode *listNodeInit(int i) {
       ListNode *node = (ListNode *)malloc(sizeof(ListNode));
       node->next = NULL;
       node->value = i;
       return node;
   }
   
   ListNode *linkedlistInit(void) {
       ListNode *head = (ListNode *)malloc(sizeof(ListNode));
       
       ListNode *temp = head; //游标
       for (int i = 0; i < 10; i++) {
           ListNode* listNode = listNodeInit(i);
           temp->next = listNode;
           temp = listNode; //游标后移
       }
       
       return head;
   }
   
   ListNode *_head;
   _head = linkedlistInit();
   ```
   
2. addListNodeAtIndex

   ``` c
   ListNode *addListNodeAtIndex(int i, ListNode *head, ListNode *listNode) {
       if (head == NULL) {
           return head;
       }
       ListNode *temp = head;
       while (i-- > 0) {
           temp = temp->next;
           if (temp == NULL) {
               return head;
           }
       }
       listNode->next = temp->next;
       temp->next = listNode;
       return head;
   }
   ```

3. 给头结点和目标节点，O(1)删除目标节点：把目标节点的下一节点值赋值给目标节点，然后删除目标节点的下一个节点
   a.目标节点node.value = node.next.value
   b.目标节点node.next = node.next.next

   ``` c
   ListNode *delListNode(ListNode *head, ListNode *listNode) {
       if (head == NULL || listNode == NULL) {
           return head;
       }
       if (listNode->next == NULL) {
           ListNode *temp = head;
           while (temp->next != listNode) {
               temp = temp->next;
           }
           temp->next = NULL;
           free(listNode);
           listNode = NULL;
           return head;
       }
       listNode->value = listNode->next->value; //将next覆盖自己
       ListNode *cur = listNode->next;
       listNode->next = cur->next; //删除next
       free(cur);
       cur = NULL;
       
       return head;
   }
   ```

4. 翻转单链表：用三个临时指针pre, cur, suf在链表上遍历一遍即可
   a.pre = null, cur = head.next, suf = cur.next
   b.while(cur.next != null) cur.next = pre, pre = cur, cur = suf, suf = suf.next

   ``` c
   ListNode *reverseLinkedList(ListNode *head) {
       if (head == NULL) {
           return head;
       }
       
       ListNode *pre = NULL;
       ListNode *cur = head->next;
       ListNode *suf = cur->next;
       
       while (suf != NULL) {
           cur->next = pre;
           pre = cur;
           cur = suf;
           suf = cur->next;
       }
       cur->next = pre;
       head->next = cur;
       
       return head;
   }
   ```

5. 删除倒数第n个节点
   a.用两个临时节点，pre 和 suf，suf先向前移n位
   b.当suf != null 或 suf.next != null，pre, suf一起向前移，直到为null
   c.此时pre.next为倒数第N个节点，删除

   ``` c
   /* 例：倒数第2
            *
    h 1 2 3 4 5
          p   s
    */
   ListNode *delListNodeAtReverseIndex(ListNode *head, int i) {
       ListNode *pre = head;
       ListNode *suf = head;
       
       while (i-- > 0) {
           suf = suf->next;
       }
       
       while (suf->next != NULL) {
           suf = suf->next;
           pre = pre->next;
       }
       
       ListNode *cur = pre->next;
       pre->next = cur->next; //删除
       free(cur);
       cur = NULL;
       
       return head;
   }
   ```

6. 求单链表的中间节点:
   a.快慢指针(fast, slow)
   b.fast每次移两位，slow移动一位，直到fast == null 或 fast.next == null时
   c.s为中间节点

   ``` c
   ListNode *midListNode(ListNode *head) {
       if (head == NULL) {
           return head;
       }
       
       ListNode *slow = head;
       ListNode *fast = head;
       while (fast != NULL && fast->next != NULL) {
           fast = fast->next->next;
           slow = slow->next;
       }
       return slow;
   }
   ```

7. 删除排序链表中重复的结点
   a.用两个临时指针，pre, cur, 重复标志位flag, 遍历
   b.如果cur.value == cur.next.value，则 cur.next = cur.next.next，flag = true, continue
   c.否则判断flag == true，删除当前节点，cur前移，pre.next = cur,flag = false, continue
   d.pre和cur正常前移

   ``` c
   ListNode *delRepeatListNodeInSortLinkedList(ListNode *head) {
       if (head == NULL) {
           return head;
       }
       
       ListNode *pre = head;
       ListNode *suf = head->next;
           
       bool isRepeat = false;
   
       while (suf->next != NULL) {
           if (suf->value == suf->next->value) { //重复了
               ListNode *temp = suf;
               suf = suf->next;
               free(temp);
               temp = NULL;
               isRepeat = true;
           }
           else {
               if (isRepeat) {
                   pre->next = suf; //重复切换到不重复的时候，需要将pre和suf链起来
                   isRepeat = false;
               }
               pre = suf;
               suf = suf->next;
           }
       }
       if (isRepeat) {
           pre->next = suf; //最后的node重复
       }
       
       return head;
   }
   ```

   

### 二叉树

``` c
typedef struct TreeNode {
    struct TreeNode *left;
    struct TreeNode *right;
    int value;
} TreeNode;
```

0.创建

``` c
TreeNode *treeNodeInit(int value) {
    TreeNode *node = (TreeNode *)malloc(sizeof(TreeNode));
    node->left = NULL;
    node->right = NULL;
    node->value = value;
    return node;
}

TreeNode *binaryTreeInit(int value, int count) {
    TreeNode *root;
    
    if (value < count) {
        root = treeNodeInit(value);
        root->left = binaryTreeInit(2 * value + 1, count);
        root->right = binaryTreeInit(2 * value + 2, count);
    }
    else {
        root = NULL;
    }
    
    return root;
}
```

1.前序遍历：根 左 右

``` c
void preOrderBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    printf("\n%d", root->value);
    preOrderBinaryTree(root->left);
    preOrderBinaryTree(root->right);
}
```

2.中序遍历：左 根 右

``` c
void inOrderBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    preOrderBinaryTree(root->left);
    printf("\n%d", root->value);
    preOrderBinaryTree(root->right);
}
```

3.后序遍历：左 右 根

```
void postOrderBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    preOrderBinaryTree(root->left);
    preOrderBinaryTree(root->right);
    printf("\n%d", root->value);
}
```

4.层序遍历

``` c
typedef struct LinkedQueueNode {
    TreeNode *treeNode;
    struct LinkedQueueNode *next;
} LinkedQueueNode;

typedef struct LinkedQueue {
    LinkedQueueNode *front;
    LinkedQueueNode *rear;
} LinkedQueue;

LinkedQueue *linkedQueueInit(void) {
    LinkedQueue *linkedQueue = (LinkedQueue *)malloc(sizeof(LinkedQueue));
    linkedQueue->front = linkedQueue->rear = (LinkedQueueNode *)malloc(sizeof(LinkedQueueNode));
    linkedQueue->front->next = NULL;
    return linkedQueue;
}

bool isQueueEmpty(LinkedQueue *linkedQueue) {
    return linkedQueue->front == linkedQueue->rear ? true : false;
}

void enqueue(LinkedQueue *linkedQueue, TreeNode *treeNode) {
    LinkedQueueNode *queueNode = (LinkedQueueNode *)malloc(sizeof(LinkedQueueNode));
    queueNode->treeNode = treeNode;
    queueNode->next = NULL;
    linkedQueue->rear->next = queueNode;
    linkedQueue->rear = queueNode;
}

LinkedQueueNode *dequeue(LinkedQueue *linkedQueue) {
    if (!isQueueEmpty(linkedQueue)) {
        LinkedQueueNode *dequeueNode = linkedQueue->front->next;
        linkedQueue->front->next = dequeueNode->next;
        //出队最后一个元素时，队尾=队头
        if (linkedQueue->rear == dequeueNode) {
            linkedQueue->rear = linkedQueue->front;
        }
        return dequeueNode;
    }
    return linkedQueue->front;
}

void layerOrderBinaryTree(TreeNode *root) {
    LinkedQueue *queue = linkedQueueInit();
    enqueue(queue, root);
    while (!isQueueEmpty(queue)) {
        LinkedQueueNode *dequeueNode = dequeue(queue);
        TreeNode *treeNode = dequeueNode->treeNode;
        printf("\n%d", treeNode->value);
        if (treeNode->left != NULL) {
            enqueue(queue, treeNode->left);
        }
        if (treeNode->right != NULL) {
            enqueue(queue, treeNode->right);
        }
        free(dequeueNode);
    }
}
```

5.翻转二叉树
从上到下，左子树和右字数对换

``` c
void mirrorBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    if (root->left == NULL && root->right == NULL) {
        return;
    }
    
    TreeNode *temp = root->left;
    root->left = root->right;
    root->right = temp;
    
    mirrorBinaryTree(root->left);
    mirrorBinaryTree(root->right);
}
```

4.堆

一种特殊的完全二叉树

堆排序

a.建立最小堆(小根堆)或者最大堆(大根堆)

b.堆首尾对换，剩下的重复a

``` c
void swap(int arr[], int left, int right) {
    int temp = arr[left];
    arr[left] = arr[right];
    arr[right] = temp;
}

int root(int child) {
    return (child - 1) / 2;
}

int left(int root) {
    return 2 * root + 1;
}

int right(int root) {
    return 2 * root + 2;
}

void maxHeap(int arr[], int count) {
    if (count < 2) {
        return;
    }
    //当前数量下构造最大堆
    for (int i = 1; i < count; i++) {
        for (int j = i; j > 0 && arr[root(j)] < arr[j]; j = root(j)) {
            swap(arr, root(j), j);
        }
    }
    
}

void heapSort(int arr[], int count) {
    do {
        maxHeap(arr, count);
        swap(arr, 0, count - 1); //最大数移动到最后
    } while (count-- > 2);
}
```



5.Top K

a.建立一个k个数的最小堆(小根堆)

b.遍历数组，与对顶比较，大于堆顶的对换堆顶

c.调整最小堆

复杂度：O(n logk)

``` c
void minHeap(int arr[], int count) {
    for (int i = 1; i < count; i++) {
        for (int j = i; arr[root(j)] > arr[j]; j = root(j)) {
            swap(arr, root(j), j);
        }
    }
}

void adjustMinHeap(int arr[], int count) {
    int j = 0;
    while ((left(j) < count && arr[left(j)] < arr[j]) || (right(j) < count && arr[right(j)] < arr[j])) {
        if (arr[left(j)] < arr[right(j)]) {
            swap(arr, left(j), j);
            j = left(j);
        }
        else {
            swap(arr, right(j), j);
            j = right(j);
        }
    }
}

void topK(int arr[], int k, int count) {
    minHeap(arr, k);
    for (int i = k; i < count; i++) {
        if (arr[0] < arr[i]) {
            swap(arr, 0, i);
            adjustMinHeap(arr, k);
        }
    }
}
```

https://zhuanlan.zhihu.com/p/37350934

https://www.cnblogs.com/xiugeng/p/9645972.html



### 排序

1.快排
分治+递归
a.找到基准数，遍历范围数组，左小右大，最后把基准数放到正确位置，返回基准数位置。
b.递归low~p-1
c.递归p+1~high

优化：基准数的选取，比如每次都在3个基准数中取中间值

``` c
/*
 *0
 5 3 1 2 4 8 6 9 0 7

 *1
           L               
 0 3 1 2 4 5 6 9 8 7
           R

 *2
 L           L
 0 3 1 2 4 5 6 9 8 7
 R           R

 *3
       L           L
 0 2 1 3 4 5 6 7 8 9
       R           R

 *4
     L         L   
 0 1 2 3 4 5 6 7 8 9
     R         R   
 */
int partition(int arr[], int left, int right) {
    int index = arr[left];
    
    while (left < right) {
        while (left < right && arr[right] > index) {
            right--;
        }
        arr[left] = arr[right];
        
        while (left < right && arr[left] < index) {
            left++;
        }
        arr[right] = arr[left];
    }
    arr[left] = index;
    
    return left;
}

void _quickSort(int arr[], int left, int right) {
    if (left < right) {
        int mid = partition(arr, left, right);
        _quickSort(arr, left, mid - 1);
        _quickSort(arr, mid + 1, right);
    }
}

void quickSort(int arr[], int count) {
    _quickSort(arr, 0, count - 1);
}

int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
int count = sizeof(arr) / sizeof(arr[0]);
quickSort(arr, count);
logArr(arr, count);
```



2.归并
a.将排序数组对半分，分到最小，然后合并它们
b.合并的过程中排序，返回已排序数组

优化：合并时可先判断arr[mid] < arr[mid + 1]，如果为true，则跳过此次合并

``` c
/*
 *0
 5 ---- 3 --- 1 -- 2 --- 4 - 8 ---- 6 --- 9 -- 0 --- 7

 *1
 3 5 --- 1 -- 2 --- 4 - 6 8 --- 9 -- 0 --- 7

 *2
 1 3 5 -- 2 4 - 6 8 9 -- 0 7

 *3
 1 2 3 4 5 - 0 6 7 8 9

 *4
 0 1 2 3 4 5 6 7 8 9
 */
void merge(int *arr, int left, int right) {
    int mid = (left + right) / 2;
    int lLen = mid - left + 1;
    int rLen = right - mid;
    
    int lArr[lLen], rArr[rLen];
    
    memcpy(lArr, arr + left, sizeof(int) * lLen);
    memcpy(rArr, arr + mid + 1, sizeof(int) * rLen);
    
    int i = 0, j = 0;
    while (i < lLen && j < rLen) {
        arr[left++] = lArr[i] < rArr[j] ? lArr[i++] : rArr[j++];
    }
    
    while (i < lLen) {
        arr[left++] = lArr[i++];
    }
    
    while (j < rLen) {
        arr[left++] = rArr[j++];
    }
}

void _mergeSort(int *arr, int left, int right) {

    if (left < right) {
        int mid = (left + right) / 2;
        
        _mergeSort(arr, left, mid);
        _mergeSort(arr, mid + 1, right);
        merge(arr, left, right);
    }
    
}

void mergeSort(int *arr, int count) {
    _mergeSort(arr, 0, count - 1);
}

int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
int count = sizeof(arr) / sizeof(arr[0]);
mergeSort(arr, count);
logArr(arr, count);
```



3.希尔排序

a.设置增量(count / 2)，插入排序

b.递归直到增量为0

优化：增量的选取

``` c
/*
 *0
 5 3 1 2 4 8 6 9 0 7

 *1: 5
 5         8
   3         6
     1         9
       2         0
         4         7
 5 3 1 0 4 8 6 9 2 7

 *2: 2
 5   1   4   6   2
 1   5   4   6   2
 1   4   5   6   2
 1   2   4   5   6
   3   0   8   9   7
   0   3   8   9   7
   0   3   7   8   9
 1 0 2 3 4 7 5 8 6 9

 *3: 1
 0 1 2 3 4 7 5 8 6 9
 0 1 2 3 4 5 7 8 6 9
 0 1 2 3 4 5 6 7 8 9
 */
void shellSort(int arr[], int count) {
    int increment = count / 2;
    int i, j, temp;
    
    for (; increment > 0; increment /= 2) {
        
        for (i = increment; i < count; i++) {
            temp = arr[i];
            
            for (j = i - increment; j >= 0 && temp < arr[j]; j -= increment) {
                arr[j + increment] = arr[j];
            }
            arr[j + increment] = temp;
        }
    }
}
```



