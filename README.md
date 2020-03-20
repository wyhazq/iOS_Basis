# iOS_Basis

一、iOS

0.内存管理

iOS内存管理分为ARC和MRC。两者从内存管理的本质上讲没有区别，都是通过引用计数机制管理内存，引用计数为0时释放对象。不同的是，在ARC中内存管理由编译器和runtime协同完成。

iOS内存管理的四大原则：
a.自己生成的对象，自己持有。
b.非自己生成的对象，自己也能持有。
c.不再需要自己持有的对象时释放。
d.非自己持有的对象无法释放。

iOS内存管理主要分为以下几种处理方式：
a.alloc，new，copy，mutableCopy生成的对象，编译器会在作用域结束时插入release的释放代码。
b.autorelese对象，类方法生成的对象，交由autoreleasePool去管理，加入到autoreleasePool中的对象会延迟释放，在autoreleasePool释放时，加入里面的全部对象都会释放。主线程AutoreleasePool创建是在一个RunLoop事件开始之前(push)，AutoreleasePool释放是在一个RunLoop事件即将结束之前(pop)。注意如果遇到内存短时暴增的情况，例如循环多次创建对象时，最好手动加上一个autoreleasePool。
c.weak指向的对象被释放时，weak指针被赋值为nil
d.unsafe_unretain，不纳入ARC的管理，需要自己手动管理，用于兼容iOS4的，现在已经很少用到

内存管理的底层实现：
程序运行过程中生成的所有对象都会通过其内存地址映射到table_buf中相应的SideTable实例上。
a.strong：引用计数会保存在isa指针和SideTable(全局有8个)的引用计数表(RefcountMap)中，key为object内存地址，value为引用计数值。[obj retain]时，引用计数表+1。
b.weak：weak指针的地址会保存在SideTable的弱引用表中，key为object内存地址，value为weak指针数组，当object被释放时，会找到所有对应的weak指针，将他们置为nil。（将所有弱引用obj的指针地址都保存在obj对应的weak_entry_t中。当obj要析构时，会遍历weak_entry_t中保存的弱引用指针地址，并将弱引用指针指向nil，同时，将weak_entry_t移除出weak_table。）
c.autoreleasePool：
自动释放池是一个个 AutoreleasePoolPage 组成的一个page是4096字节大小,每个 AutoreleasePoolPage 以双向链表连接起来形成一个自动释放池，内部是一个栈。
创建：autoreleasePoolPush时会加入一个边界对象
加入：当对象调用 autorelease 方法时，会将对象加入 AutoreleasePoolPage 的栈中
销毁：pop 时是传入边界对象,然后对page 中从栈顶到边界对象出栈并发送release消息

浅拷贝和深拷贝
copy方法利用基于NSCopying方法约定，由各类实现的copyWithZone:方法生成并持有对象的副本。
mutableCopy方法利用基于NSMutableCopying方法约定，由各类实现的mutableCopyWithZone:方法生成并持有对象的副本。
浅拷贝：指向对象地址不变
深拷贝：指向对象地址变了，拷贝了多一份新对象出来
集合：集合对象是深拷贝，元素是浅拷贝

内存泄漏常见场景：
a.两个对象互相持有或者几个对象间形成循环引用链
b.block与对象间互相持有
c.NSTimer的target持有了self

内存泄漏检测：
MLeaksFinder 找到内存泄漏对象
原理：
1.通过运行时 hook 系统的 viewdidDisappear 等页面消失的方法，在 hook 的方法里面调用添加的willDealloc（）方法。
2.NSObject的 willDealloc（）方法会有一个延迟执行 2s 的 alert 弹框，如果 2s 以后对象被释放，系统会把对象指针设置为nil，2s 以后也就不会有弹框出现，所以根据 2s 以后有没有弹框来判断对象有没有正确的释放。
3.最后会有一个 proxy 实例 objc_setAssociatedObject 在 object 上，如果上述弹窗提示未被释放的对象最后又释放了，则会调用 proxy 实例的 dealloc 方法，然后弹窗提示用户对象最终还是释放了，避免了错误的判断。

FBRetainCycleDetector 检测是否有循环引用
原理：
1.找出 Object（ Timer 类型因为 Target 需要区别对待 ），每个 Object associate 的 Object，Block 这几种类型的 Strong Reference。
2.最开始就是自身，把 Self 作为根节点，沿着各个 Reference 遍历，如果形成了环，则存在循环依赖。

参考
内存管理：https://juejin.im/post/5abe543bf265da23784064dd#heading-46
内存管理深入：https://juejin.im/post/5ddbf5a551882572fa6a909b
AutoreleasePool原理：https://juejin.im/post/5b052282f265da0b7156a2aa
MLeaksFinder / FBRetainCycleDetector 分析：https://juejin.im/post/5b80fdacf265da437a469986#heading-4

1.block

带有自动变量的匿名函数，block也是一个对象

常见类型：_NSConcreteStackBlock，_NSConcreteMallocBlock，_NSConcreteGlobalBlock

ARC下，block从栈上拷贝到堆上的情况：
a.block作为函数返回值时
b.将block赋值给__strong指针时(强引用)
c.block作为Cocoa API方法名含有UsingBlock的方法参数时
d.block作为GCD API的方法参数时

捕获：
a.block内部用到才捕获
b.自动变量，不带__block修饰，捕获值，带__block修饰，包装成一个对象，捕获其地址。

__block原理：
a.生成一个对象obj，内部含指向自身的指针__forwarding
b.对象传入block中，ARC下block会拷贝到堆上，联同这个对象obj
c.通过obj->__forwarding(访问到原对象)->(objVal)来访问和改变其值

常见问题：循环引用，加__weak解决


2.多线程

1.一个线程可以包含多个队列
主线程和主队列：主线程执行的不一定是主队列的任务，可能是其他队列任务；主队列的任务一定会放在主线程执行。使用是否是主队列的判断来替代是否是主线程（isMainThread），是更严谨的做法，因为有一些Framework代码如MapKit，不仅会要求代码在主线程执行，还要求在主队列。

2.6种情况
		主(当前)队列			串行队列			并行队列	
同步		死锁					当前线程串行		当前线程串行
异步		当前线程按加入顺序串行	新线程串行		新线程并行

3.dispatch_barrier_async 将异步并行任务分割

4.dispatch_after 延时

5.dispatch_once 单次

6.dispatch_apply 快速迭代

7.dispatch_group 队列组：组内所有任务执行完后，才执行dispatch_group_notify
a.dispatch_group_async & dispatch_group_notify 配合
b.dispatch_group_wait 阻塞当前线程
c.dispatch_group_enter & dispatch_async & dispatch_group_leave & dispatch_group_notify 配合，等同a

8.dispatch_semaphore 信号量
a.保持线程同步，将异步执行任务转换为同步执行任务
b.保证线程安全，为线程加锁
dispatch_semaphore_create & dispatch_semaphore_wait & dispatch_semaphore_signal 配合

9.NSOperation & NSOperarionQueue

10.常驻线程
NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
[runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
[runLoop run];

11.线程安全

a.atomic只能保证get,set的时候线程安全，但不是真正的线程安全。atomic只是在get,set的时候加上锁，但一个线程在读，另外的几个线程在写的时候，读到的值并不确定，也有可能读的时候被另一个线程释放了。

b.OSSpinLock 不再安全
优先级倒置，又称优先级反转、优先级逆转、优先级翻转，是一种不希望发生的任务调度状态。在该种状态下，一个高优先级任务间接被一个低优先级任务所抢先(preemtped)，使得两个任务的相对优先级被倒置。
这往往出现在一个高优先级任务等待访问一个被低优先级任务正在使用的临界资源，从而阻塞了高优先级任务；同时，该低优先级任务被一个次高优先级的任务所抢先，从而无法及时地释放该临界资源。这种情况下，该次高优先级任务获得执行权。
我们看到很多本来使用 OSSpinLock 的知名项目，都改用了其它方式替代，比如 pthread_mutex 和 dispatch_semaphore 。
那为什么其它的锁，就不会有优先级反转的问题呢？如果按照上面的想法，其它锁也可能出现优先级反转。
原因在于，其它锁出现优先级反转后，高优先级的任务不会忙等。因为处于等待状态的高优先级任务，没有占用时间片，所以低优先级任务一般都能进行下去，从而释放掉锁。

线程调度
为了帮助理解，要提一下有关线程调度的概念。
无论多核心还是单核，我们的线程运行总是 "并发" 的。
当 cpu 数量大于等于线程数量，这个时候是真正并发，可以多个线程同时执行计算。
当 cpu 数量小于线程数量，总有一个 cpu 会运行多个线程，这时候"并发"就是一种模拟出来的状态。操作系统通过不断的切换线程，每个线程执行一小段时间，让多个线程看起来就像在同时运行。这种行为就称为 "线程调度（Thread Schedule）"。

线程状态
在线程调度中，线程至少拥有三种状态 : 运行(Running),就绪(Ready),等待(Waiting)。
处于 Running 的线程拥有的执行时间，称为 时间片 (Time Slice)，时间片 用完时，进入 Ready 状态。如果在 Running 状态，时间片没有用完，就开始等待某一个事件（通常是 IO 或 同步 ），则进入 Waiting 状态。
如果有线程从 Running 状态离开，调度系统就会选择一个 Ready 的线程进入 Running 状态。而 Waiting 的线程等待的事件完成后，就会进入 Ready 状态。

信号量
信号量>0时任务可以执行，否则等待。信号量可以由一个线程获取，然后由不同的线程释放。

互斥锁
a.可以分为非递归锁/递归锁两种，主要区别在于:同一个线程可以重复获取递归锁，不会死锁; 同一个线程重复获取非递归锁，则会产生死锁。@synchonized(obj)是递归锁。
b.pthread_mutex作为互斥锁。不是使用忙等，而是同信号量一样，会阻塞线程并进行等待，调用时进行线程上下文切换。pthread_mutex 本身拥有设置协议的功能，通过设置它的协议，来解决优先级反转。设置协议类型为 PTHREAD_PRIO_INHERIT ，运用优先级继承的方式，可以解决优先级反转的问题。
c.NSLock(非递归锁),NSRecursiveLock(递归锁) 等都是基于 pthread_mutex 做实现的。
d.NSCondition 是通过 pthread 中的条件变量(condition variable) pthread_cond_t 来实现的。
e.NSConditionLock 称为条件锁，只有 condition 参数与初始化时候的 condition 相等，lock 才能正确进行加锁操作。

https://juejin.im/post/5a90de68f265da4e9b592b40  GCD
https://juejin.im/post/5bc5d506e51d450e6867e427  常驻线程
https://juejin.im/post/5a8fdb1c5188257a856f55a8 谈iOS的锁

3.KVO

1.实现
当一个对象使用了KVO监听，iOS系统会修改这个对象的isa指针，改为指向一个全新的通过Runtime动态创建的子类，子类拥有自己的set方法实现，set方法实现内部会顺序调用willChangeValueForKey方法、原来的setter方法实现、didChangeValueForKey方法，而didChangeValueForKey方法内部又会调用监听器的observeValueForKeyPath:ofObject:change:context:监听方法。

2.手动触发KVO
监听的属性的值被修改时，就会自动触发KVO。如果想要手动触发KVO，则需要我们自己调用willChangeValueForKey和didChangeValueForKey方法即可在不改变属性值的情况下手动触发KVO，并且这两个方法缺一不可。

3.自己实现KVO
a.objc_allocateClassPair 创建子类
b.objc_registerClassPair 将子类注册进运行时
c.class_addMethod 为子类添加一个Setter方法和提供Setter方法的实现
d.object_setClass 把被观察的类的isa指向子类
e.objc_setAssociatedObject 保存观察者
Setter方法实现里面 (或者是按官方实现去调用，走官方回调)
a.objc_super 获取父类
b.objc_msgSendSuper 改变被观察的属性的值
c.调用自定义的观察者回调

https://juejin.im/post/5adab70cf265da0b736d37a8

4.KVC

当调用setValue：属性值 forKey：@”name“的代码时，底层的执行机制如下：

a.程序优先调用set<Key>:属性值方法，代码通过setter方法完成设置。注意，这里的<key>是指成员变量名，首字母大小写要符合KVC的命名规则，下同
b.如果没有找到setName：方法，KVC机制会检查+ (BOOL)accessInstanceVariablesDirectly方法有没有返回YES，默认该方法会返回YES，如果你重写了该方法让其返回NO的话，那么在这一步KVC会执行setValue：forUndefinedKey：方法，不过一般开发者不会这么做。所以KVC机制会搜索该类里面有没有名为_<key>的成员变量，无论该变量是在类接口处定义，还是在类实现处定义，也无论用了什么样的访问修饰符，只在存在以_<key>命名的变量，KVC都可以对该成员变量赋值。
c.如果该类即没有set<key>：方法，也没有_<key>成员变量，KVC机制会搜索_is<Key>的成员变量。
d.和上面一样，如果该类即没有set<Key>：方法，也没有_<key>和_is<Key>成员变量，KVC机制再会继续搜索<key>和is<Key>的成员变量。再给它们赋值。
e.如果上面列出的方法或者成员变量都不存在，系统将会执行该对象的setValue：forUndefinedKey：方法，默认是抛出异常。
f.如果开发者想让这个类禁用KVC里，那么重写+ (BOOL)accessInstanceVariablesDirectly方法让其返回NO即可，这样的话如果KVC没有找到set<Key>:属性名时，会直接用setValue：forUndefinedKey：方法。

5.runtime
0.runtime的入口函数是_objc_init

1.什么是runtime？
a.OC是一门动态语言，与C++这种静态语言不同，静态语言的各种数据结构在编译期已经决定了，不能够被修改。而动态语言却可以使我们在程序运行期，动态的修改一个类的结构，如修改方法实现，绑定实例变量等。
b.OC作为动态语言，它总会想办法将静态语言在编译期决定的事情，推迟到运行期来做。所以，仅有编译器是不够的，它需要一个运行时系统(runtime system)，这也就是OC的runtime系统的意义，它是OC运行框架的基石。
c.所谓的runtime黑魔法，只是基于OC各种底层数据结构上的应用。

2.结构
a.objc_class 包含 cache_t 和 核心class_rw_t
b.class_rw_t 包含 类不可修改的原始核心class_ro_t 和 可以被runtime扩展的method, property, protocol
c.realizeClass 可将Category中定义的各种扩展附加到class上，在class没有调用realizeClass之前，不是真正完整的类。
d.objc_class 继承于objc_object， 因此，类可以看做是一类特殊的对象。
e.objc_object 仅包含一个isa_t 类型，isa_t 是一个联合，可以表示Class cls或uintptr_t bits类型。实际上在OC 2.0里面，多数时间用的是uintptr_t bits。bits是一个64位的数据，每一位或几位都表示了关于当前对象的信息。
f.元类，类对象的类，存储类方法和属性的结构，object_getClass(self)获取。
g.id，objc_object *指针。

3.消息发送
objc_msgSend(self, SEL)
a.判断当前receiver是否为nil，若为nil，则不做任何响应，即向nil发送消息，系统不会crash。
b.尝试在当前receiver对应的class的cache中查找imp
c.尝试在class的方法列表中查找imp
d.尝试在class的所有super classes中查找imp（先看Super class的cache，再看super class的方法列表）
e.上面3步都没有找到对应的imp，则尝试动态解析这个SEL
f.动态解析失败，尝试进行消息转发，让别的class处理这个SEL
g.消息转发失败，程序crash并记录日志。

objc_msgSendSuper(objc_super, SEL)
super并不代表某个确定的对象，区别就是从父类开始找imp，消息的接收者还是当前类实例。

动态解析：可以动态添加方法
+ (BOOL)resolveInstanceMethod:(SEL)sel  // 动态解析实例方法
+ (BOOL)resolveClassMethod:(SEL)sel     // 动态解析类方法

消息转发
forwardingTargetForSelector 转发到别的对象接收
methodSignatureForSelector 返回方法签名，用于组成NSInvocation
forwardInvocation 发送

方法调换
a.调换类方法：object_getClass((id)self);
b.class_addMethod 判断类里面是否有原方法和实现，没有则添加原方法SEL，实现为调换方法的实现。
c.class_replaceMethod会调用class_addMethod尝试添加调换方法SEL，实现为原方法的实现；如果已有调换方法，则调用method_setImplementation将调换方法的实现设置为原方法的实现(内部其实都是调用addMethod方法，区别在于是否替换实现) PS:该方法仅会查找当前类的实现。
d.method_exchangeImplementations调换两个方法的实现

category
a.加载：runtime会分别将category 结构体中的instanceMethods, protocols，instanceProperties添加到target class的实例方法列表，协议列表，属性列表中，会将category结构体中的classMethods添加到target class所对应的元类的实例方法列表中。其本质就相当于runtime在运行时期，修改了target class的结构。经过这一番修改，category中的方法，就变成了target class方法列表中的一部分
b.在remethodizeClass函数中实现加载逻辑，category可以覆盖原方法实现的原因是，category的方法是插入到methodlist的头部的
c.+load方法的调用是在cateogry加载之后的。因此，在+load方法中，是可以调用category方法的
d.关联对象，为类的对象添加关联对象，不影响该类新创建的实例。存储在AssociationsManager中。

runtime与内存管理
a.Tagged Pointer，指针中包含真实的值，用于优化存储空间，内存由系统管理。
b.isa指针，指针中包含标志位nonpointer，奇数表示启用isa优化；has_assoc表示是否有关联对象；has_cxx_dtor表示对象是否有c++或者ARC析构函数；weakly_referenced表示是否被弱引用；has_sidetable_rc表示引用计数是否过大，过大要借用sidetable存储；extra_rc表示引用计数-1。
存：存在extra_rc中，不够用是extra_rc减半存到sidetable中
取：先取extra_rc的值 + 1，判断sidetable中是否有引用计数，有则取出来相加

6.runloop

概念：
事件循环，当没有事件时，RunLoop 会进入休眠状态，有事件发生时， RunLoop 会去找对应的 Handler 处理事件。RunLoop 可以让线程在需要做事的时候忙起来，不需要的话就让线程休眠。

结构：
runloop与线程：1：1，新创建的线程没有runloop，获取线程当前runloop的时候再去创建。
runloop包含多个mode：common(default，eventTracking)(default[CF])
一个mode包含多个source item：Source，Observer，Timer
runloop与autoreleasePool：创建优先级最高，释放优先级最低，保证runloop的所有回调在autoreleasePool中执行，避免内存泄漏
runloop与GCD：除了dispatch_mian，其他由libDispatch驱动

流程：
1.通知Observer，即将进入runloop
do {
    2.通知Observer，即将触发Timer回调
    3.通知Observer，即将触发Source0回调
    4.触发Source0回调
    5.如果有Source1，跳到9，同被唤醒时的处理一样(handle_msg)
    6.通知Observer，线程即将进入休眠
    7.调用mach_msg等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。(大部分时间处于这里，等待被唤醒，唤醒入口)（被唤醒：基于 port 的Source 的事件；timer；dispatch_main，手动唤醒；runloop超时；）
    8.通知Observer:，runloop的线程刚刚被唤醒了。
    9.处理唤醒runloop的消息(timer，dispatch_main，source1)
} whild(退出 == false) （进入loop时参数说处理完事件就返回；超时；外部停止；source，timer，observer一个都没有了；）
10.通知Observer，runloop即将退出。

应用：
Timer，事件响应，常驻线程

CADisplayLink
CADisplayLink是一个执行频率（fps）和屏幕刷新相同（可以修改preferredFramesPerSecond改变刷新频率）的定时器，它也需要加入到RunLoop才能执行。与NSTimer类似，CADisplayLink同样是基于CFRunloopTimerRef实现，底层使用mk_timer（可以比较加入到RunLoop前后RunLoop中timer的变化）。和NSTimer相比它精度更高（尽管NSTimer也可以修改精度），不过和NStimer类似的是如果遇到大任务它仍然存在丢帧现象。通常情况下CADisaplayLink用于构建帧动画，看起来相对更加流畅，而NSTimer则有更广泛的用处。

7.各种优化

界面卡顿优化
CPU：
1.不需要响应触摸的，用CALayer代替，复用代价小的类，尽量使用缓存池复用
2.减少对frame/bounds/transform的修改，避免调整视图层次、添加和移除视图
3.对象能放到后台线程去释放，则放到后台。小 Tip：把对象捕获到 block 中，然后扔到后台队列去随便发送个消息以避免编译器警告，就可以让对象在后台线程销毁了。
4.提前计算好布局，缓存布局。
5.复杂视图尽量不适用Autolayout。
6.文本宽高计算放到后台
7.文本控件排版和绘制都是在主线程进行的，当显示大量文本时，CPU 的压力会非常大。对此解决方案只有一个，那就是自定义文本控件，用 TextKit 或最底层的 CoreText 对文本异步绘制。
8. CALayer 被提交到 GPU 前，CGImage 中的数据才会得到解码。这一步是发生在主线程的，并且不可避免。如果想要绕开这个机制，常见的做法是在后台线程先把图片绘制到 CGBitmapContext 中，然后从 Bitmap 直接创建图片。目前常见的网络图片库都自带这个功能。

GPU：
1.尽量减少在短时间内大量图片的显示，尽可能将多张图片合成为一张进行显示。尽量不要让图片和视图的大小超过 GPU 的最大纹理尺寸4096×4096。
2.应用应当尽量减少视图数量和层次，并在不透明的视图里标明 opaque 属性以避免无用的 Alpha 通道合成。当然，这也可以用上面的方法，把多个视图预先渲染为一张图片来显示。
3.对于只需要圆角的某些场合，也可以用一张已经绘制好的圆角图片覆盖到原本视图上面来模拟相同的视觉效果。最彻底的解决办法，就是把需要显示的图形在后台线程绘制为图片，避免使用圆角、阴影、遮罩等属性。

8.调试 LLDB
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

9.编译、构建

10.三方库

11.启动流程和优化


二、网络

1.IP，TCP，HTTP，HTTPS，Socket

TCP
三次握手
1.客户端发送SYN(随机数a)到服务器（你好，听到吗）
2.服务器发送SYN(随机数b)，ACK(a+1)到客户端（嗯嗯，你好，你能听到吗）
3.客户端发送ACK(b+1)到服务器（嗯嗯）
正常通讯

四次挥手
1.客户端发送FIN(随机数a)，ACK(随机数b)到服务器（再见）
2.服务器发送ACK(a+1)到客户端（嗯嗯）
3.服务器发送FIN(随机数b)到客户端（再见）
4.客户端发送ACK(b+1)到服务器（嗯嗯）
结束通讯

HTTP 1.1
1.keep-alive
2.pipeline（需要服务器支持）

HTTP 2.0
1.重用tcp连接
2.多路复用
3.二进制传输
4.服务器推送

HTTPS
1.客户端向服务器发起请求
2.服务器返回证书、加密公钥
3.客户端验证服务器证书的有效性(颁发机构（验证CA，再验证数字签名），host，过期时间等)
4.客户端生成随机值，用服务器公钥加密后传给服务器（RSA(随机值)，AES(HASH(握手消息))，AES(握手消息)）
5.服务器用私钥解密后，得到随机值（解密HASH值，解密握手消息，HASH(握手消息) == HASH值？）
6.使用随机值进行对称加密传输数据

HTTPDNS
1.解析域名，IP直连，防止域名劫持

2.网络优化
速度：HTTPDNS、连接多路复用、数据压缩
弱网：提升连接成功率，指定最合适的超时时间，调优TCP参数，使用TCP优化算法。（mars实现了前两个）还有控制网络请求并发数。
安全：HTTPS

三、架构

0.组件化 & 打包

1.MVC，MVP，MVVM

2.Hybrid

3.热更新

四、算法