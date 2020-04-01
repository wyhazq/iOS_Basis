# iOS_Basis



## 目录

[**一、iOS**](#一、iOS)

[0.内存管理](#0.内存管理)

​	[四大原则](#四大原则)		[ARC处理方式](#ARC处理方式)		[底层实现](#底层实现)		[浅拷贝和深拷贝](#浅拷贝和深拷贝)		[内存泄漏常见场景](#内存泄漏常见场景)

​	[内存泄漏检测](#内存泄漏检测)

[1.block](#1.block)

​	[常见类型](#常见类型)		[拷贝到堆上](#拷贝到堆上)		[不会拷贝到堆上](#不会拷贝到堆上)		[捕获](#捕获)		[__block 原理](#__block 原理)

​	[常见问题](#常见问题)

[2.多线程](#2.多线程)

​	[线程与队列关系](#线程与队列关系)		[6种情况](#6种情况)		[dispatch_barrier](#dispatch_barrier)		[dispatch_after](#dispatch_after)		[dispatch_once](#dispatch_once)

​	[dispatch_apply](#dispatch_apply)		[dispatch_group](#dispatch_group)		[dispatch_semaphore](#dispatch_semaphore)		[NSOperation](#NSOperation)

​	[常驻线程](#常驻线程)		[线程安全](#线程安全)		[线程调度](#线程调度)		[线程状态](#线程状态)		[锁](#锁)

[3.KVO](#3.KVO)

​	[实现](#实现)		[手动触发](#手动触发)		[自己实现](#自己实现)

[4.KVC](#4.KVC)

​	[原理](#原理)

[5.runtime](#5.runtime)

​	[入口函数](#入口函数)		[什么是runtime](#什么是runtime)		[结构](#结构)		[消息发送](#消息发送)		[动态解析](#动态解析)

​	[消息转发](#消息转发)		[方法调换](#方法调换)		[category](#category)		[runtime与内存管理](#runtime与内存管理)

[6.runloop](#6.runloop)

​	[结构](#结构)		[流程](#流程)		[应用](#应用)		[CADisplayLink](#CADisplayLink)		[触摸事件响应](#触摸事件响应)

[7.各种优化](#7.各种优化)

​	[界面卡顿优化](#界面卡顿优化)		[启动流程和优化](#启动流程和优化)

[8.调试 LLDB](#8.调试 LLDB)

[9.缓存](9.缓存)

[10.编译、构建](#10.编译、构建)

[11.三方库](#11.三方库)

[12.UIKit](#12.UIKit)

[13.Fundation](#13.Fundation)



[**二、网络**](#二、网络)

[1.TCP](#1.TCP)

[2.HTTP](#2.HTTP)

[3.HTTPS](#3.HTTPS)

[4.HTTPDNS](#4.HTTPDNS)

[5.网络优化](#5.网络优化)



[**三、架构**](#三、架构)

[0.组件化](#0.组件化)

[1.打包](#1.打包)

[2.项目架构分层](#2.项目架构分层)

[3.Hybrid](#Hybrid)

[4.热更新](#4.热更新)



[**四、算法**](#四、算法)

[复杂度](#复杂度)		[链表](#链表)		[二叉树](#二叉树)		[排序](#排序)



## 一、iOS



### 0.内存管理

> iOS内存管理分为ARC和MRC。两者从内存管理的本质上讲没有区别，都是通过引用计数机制管理内存，引用计数为0时释放对象。不同的是，在ARC中内存管理由编译器和runtime协同完成。



#### 四大原则

- 自己生成的对象，自己持有。

- 非自己生成的对象，自己也能持有。

- 不再需要自己持有的对象时释放。

- 非自己持有的对象无法释放。



#### ARC处理方式

- alloc，new，copy，mutableCopy生成的对象，编译器会在作用域结束时插入release的释放代码。
- weak指向的对象被释放时，weak指针被赋值为nil
- autorelese对象，类方法生成的对象，交由autoreleasePool去管理，加入到autoreleasePool中的对象会延迟释放，在autoreleasePool释放时，加入里面的全部对象都会释放。主线程AutoreleasePool创建是在一个RunLoop事件开始之前(push)，AutoreleasePool释放是在一个RunLoop事件即将结束之前(pop)。注意如果遇到内存短时暴增的情况，例如循环多次创建对象时，最好手动加上一个autoreleasePool。
- unsafe_unretain，不纳入ARC的管理，需要自己手动管理，用于兼容iOS4的，现在已经很少用到



#### 底层实现


> 程序运行过程中生成的所有对象都会通过其内存地址映射到table_buf中相应的SideTable实例上。



- strong：引用计数会保存在isa指针和SideTable(全局有8个)的引用计数表(RefcountMap)中，key为object内存地址，value为引用计数值。[obj retain]时，引用计数表+1。

- weak：weak指针的地址会保存在SideTable的弱引用表中，key为object内存地址，value为weak指针数组，当object被释放时，会找到所有对应的weak指针，将他们置为nil。（将所有弱引用obj的指针地址都保存在obj对应的weak_entry_t中。当obj要析构时，会遍历weak_entry_t中保存的弱引用指针地址，并将弱引用指针指向nil，同时，将weak_entry_t移除出weak_table。）

- autoreleasePool：
  自动释放池是一个个 AutoreleasePoolPage 组成的一个page是4096字节大小,每个 AutoreleasePoolPage 以双向链表连接起来形成一个自动释放池，内部是一个栈。
  - 创建：autoreleasePoolPush时会加入一个边界对象
  
  - 加入：当对象调用 autorelease 方法时，会将对象加入 AutoreleasePoolPage 的栈中
  
  - 销毁：pop 时是传入边界对象,然后对page 中从栈顶到边界对象出栈并发送release消息



#### 浅拷贝和深拷贝

copy方法利用基于NSCopying方法约定，由各类实现的copyWithZone:方法生成并持有对象的副本。
mutableCopy方法利用基于NSMutableCopying方法约定，由各类实现的mutableCopyWithZone:方法生成并持有对象的副本。
浅拷贝：指向对象地址不变
深拷贝：指向对象地址变了，拷贝了多一份新对象出来
集合：集合对象是深拷贝，集合内元素是浅拷贝

##### copy
NSString的内存标识符为strong的话，外部可能会将NSMutableString赋给NSString，不会造成安全问题，但如果不希望对象改变的话，建议使用copy。
NSMutableString的内存标识符不能为copy，否则赋值之后会变成NSString，可能造成闪退。

##### instancetype
关联返回类型，会返回一个方法所在类类型的对象，能让编译在编译的时候去判断一些错误，id则不会判断。



#### 内存泄漏常见场景

- 两个对象互相持有或者几个对象间形成循环引用链

- block与对象间互相持有

- NSTimer的target持有了self (WeakProxy转发可以解决)



#### 内存泄漏检测



##### MLeaksFinder 找到内存泄漏对象

原理：
1.通过运行时 hook 系统的 viewdidDisappear 等页面消失的方法，在 hook 的方法里面调用添加的willDealloc（）方法。


2.NSObject的 willDealloc（）方法会有一个延迟执行 2s 的 alert 弹框，如果 2s 以后对象被释放，系统会把对象指针设置为nil，2s 以后也就不会有弹框出现，所以根据 2s 以后有没有弹框来判断对象有没有正确的释放。


3.最后会有一个 proxy 实例 objc_setAssociatedObject 在 object 上，如果上述弹窗提示未被释放的对象最后又释放了，则会调用 proxy 实例的 dealloc 方法，然后弹窗提示用户对象最终还是释放了，避免了错误的判断。



##### FBRetainCycleDetector 检测是否有循环引用

原理：
1.找出 Object（ Timer 类型因为 Target 需要区别对待 ），每个 Object associate 的 Object，Block 这几种类型的 Strong Reference。
2.最开始就是自身，把 Self 作为根节点，沿着各个 Reference 遍历，如果形成了环，则存在循环依赖。



### 参考

[内存管理](https://juejin.im/post/5abe543bf265da23784064dd#heading-46)
[内存管理深入](https://juejin.im/post/5ddbf5a551882572fa6a909bhttps://juejin.im/post/5ddbf5a551882572fa6a909b)
[AutoreleasePool原理](https://juejin.im/post/5b052282f265da0b7156a2aa)
[MLeaksFinder / FBRetainCycleDetector 分析](https://juejin.im/post/5b80fdacf265da437a469986#heading-4)





### 1.block

> 带有自动变量的匿名函数，block也是一个对象



#### 常见类型

- _NSConcreteStackBlock            不被强引用持有的block	
- _NSConcreteMallocBlock          常见的block
- _NSConcreteGlobalBlock          全局block



#### 拷贝到堆上
a.block作为函数返回值时
b.将block赋值给__strong指针时(强引用)
c.block作为Cocoa API方法名含有UsingBlock的方法参数时
d.block作为GCD API的方法参数时



#### 不会拷贝到堆上

a.block作为函数的参数，除了作为GCD的参数和UsingBlock的情况



#### 捕获

a.block内部用到才捕获
b.自动变量，不带 `__block` 修饰，捕获值；带 `__block` 修饰，包装成一个对象，捕获其地址。



#### __block 原理

1. 生成一个对象obj(假设地址为001)，内部含指向自身的指针 `__forwarding`(地址也为001)
2. 对象传入block中，ARC下block会拷贝到堆上，捕获的对象obj也会被拷贝到堆上，变成newObj(地址为002)
3. 通过 `obj->__forwarding` (地址还是001，访问到原对象) -> (objVal)来访问和改变其值



#### 常见问题

- 循环引用，加__weak解决

- GCD的block不会产生循环引用，queue在执行完block后会将block置为nil，防止循环引用。





### 2.多线程



#### 线程与队列关系

一个线程可以包含多个队列

主线程和主队列：主线程执行的不一定是主队列的任务，可能是其他队列任务；主队列的任务一定会放在主线程执行。使用是否是主队列的判断来替代是否是主线程（isMainThread），是更严谨的做法，因为有一些Framework代码如MapKit，不仅会要求代码在主线程执行，还要求在主队列。



安全派发到主线程的方法

``` objective-c
static inline void sh_dispatch_main_async_safe(dispatch_block_t block) {
		if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
				block();
		} 
  	else {
				dispatch_async(dispatch_get_main_queue(), block);
    }
}
```



#### 6种情况

|                    | 当前队列       | 串行队列     | 并行队列   |
| ------------------ | -------------- | ------------ | ---------- |
| 同步(不会开新线程) | 串行队列会死锁 | 串行         | 串行       |
| 异步               | 当前线程串行   | 子线程、并行 | 新线程并行 |



#### dispatch_barrier 

dispatch_barrier_async 将异步并行任务分割



#### dispatch_after 

延时



#### dispatch_once 

单次执行

原理：

1. 原子性判断block是否被执行(long的0按位取反)，执行过则return
2. 没执行过则调用dispatch_once的执行方法
3. 内部会先原子性判断token的指针是否为NULL，true则将tail插入vval链表中，执行block，并标记block已执行。
4. 同时其他线程进入，判断token的指针不为空，则将线程信息插入vval链表中，线程进入等待状态
5. block执行完后，会唤醒链表中等待的线程

死锁：

dispatch_once 内部再调用同一个 dispatch_once 会造成死锁，循环递归调用了，信号量无法释放，一直阻塞线程。



#### dispatch_apply 

快速迭代



#### dispatch_group 

队列组：组内所有任务执行完后，才执行dispatch_group_notify

- dispatch_group_async 把任务加入组内
- dispatch_group_enter 和 dispatch_group_leave 配合，效果等同A
- 组内任务执行完成后，会执行dispatch_group_notify
- dispatch_group_wait 可以阻塞当前线程，等待group执行完成，看情况需不需要阻塞线程来使用



#### dispatch_semaphore

信号量小于0时阻塞当前线程，信号量可以由一个线程获取，然后由不同的线程释放。

- 异步转同步

``` objective-c
dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //1.创建信号量为0
dispatch_async(asyncQueue, ^{
		//do something
    dispatch_semaphore_signal(semaphore); //3.信号量+1
});
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER); //2.信号量-1小于0,阻塞当前线程，等待信号量恢复
```



- 加锁

``` objective-c
dispatch_semaphore_t semaphore;
semaphore = dispatch_semaphore_create(1); //1.创建信号量为1

dispatch_async(asyncQueue1, ^{
		[self doSomeThing];
});

dispatch_async(asyncQueue2, ^{
		[self doSomeThing];
});

- (void)doSomeThing {
    //2.线程1，任务1 进入时，信号量-1为0, 任务通过并执行；
  	//线程2，任务2 进入时，信号量为-1小于0，阻塞线程2，等待信号量恢复
		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  	
  	//do something
  	
  	dispatch_semaphore_signal(semaphore); //3.信号量+1
}
```



#### NSOperation

NSOperation & NSOperarionQueue 基于GCD封装



#### 常驻线程

NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
[runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
[runLoop run];



#### 线程安全

- atomic只能保证get,set的时候线程安全，但不是真正的线程安全。atomic只是在get,set的时候加上锁，但一个线程在读，另外的几个线程在写的时候，读到的值并不确定，也有可能读的时候被另一个线程释放了。

- OSSpinLock 不再安全
  优先级倒置，又称优先级反转、优先级逆转、优先级翻转，是一种不希望发生的任务调度状态。在该种状态下，一个高优先级任务间接被一个低优先级任务所抢先(preemtped)，使得两个任务的相对优先级被倒置。
  这往往出现在一个高优先级任务等待访问一个被低优先级任务正在使用的临界资源，从而阻塞了高优先级任务；同时，该低优先级任务被一个次高优先级的任务所抢先，从而无法及时地释放该临界资源。这种情况下，该次高优先级任务获得执行权。
  我们看到很多本来使用 OSSpinLock 的知名项目，都改用了其它方式替代，比如 pthread_mutex 和 dispatch_semaphore 。
  那为什么其它的锁，就不会有优先级反转的问题呢？如果按照上面的想法，其它锁也可能出现优先级反转。
  原因在于，其它锁出现优先级反转后，高优先级的任务不会忙等。因为处于等待状态的高优先级任务，没有占用时间片，所以低优先级任务一般都能进行下去，从而释放掉锁。



#### 线程调度

为了帮助理解，要提一下有关线程调度的概念。
无论多核心还是单核，我们的线程运行总是 "并发" 的。
当 cpu 数量大于等于线程数量，这个时候是真正并发，可以多个线程同时执行计算。
当 cpu 数量小于线程数量，总有一个 cpu 会运行多个线程，这时候"并发"就是一种模拟出来的状态。操作系统通过不断的切换线程，每个线程执行一小段时间，让多个线程看起来就像在同时运行。这种行为就称为 "线程调度（Thread Schedule）"。



#### 线程状态

在线程调度中，线程至少拥有三种状态 : 运行(Running),就绪(Ready),等待(Waiting)。
处于 Running 的线程拥有的执行时间，称为 时间片 (Time Slice)，时间片 用完时，进入 Ready 状态。如果在 Running 状态，时间片没有用完，就开始等待某一个事件（通常是 IO 或 同步 ），则进入 Waiting 状态。
如果有线程从 Running 状态离开，调度系统就会选择一个 Ready 的线程进入 Running 状态。而 Waiting 的线程等待的事件完成后，就会进入 Ready 状态。



#### 锁

- 互斥锁可以分为非递归锁/递归锁两种，主要区别在于:同一个线程可以重复获取递归锁，不会死锁; 同一个线程重复获取非递归锁，则会产生死锁。@synchonized(obj)是递归锁。
- pthread_mutex作为互斥锁。不是使用忙等，而是同信号量一样，会阻塞线程并进行等待，调用时进行线程上下文切换。pthread_mutex 本身拥有设置协议的功能，通过设置它的协议，来解决优先级反转。设置协议类型为 PTHREAD_PRIO_INHERIT ，运用优先级继承的方式，可以解决优先级反转的问题。
- NSLock(非递归锁),NSRecursiveLock(递归锁) 等都是基于 pthread_mutex 做实现的。



#### NSCondition 

是通过 pthread 中的条件变量(condition variable) pthread_cond_t 来实现的。
NSConditionLock 称为条件锁，只有 condition 参数与初始化时候的 condition 相等，lock 才能正确进行加锁操作。



#### 参考

[GCD详尽总结](https://juejin.im/post/5a90de68f265da4e9b592b40)

[常驻线程](https://juejin.im/post/5bc5d506e51d450e6867e427)

[谈iOS的锁](https://juejin.im/post/5a8fdb1c5188257a856f55a8)

[深入浅出 GCD 之 dispatch_once](https://xiaozhuanlan.com/topic/7916538240)

[GCD源码吐血分析(1)](https://blog.csdn.net/u013378438/article/details/81031938)

[GCD源码吐血分析(2)](https://blog.csdn.net/u013378438/article/details/81076116)

[深入浅出 GCD 之 dispatch_semaphore](https://xiaozhuanlan.com/topic/4365017982)





###3.KVO



#### 实现
当一个对象使用了KVO监听，iOS系统会修改这个对象的isa指针，改为指向一个全新的通过Runtime动态创建的子类，子类拥有自己的set方法实现，set方法实现内部会顺序调用willChangeValueForKey方法、原来的setter方法实现、didChangeValueForKey方法，而didChangeValueForKey方法内部又会调用监听器的observeValueForKeyPath:ofObject:change:context:监听方法。



#### 手动触发
监听的属性的值被修改时，就会自动触发KVO。如果想要手动触发KVO，则需要我们自己调用willChangeValueForKey和didChangeValueForKey方法即可在不改变属性值的情况下手动触发KVO，并且这两个方法缺一不可。



#### 自己实现
1. objc_allocateClassPair 创建子类
2. objc_registerClassPair 将子类注册进运行时
3. class_addMethod 为子类添加一个Setter方法和提供Setter方法的实现
4. object_setClass 把被观察的类的isa指向子类
5. objc_setAssociatedObject 保存观察者
   Setter方法实现 (或者是按官方实现去调用，走官方回调)
   a.objc_super 获取父类
   b.objc_msgSendSuper 改变被观察的属性的值
   c.调用自定义的观察者回调

#### 不触发KVO
- 修改成员变量不会触发，因为不走set方法

#### 参考

[探寻KVO本质](https://juejin.im/post/5adab70cf265da0b736d37a8)



###4.KVC



#### 原理

当调用setValue：属性值 forKey：@”name“的代码时，底层的执行机制如下：

1. 程序优先调用set<Key>:属性值方法，代码通过setter方法完成设置。注意，这里的<key>是指成员变量名，首字母大小写要符合KVC的命名规则，下同
2. 如果没有找到setName：方法，KVC机制会检查+ (BOOL)accessInstanceVariablesDirectly方法有没有返回YES，默认该方法会返回YES，如果你重写了该方法让其返回NO的话，那么在这一步KVC会执行setValue：forUndefinedKey：方法，不过一般开发者不会这么做。所以KVC机制会搜索该类里面有没有名为_<key>的成员变量，无论该变量是在类接口处定义，还是在类实现处定义，也无论用了什么样的访问修饰符，只在存在以_<key>命名的变量，KVC都可以对该成员变量赋值。
3. 如果该类即没有set<key>：方法，也没有_<key>成员变量，KVC机制会搜索_is<Key>的成员变量。
   d.和上面一样，如果该类即没有set<Key>：方法，也没有_<key>和_is<Key>成员变量，KVC机制再会继续搜索<key>和is<Key>的成员变量。再给它们赋值。
4. .如果上面列出的方法或者成员变量都不存在，系统将会执行该对象的setValue：forUndefinedKey：方法，默认是抛出异常。
5. 如果开发者想让这个类禁用KVC里，那么重写+ (BOOL)accessInstanceVariablesDirectly方法让其返回NO即可，这样的话如果KVC没有找到set<Key>:属性名时，会直接用setValue：forUndefinedKey：方法。



### 5.runtime


#### 入口函数

_objc_init

#### 什么是runtime
- OC是一门动态语言，与C++这种静态语言不同，静态语言的各种数据结构在编译期已经决定了，不能够被修改。而动态语言却可以使我们在程序运行期，动态的修改一个类的结构，如修改方法实现，绑定实例变量等。
- OC作为动态语言，它总会想办法将静态语言在编译期决定的事情，推迟到运行期来做。所以，仅有编译器是不够的，它需要一个运行时系统(runtime system)，这也就是OC的runtime系统的意义，它是OC运行框架的基石。
- 所谓的runtime黑魔法，只是基于OC各种底层数据结构上的应用。



#### 结构

- objc_class 包含 cache_t 和 核心class_rw_t
- class_rw_t 包含 类不可修改的原始核心class_ro_t 和 可以被runtime扩展的method, property, protocol
- realizeClass 可将Category中定义的各种扩展附加到class上，在class没有调用realizeClass之前，不是真正完整的类。
- objc_class 继承于objc_object， 因此，类可以看做是一类特殊的对象。
- objc_object 仅包含一个isa_t 类型，isa_t 是一个联合，可以表示Class cls或uintptr_t bits类型。实际上在OC 2.0里面，多数时间用的是uintptr_t bits。bits是一个64位的数据，每一位或几位都表示了关于当前对象的信息。
- 元类，类对象的类，存储类方法和属性的结构，object_getClass(self)获取。
- id，objc_object *指针。



#### 消息发送

`objc_msgSend(self, SEL)`

1. 判断当前receiver是否为nil，若为nil，则不做任何响应，即向nil发送消息，系统不会crash。
2. 尝试在当前receiver对应的class的cache中查找imp
3. 尝试在class的方法列表中查找imp
4. 尝试在class的所有super classes中查找imp（先看Super class的cache，再看super class的方法列表）
5. 上面3步都没有找到对应的imp，则尝试动态解析这个SEL `resolveMethod`
6. 动态解析失败，尝试进行消息转发，让别的class处理这个SEL `forwarding`
7. 消息转发失败，程序crash并记录日志。



`objc_msgSendSuper(objc_super, SEL)`
super并不代表某个确定的对象，区别就是从父类开始找imp，消息的接收者还是当前类实例。



#### 动态解析

可以动态添加方法

+ (BOOL)resolveInstanceMethod:(SEL)sel  // 动态解析实例方法
+ (BOOL)resolveClassMethod:(SEL)sel     // 动态解析类方法



#### 消息转发
forwardingTargetForSelector 简单消息转发，转发到别的对象接收
methodSignatureForSelector 返回方法签名，用于组成NSInvocation
forwardInvocation 发送



#### 方法调换

1. 调换类方法：object_getClass((id)self);
2. class_addMethod 判断类里面是否有原方法和实现，没有则添加原方法SEL，实现为调换方法的实现。
3. class_replaceMethod会调用class_addMethod尝试添加调换方法SEL，实现为原方法的实现；如果已有调换方法，则调用method_setImplementation将调换方法的实现设置为原方法的实现(内部其实都是调用addMethod方法，区别在于是否替换实现) PS:该方法仅会查找当前类的实现。
4. method_exchangeImplementations调换两个方法的实现



#### category

- 加载：runtime会分别将category 结构体中的instanceMethods, protocols，instanceProperties添加到target class的实例方法列表，协议列表，属性列表中，会将category结构体中的classMethods添加到target class所对应的元类的实例方法列表中。其本质就相当于runtime在运行时期，修改了target class的结构。经过这一番修改，category中的方法，就变成了target class方法列表中的一部分
- 在remethodizeClass函数中实现加载逻辑，category可以覆盖原方法实现的原因是，category的方法是插入到methodlist的头部的
- +load方法的调用是在cateogry加载之后的。因此，在+load方法中，是可以调用category方法的
- 关联对象，为类的对象添加关联对象，不影响该类新创建的实例。存储在AssociationsManager中
- category不支持添加成员变量，因为category可以在运行时动态地为已有类添加新行为，category是运行期决定的，而成员变量的内存布局在编译器就决定好了，如果支持在运行期添加成员变量的话，会破坏类原有的布局，造成可怕后果。



#### runtime与内存管理

- Tagged Pointer，指针中包含真实的值，用于优化存储空间，内存由系统管理。
- isa指针，指针中包含标志位nonpointer，奇数表示启用isa优化；has_assoc表示是否有关联对象；has_cxx_dtor表示对象是否有c++或者ARC析构函数；weakly_referenced表示是否被弱引用；has_sidetable_rc表示引用计数是否过大，过大要借用sidetable存储；extra_rc表示引用计数-1。
- 存：存在extra_rc中，不够用是extra_rc减半存到sidetable中
- 取：先取extra_rc的值 + 1，判断sidetable中是否有引用计数，有则取出来相加



### 6.runloop

> 事件循环，当没有事件时，RunLoop 会进入休眠状态，有事件发生时， RunLoop 会去找对应的 Handler 处理事件。RunLoop 可以让线程在需要做事的时候忙起来，不需要的话就让线程休眠。



#### 结构

- runloop与线程：1：1，新创建的线程没有runloop，获取线程当前runloop的时候再去创建。
- runloop包含多个mode：NSCommon包含default，eventTracking；CFCommon包含default
- 一个mode包含多个source item：Source，Observer，Timer
- runloop与autoreleasePool：创建优先级最高，释放优先级最低，保证runloop的所有回调在autoreleasePool中执行，避免内存泄漏
- runloop与GCD：除了dispatch_mian，其他由libDispatch驱动



#### 流程

``` objective-c
1.通知Observer，即将进入runloop
do {
  2.通知Observer，即将触发Timer回调
  3.通知Observer，即将触发Source0回调
  4.触发Source0回调
  5.如果有Source1，跳到9，同被唤醒时的处理一样(handle_msg)
  6.通知Observer，线程即将进入休眠
  7.调用mach_msg等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。(大部分时间处于这里，等待被唤醒，唤醒入口)（被唤醒：基于 port 的Source 的事件；timer；dispatch_main，手动唤醒；runloop超时；）
  8.通知Observer:，runloop的线程刚刚被唤醒了。
  9.处理唤醒runloop的消息(timer，dispatch_main，source1)，然后跳回2
} whild(退出 == false) （进入loop时参数说处理完事件就返回；超时；外部停止；source，timer，observer一个都没有了；）
10.通知Observer，runloop即将退出。
```



#### 应用
Timer，事件响应，常驻线程



#### CADisplayLink

CADisplayLink是一个执行频率（fps）和屏幕刷新相同（可以修改preferredFramesPerSecond改变刷新频率）的定时器，它也需要加入到RunLoop才能执行。与NSTimer类似，CADisplayLink同样是基于CFRunloopTimerRef实现，底层使用mk_timer（可以比较加入到RunLoop前后RunLoop中timer的变化）。和NSTimer相比它精度更高（尽管NSTimer也可以修改精度），不过和NStimer类似的是如果遇到大任务它仍然存在丢帧现象。通常情况下CADisaplayLink用于构建帧动画，看起来相对更加流畅，而NSTimer则有更广泛的用处。



#### 触摸事件响应

1. 苹果注册了一个Source1来接收系统事件
2. 一个触摸事件发生后，IOKit会生成一个IOHIDEvent事件并由SpringBoard接收
3. 接收后通过mach port发送给在前台运行的App
4. App的runloop接收到触摸事件后触发回调，调用_UIApplicationHandleEventQueue进行分发
5. _UIApplicationHandleEventQueue会把触摸事件打包成UIEvent，发送给UIWindow
6. UIWindow里分两种情况处理，看是UIGesture还是触摸事件UITouch
7. UIGesture识别成功后将action发送到对应的target，结束
8. touch事件会沿着响应链查找响应者，找到之后把事件发送给响应者，结束
9. 找不到响应者则不作处理





### 7.各种优化



#### 界面卡顿优化



#### 检测卡顿

YYFPSLabel，用CADisplayLink实现的，原理是计算一秒内CADisplayLink的trick次数



#### CPU

1. 不需要响应触摸的，用CALayer代替，复用代价小的类，尽量使用缓存池复用
2. 减少对frame/bounds/transform的修改，避免调整视图层次、添加和移除视图
3. 对象能放到后台线程去释放，则放到后台。小 Tip：把对象捕获到 block 中，然后扔到后台队列去随便发送个消息以避免编译器警告，就可以让对象在后台线程销毁了。
4. 提前计算好布局，缓存布局。
5. 复杂视图尽量不适用Autolayout。
6. 文本宽高计算放到后台
7. 文本控件排版和绘制都是在主线程进行的，当显示大量文本时，CPU 的压力会非常大。对此解决方案只有一个，那就是自定义文本控件，用 TextKit 或最底层的 CoreText 对文本异步绘制。
8. CALayer 被提交到 GPU 前，CGImage 中的数据才会得到解码。这一步是发生在主线程的，并且不可避免。如果想要绕开这个机制，常见的做法是在后台线程先把图片绘制到 CGBitmapContext 中，然后从 Bitmap 直接创建图片。目前常见的网络图片库都自带这个功能。



#### GPU

1. 尽量减少在短时间内大量图片的显示，尽可能将多张图片合成为一张进行显示。尽量不要让图片和视图的大小超过 GPU 的最大纹理尺寸4096×4096。
2. 应用应当尽量减少视图数量和层次，并在不透明的视图里标明 opaque 属性以避免无用的 Alpha 通道合成。当然，这也可以用上面的方法，把多个视图预先渲染为一张图片来显示。
3. 对于只需要圆角的某些场合，也可以用一张已经绘制好的圆角图片覆盖到原本视图上面来模拟相同的视觉效果。最彻底的解决办法，就是把需要显示的图形在后台线程绘制为图片，避免使用圆角、阴影、遮罩等属性。(避免离屏渲染)



#### 启动流程和优化



#### main函数之前

1. 加载可执行文件。（`App`里的所有`.o`文件）
2. 加载动态链接库，进行`rebase`指针调整和`bind`符号绑定。
3. `ObjC`的`runtime`初始化。 包括：`ObjC`相关`Class`的注册、`category`注册、`selector`唯一性检查等。
4. 初始化。 包括：执行`+load()`方法、用`attribute((constructor))`修饰的函数的调用、创建`C++`静态全局变量等。
5. 调用main函数



#### main函数之后

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



#### 优化

main之前

1. 减少使用 `+load()`方法
2. 优化类、方法、全局变量。减少加载启动后不会去使用的类或方法；少用C++全局变量；
3. 二进制重排？

main之后

1. 优化首屏渲染前的功能初始化，SDK初始化那些
2. 优化主线程耗时操作，防止屏幕卡顿。首先检查首屏渲染前，主线程上的耗时操作。将耗时操作滞后或异步处理。 通常的耗时操作有：网络加载、编辑、存储图片和文件等资源。 针对耗时操作做相对应的优化即可。



### 8.调试 LLDB

控制台
a.p 打印 | 改变值，p == e --，po == e -o --
b.p/x 16进制，p/t 2进制，p/c /s 字符和字符串
c.e可以声明变量和赋值
d.LLDB无法确定返回的类型，加个强转即可
e. continue(c)，step over(n)，step into(s)，step out(执行完当前函数)，thread return(立刻返回)

断点：
a.符号断点，在断点栏添加Symbolic
b.condition，可以为变量添加断点条件
c.action，可以添加断点时的表达式，比如打印，赋值等



### 9.缓存

内存缓存，一般由NSCache实现，可设置数目和大小限制，超过会受到内存警告通知，线程安全类。



### 10.编译、构建

### 11.三方库



### 12.UIKit

- UIView是CALayer的delegate，是CALayer的封装，同时继承与UIResponder，负责响应交互；CALayer负责显示和动画。
- UIButton继承链：UIControl UIView UIResponder NSObject
- target-action：将一个动作发送给一个目标处理，原理上还是消息发送 
- UIEvent事件：触摸，动效(设备摇动)，远程控制，按压


### 13.Fundation

- NSHashTable，可存弱引用的NSSet
- NSMapTable，可存弱引用的NSDictionary







## 二、网络



### 1.TCP

#### 三次握手
1.客户端发送SYN+(随机数a)到服务器（你好，听到吗）
2.服务器发送SYN+(随机数b)，ACK(a+1)到客户端（嗯嗯，你好，你能听到吗）
3.客户端发送ACK(b+1)到服务器（嗯嗯）
正常通讯

#### 为什么需要三次握手

第二次握手后，客户端可以确认第一次握手的请求报文服务器已经收到，但此时服务器无法确认自己发出的确认报文客户端是否已经收到，所以需要进行第三次握手。TCP是可靠的连接，三次握手是保证双端连接可用的最小次数。



#### 四次挥手
1.客户端发送FIN(随机数a)，ACK(随机数b)到服务器（再见）
2.服务器发送ACK(a+1)到客户端（嗯嗯）
3.服务器发送FIN(随机数b)到客户端（再见）
4.客户端发送ACK(b+1)到服务器（嗯嗯）
结束通讯



#### 问什么需要四次挥手

TCP是全双工，两端之间可同时互相发送信息。

第一次挥手客户端发送断开连接请求（FIN报文）给服务器，代表客户端不会再发送数据报文了，但仍可以接收数据报文。

第二次挥手服务端可能还有相应的数据报文需要发送，因此需要先发送ACK报文，告知客户端已收到，避免客户端继续发送FIN报文。

第三次挥手服务器在处理完数据报文后，便发送给FIN报文给客户端。

第四次挥手客户端接收到FIN报文后，发送ACK报文给服务器，以断开TCP连接。



### 2.HTTP



#### HTTP 1.1

- keep-alive
- pipeline（需要服务器支持）



#### HTTP 2.0

- 重用tcp连接
- 多路复用
- 二进制传输
- 服务器推送



### 3.HTTPS

1. 客户端向服务器发起请求
2. 服务器返回证书、加密公钥
3. 客户端验证服务器证书的有效性(颁发机构（验证CA，再验证数字签名），host，过期时间等)
4. 客户端生成随机值，用服务器公钥加密后传给服务器（RSA(随机值)，AES(HASH(握手消息))，AES(握手消息)）
5. 服务器用私钥解密后，得到随机值（解密HASH值，解密握手消息，HASH(握手消息) == HASH值？）
6. 使用随机值进行对称加密传输数据



##### 为什么数据传输使用对称加密?

首先，因为非对称加解密的效率相对较低，而HTTP应用场景中通常端与端之间存在大量的交互，因此为了提升效率，数据传输使用对称加密。

另外，在HTTPS的场景中，只有服务端保存了私钥，一对公私钥只能实现单向的加解密，所以 HTTPS 中内容传输加密采取的是对称加密，而不是非对称加密。

##### 客户端怎样校验证书合法性

客户端通常会校验证书的域名、有效期、根证书等进行校验。服务端返回的是一个证书链，末端是CA签发生成的证书，合法的根证书会内置到操作系统。

证书有效性通常是用过OCSP （在线证书状态协议 Online Certificate Status Protocol）来校验。它替代了证书注销列表（CRL），注销列表存在一些缺点，如：必须经常在客户端下载以确保列表的更新。

OCSP是IETF颁布的用于检查数字证书在某一交易时间是否有效的标准。该协议规定了服务器和客户端应用程序的通讯语法。OCSP给用户到期的证书一个宽限期，这样他们就可以在更新以前的一段时间内继续访问服务器。

参考[OCSP概览](%5BOCSP%E6%A6%82%E8%A7%88%5D(https://help.trustasia.com/what-is-ocsp/)。

##### 使用HTTPS为什么还是可以抓包

HTTPS优点: 保证了传输安全，防止传输过程被监听、防止数据被窃取，可以确认网站的真实性。

HTTPS 传输的数据是加密的，常规下抓包工具代理请求后抓到的包内容是加密状态，无法直接查看。通常 HTTPS 抓包工具的使用方法是会生成一个证书，用户需要手动把证书安装到客户端中，然后终端发起的所有请求通过该证书完成与抓包工具的交互。

另外一般情况下，HTTPS中只会做单向的证书校验，如果存在双向校验也可以避免被抓包。



### 4.HTTPDNS

解析域名，IP直连，防止域名劫持



### 5.网络优化

速度：HTTPDNS、连接多路复用、数据压缩
弱网：提升连接成功率，指定最合适的超时时间，调优TCP参数，使用TCP优化算法。（mars实现了前两个）还有控制网络请求并发数。
安全：HTTPS



## 三、架构



### 0.组件化

使用子工程，每个子工程都是一个静态库 + bundle，子工程依赖对应的Pod三方库，主工程与子工程间通过路由进行通信



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
ListNode {
	data
	ListNode *next
}
```

1. 给头结点和目标节点，O(1)删除目标节点：把目标节点的下一节点值赋值给目标节点，然后删除目标节点的下一个节点
   a.目标节点node.value = node.next.value
   b.目标节点node.next = node.next.next

2. 翻转单链表：用三个临时指针pre, cur, suf在链表上遍历一遍即可
   a.pre = null, cur = head.next, suf = cur.next
   b.while(cur.next != null) cur.next = pre, pre = cur, cur = suf, suf = suf.next
   c.pre为头结点

3. 删除倒数第n个节点
   a.用两个临时节点，pre 和 suf，suf先向前移n位
   b.当suf != null 或 suf.next != null，pre, suf一起向前移，直到为null
   c.此时pre.next为倒数第N个节点，删除

4. 求单链表的中间节点:
   a.快慢指针(fast, slow)
   b.fast每次移两位，slow移动一位，直到fast == null 或 fast.next == null时
   c.s为中间节点

5. 删除排序链表中重复的结点
   a.用两个临时指针，pre, cur, 重复标志位flag, 遍历
   b.如果cur.value == cur.next.value，则 cur.next = cur.next.next，flag = true, continue
   c.否则判断flag == true，删除当前节点，cur前移，pre.next = cur,flag = false, continue
   d.pre和cur正常前移



### 二叉树

``` c
TreeNode {
	data
	TreeNode *left
	TreeNode *right
}
```

1.前序遍历：根 左 右

``` c
preOrder(TreeNode *node) {
	visit(node.data)
	preOrder(node.left)
	preOrder(node.right)
}
```

2.中序遍历：左 根 右

``` c
inOrder(TreeNode *node) {
	inOrder(node.left)
	visit(node.data)
	inOrder(node.right)
}
```

3.后序遍历：左 右 根

```
postOrder(TreeNode *node) {
	postOrder(node.left)
	postOrder(node.right)
	visit(node.data)
}
```

4.翻转二叉树
从上到下，左子树和右字数对换
``` c
mirror(TreeNode *node) {
  if (node == null) {
    return;
  }
  if (node.left == null && node.right == null) {
    return;
  }

  TreeNode *temp = node.left;
  node.left = node.right;
  node.right = temp;

  if (node.left != null) {
    mirror(node.left);
  }
  if (node.right != null) {
    mirror(node.right);
  }
}
```

4.堆

一种特殊的完全二叉树

堆排序

a.建立最小堆(小根堆)或者最大堆(大根堆)

b.堆首尾对换，剩下的重复a

``` c
void swap(int arr[], int i, int j) {
    int temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}

int root(int j) {
    return (j - 1) / 2;
}

int left(int j) {
    return 2 * j + 1;
}

int right(int j) {
    return 2 * j + 2;
}

void maxHeap(int arr[], int n) {
    
    for (int i = 1; i < n; i++) {
        int j = i;
        while (j > 0 && arr[root(j)] < arr[j]) {
            swap(arr, root(j), j);
            j = root(j);
        }
    }
}

void heapSort(int arr[], int n) {

    for (int i = n; i > 1; i--) {
        maxHeap(arr, i);
        swap(arr, 0, i - 1);
    }
}

int main(int argc, const char * argv[]) {
    
    int arr[] = {5, 3, 1, 2, 4, 8, 6, 9};
    int count = sizeof(arr) / sizeof(arr[0]);

    heapSort(arr, count);
    
    for (int i = 0; i < count; i++) {
        printf("%d", arr[i]);
    }

    return 0;
}
```



5.Top K

a.建立一个k个数的最小堆(小根堆)

b.遍历数组，与对顶比较，大于堆顶的对换堆顶

c.调整最小堆

复杂度：O(n logk)

``` c
void swap(int arr[], int i, int j) {
    int temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
}

int root(int j) {
    return (j - 1) / 2;
}

int left(int j) {
    return 2 * j + 1;
}

int right(int j) {
    return 2 * j + 2;
}

void minHeap(int arr[], int k) {
    
    for (int i = 1; i < k; i++) {
        int j = i;
        
        while (j > 0 && arr[root(j)] > arr[j]) {
            swap(arr, root(j), j);
            j = root(j);
        }
    }
}

void adjustMinHeap(int arr[], int k, int i) {
    if (arr[i] < arr[0]) {
        return;
    }
    
    swap(arr, 0, i);
    int j = 0;
    while ((left(j) < k && arr[j] > arr[left(j)]) || (right(j) < k && arr[j] > arr[right(j)])) {
        if (arr[left(j)] < arr[right(j)]) {
            swap(arr, j, left(j));
            j = left(j);
        }
        else {
            swap(arr, j, right(j));
            j = right(j);
        }
    }
}

void topK(int arr[], int n, int k) {
    minHeap(arr, k);
    
    for (int i = k; i < n; i++) {
        adjustMinHeap(arr, k, i);
    }
}

int main(int argc, const char * argv[]) {
    
    int arr[] = {5, 3, 1, 2, 4, 8, 6, 9};
    int count = sizeof(arr) / sizeof(arr[0]);
    int k = 3;
    topK(arr, count, k);
    
    for (int i = 0; i < k; i++) {
        printf("%d", arr[i]);
    }

    return 0;
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
    
    return index;
}

void quickSort(int arr[], int left, int right) {
    
    if (left < right) {
        int index = partition(arr, left, right);
        quickSort(arr, left, index - 1);
        quickSort(arr, index + 1, right);
    }
}

int main() {
    
    int arr[] = {5, 3, 1, 2, 4};
    int count = sizeof(arr) / sizeof(arr[0]);
    quickSort(arr, 0, count);
    for (int i = 0; i < count; i++) {
        printf("%d", arr[i]);
    }
    
    return 0;
}

```



2.归并
a.将排序数组对半分，分到最小，然后合并它们
b.合并的过程中排序，返回已排序数组

优化：合并时可先判断arr[mid] < arr[mid + 1]，如果为true，则跳过此次合并

``` c
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

void mergeSort(int *arr, int left, int right) {

    if (left < right) {
        int mid = (left + right) / 2;
        
        mergeSort(arr, left, mid);
        mergeSort(arr, mid + 1, right);
        merge(arr, left, right);
    }
    
}

int main(int argc, const char * argv[]) {
    
    int arr[] = {5, 3, 1, 2, 4, 8, 6, 9};
    int count = sizeof(arr) / sizeof(arr[0]);
    mergeSort(arr, 0, count - 1);
    for (int i = 0; i < count; i++) {
        printf("%d", arr[i]);
    }

    return 0;
}
```



3.希尔排序

a.设置一个增量分割数组，然后进行插入排序，然后缩小增量，直到增量足够小，通常为1时

b.对整体进行一次插入排序(类似于扑克牌整理顺序那样)

优化：增量的选取

``` c
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



