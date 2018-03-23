//
//  ViewController.m
//  DMGCD
//
//  Created by lbq on 2017/9/12.
//  Copyright © 2017年 lbq. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "DMCache.h"

static NSInteger kMaxIndex = 50;

static NSInteger kPerValue = 1;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)startAction:(id)sender {
    ////https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html#//apple_ref/doc/uid/TP40008091-CH103-SW22
    [self dispatch_source_4];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//MARK: dispatch barrier

/**
 dispatch_barrier_async一般叫做“栅栏函数”，它就好像栅栏一样可以将多个操作分隔开，在它前面追加的操作先执行，在它后面追加的操作后执行。
 栅栏函数也可以执行队列上的操作(参数列表中有queue和block)，也有对应的 dispatch_barrier_sync 函数。
 
 注意：The queue you specify should be a concurrent queue that you create yourself using the dispatch_queue_create function. If the queue you pass to this function is a serial queue or one of the global concurrent queues, this function behaves like the dispatch_async function.
 dispatch_barrier_async函数中传入的参数队列必须是由 dispatch_queue_create 方法创建的队列，
 如果参数传入的队列是 dispatch_get_global_queue 或者是 串行队列，那么dispatch_barrier_async相当于dispatch_async。
 对于dispatch_barrier_sync也是同理。
 应用：
 我们可以利用 dispatch_barrier 的特性实现读写安全的模型.
 */
- (void)dispatch_barrier_1
{
    dispatch_queue_t queue = dispatch_queue_create("com.leoliu.concurrent",DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"1");
    });
    dispatch_async(queue, ^{
        sleep(5);
        NSLog(@"2");
    });
    dispatch_async(queue, ^{
        NSLog(@"3");
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"barrier");
        sleep(5);
    });
    
    dispatch_async(queue, ^{
        sleep(1);
        NSLog(@"4");
    });
    dispatch_async(queue, ^{
        sleep(2);
        NSLog(@"5");
    });
    dispatch_async(queue, ^{
        NSLog(@"6");
    });
    dispatch_async(queue, ^{
        NSLog(@"7");
    });
    
    
    
    NSLog(@"over");
    /**
     结果：
     1
     3
     2
     barrier
     6
     4
     7
     5
     结论：
     barrier：之前的执行完成之后 才会执行barrier中的代码，barrier中的代码执行完后才会执行后面的代码
     barrier函数之前和之后的操作执行顺序都不固定
     */
}

/*
 并发编程中不可避免的碰到资源争夺问题，解决这类问题有三种方法：
 
 加锁 @synchronized(//要锁对象){相关操作}
 使用异步执行串行队列的方式，这样可以控制对象的操作顺序
 上面两种方法的确已经足够好了，但还不是最优的，它只可以实现单读、单写。
 整体来看，我们最终要解决的问题是，在写的过程中不能被读，以免数据不对，但是读与读之间并没有任何的冲突
 
 dispatch_barrier 实现读写安全的模型
 */
- (void)dispatch_barrier_2
{
    dispatch_queue_t q = dispatch_queue_create("com.queue.aaa", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(q, ^{
        for (int i = 0; i < 100; i++) {
            [[DMCache shared] setCacheObject:[NSString stringWithFormat:@"%tu",i] withKey:[NSString stringWithFormat:@"1-%tu",i]];
        }
    });
    
    dispatch_async(q, ^{
        for (int i = 0; i < 100; i++) {
            [[DMCache shared] setCacheObject:[NSString stringWithFormat:@"%tu",i] withKey:[NSString stringWithFormat:@"2-%tu",i]];
        }
    });
    
    dispatch_barrier_async(q, ^{
        for (int i = 0; i < 100; i++) {
            NSString *value1 = [[DMCache shared] cacheWithKey:[NSString stringWithFormat:@"1-%tu",i]];
            NSString *value2 = [[DMCache shared] cacheWithKey:[NSString stringWithFormat:@"2-%tu",i]];
            NSLog(@"key1:%@==%@;key2:%@==%@",[NSString stringWithFormat:@"1-%tu",i],value1,[NSString stringWithFormat:@"2-%tu",i],value2);
        }
    });
}

/*
 dispatch_barrier_sync与dispatch_barrier_async
 1、等待在它前面插入队列的任务先执行完
 
 2、等待他们自己的任务执行完再执行后面的任务
 
 不同点：
 
 1、dispatch_barrier_sync将自己的任务插入到队列的时候，需要等待自己的任务结束之后才会继续插入被写在它后面的任务，然后执行它们
 
 2、dispatch_barrier_async将自己的任务插入到队列之后，不会等待自己的任务结束，它会继续把后面的任务插入到队列，然后等待自己的任务结束后才执行后面任务。
 */
- (void)dispatch_barrier_3
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentQueue, ^(){
        sleep(5);
        NSLog(@"dispatch-1");
    });
    dispatch_async(concurrentQueue, ^(){
        sleep(1);
        NSLog(@"dispatch-2");
    });
//    dispatch_barrier_async(concurrentQueue, ^(){
//        NSLog(@"dispatch-barrier");
//    });
    dispatch_barrier_sync(concurrentQueue, ^(){
        NSLog(@"dispatch-barrier");
    });
    dispatch_async(concurrentQueue, ^(){
        NSLog(@"dispatch-3");
    });
    dispatch_async(concurrentQueue, ^(){
        NSLog(@"dispatch-4");
    });
}


//MARK: dispatch group
/*
 Dispatch group 用来阻塞一个线程，直到一个或多个任务完成执行。
 */
- (void)dispatch_group_1
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    // 把 queue 加入到 group
    dispatch_group_async(group, queue, ^{
        // 一些异步操作任务
        NSLog(@"group task one");
    });
    
    dispatch_group_async(group, queue, ^{
        NSLog(@"group task two");
    });
    
    // code 你可以在这里写代码做一些不必等待 group 内任务的操作
    NSLog(@"outer");
    // 当你在 group 的任务没有完成的情况下不能做更多的事时，阻塞当前线程等待 group 完工
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        NSLog(@"finish");
    
//    dispatch_group_notify(group, queue, ^{
//        NSLog(@"notify group finish");
//    });
}

- (void)dispatch_group_2
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < 10; i++) {
        dispatch_group_enter(group);
        dispatch_async(concurrentQueue, ^{
            NSLog(@"task = %tu",i);
            sleep(i+1);
            dispatch_group_leave(group);
        });
    }
    
    NSLog(@"outter");
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"finished");
    });
    
}

//MARK: dispatch_set_target_queue
//变更队列的执行优先级
- (void)dispatch_target_1
{
    //优先级变更的串行队列，初始是默认优先级
    dispatch_queue_t serialQueue = dispatch_queue_create("com.leoliu.gcd.serial", DISPATCH_QUEUE_SERIAL);
    
    //优先级不变的串行队列（参照），初始是默认优先级
    dispatch_queue_t defaultSerialQueue = dispatch_queue_create("com.leoliu.gcd.defaultserial", DISPATCH_QUEUE_SERIAL);
    
    //变更前
    dispatch_async(serialQueue, ^{
        NSLog(@"变更前 - 1");
    });
    
    dispatch_async(defaultSerialQueue, ^{
        NSLog(@"变更前 - 2");
    });
    
    //获取优先级为后台优先级的全局队列
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    //变更优先级
    dispatch_set_target_queue(serialQueue, globalQueue);
    
    //变更后
    dispatch_async(serialQueue, ^{
        NSLog(@"变更后 - 1");
    });
    
    dispatch_async(defaultSerialQueue, ^{
        NSLog(@"变更后 - 2");
    });
    
    /**
     结果:
      变更前 - 2
      变更前 - 1
      变更后 - 2
      变更后 - 1
     */
}

- (void)dispatch_target_2
{
    dispatch_queue_t serialQueue1 = dispatch_queue_create("com.leoliu.gcd.serial1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue2 = dispatch_queue_create("com.leoliu.gcd.serial2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue3 = dispatch_queue_create("com.leoliu.gcd.serial3", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue4 = dispatch_queue_create("com.leoliu.gcd.serial4", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue5 = dispatch_queue_create("com.leoliu.gcd.serial5", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(serialQueue1, ^{
        NSLog(@"变更前 - 1");
    });
    dispatch_async(serialQueue2, ^{
        NSLog(@"变更前 - 2");
    });
    dispatch_async(serialQueue3, ^{
        NSLog(@"变更前 - 3");
    });
    dispatch_async(serialQueue4, ^{
        NSLog(@"变更前 - 4");
    });
    dispatch_async(serialQueue5, ^{
        NSLog(@"变更前 - 5");
    });
    
    
    sleep(5);
    
    dispatch_queue_t targetQueue = dispatch_queue_create("com.leoliu.gcd.target", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(serialQueue2, targetQueue);
    dispatch_set_target_queue(serialQueue1, targetQueue);
    dispatch_set_target_queue(serialQueue3, targetQueue);
    dispatch_set_target_queue(serialQueue4, targetQueue);
    dispatch_set_target_queue(serialQueue5, targetQueue);
    
    dispatch_async(serialQueue1, ^{
        NSLog(@"变更后 - 1");
    });
    dispatch_async(serialQueue2, ^{
        NSLog(@"变更后 - 2");
    });
    dispatch_async(serialQueue3, ^{
        NSLog(@"变更后 - 3");
    });
    dispatch_async(serialQueue4, ^{
        NSLog(@"变更后 - 4");
    });
    dispatch_async(serialQueue5, ^{
        NSLog(@"变更后 - 5");
    });
    
    /**
     结果：
      变更前 - 3
      变更前 - 2
      变更前 - 4
      变更前 - 1
      变更前 - 5
     
      变更后 - 1
      变更后 - 2
      变更后 - 3
      变更后 - 4
      变更后 - 5
     */
}


- (void)dispatch_target_3
{
    dispatch_queue_t concurrentQueue1 = dispatch_queue_create("com.leoliu.gcd.concurrent1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t serialQueue2 = dispatch_queue_create("com.leoliu.gcd.serial2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue3 = dispatch_queue_create("com.leoliu.gcd.serial3", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue4 = dispatch_queue_create("com.leoliu.gcd.serial4", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue5 = dispatch_queue_create("com.leoliu.gcd.serial5", DISPATCH_QUEUE_SERIAL);
    
    dispatch_queue_t targetQueue = dispatch_queue_create("com.leoliu.gcd.target", DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(concurrentQueue1, targetQueue);
    dispatch_set_target_queue(serialQueue3, targetQueue);
    dispatch_set_target_queue(serialQueue2, targetQueue);
    dispatch_set_target_queue(serialQueue4, targetQueue);
    dispatch_set_target_queue(serialQueue5, targetQueue);
    
    dispatch_async(concurrentQueue1, ^{
        NSLog(@"变更后 - 1-1");
        sleep(5);
    });
    
    dispatch_async(concurrentQueue1, ^{
        NSLog(@"变更后 - 1-3");
    });
   
    dispatch_async(serialQueue2, ^{
        sleep(2);
        NSLog(@"变更后 - 2");
    });
    dispatch_async(concurrentQueue1, ^{
        sleep(5);
        NSLog(@"变更后 - 1-2");
    });
    dispatch_async(serialQueue3, ^{
        NSLog(@"变更后 - 3");
    });
    dispatch_async(serialQueue4, ^{
        NSLog(@"变更后 - 4");
    });
    dispatch_async(serialQueue5, ^{
        NSLog(@"变更后 - 5");
    });
    
   
    
    
    /**
     结果：
     变更后 - 1-1
     变更后 - 1-3
     变更后 - 2
     变更后 - 1-2
     变更后 - 3
     变更后 - 4
     变更后 - 5
     
     结论：
     并行队列指定到目标串行队列中后会根据添加顺序执行
     串行队列指定到目标串行队列中后会根据添加顺序执行
     目标队列是什么队列 执行就是按什么队列执行
     */
}


- (void)dispatch_set_target_4
{
    dispatch_queue_t queue = dispatch_queue_create("com.thread.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_set_target_queue(queue, dispatch_get_main_queue());
    dispatch_async(queue, ^{
        NSLog(@"开始请求");
        sleep(5);
        NSLog(@"得到请求结果:%@",[NSThread currentThread]);
    });
    
    
}
//MARK: dispatch apply

/**
 dispatch_apply函数是dispatch_sync函数和Dispatch Group的关联API,该函数按指定的次数将指定的Block追加到指定的Dispatch Queue中,并等到全部的处理执行结束
 */
- (void)dispatch_apply_1
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    NSArray *arr = @[@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j"];
    dispatch_async(queue, ^{
        dispatch_apply(arr.count, queue, ^(size_t i) {
            NSLog(@"%@",[arr objectAtIndex:i]);
        });
        NSLog(@"--over");
    });
    NSLog(@"over");
}

//MARK: dispatch semaphore
//https://blog.csdn.net/LXL_815520/article/details/60144640
/**
 关于信号量，一般可以用停车来比喻
 停车场剩余4个车位，那么即使同时来了四辆车也能停的下。如果此时来了五辆车，那么就有一辆需要等待。
 信号量的值就相当于剩余车位的数目，dispatch_semaphore_wait函数就相当于来了一辆车，dispatch_semaphore_signal
 就相当于走了一辆车。停车位的剩余数目在初始化的时候就已经指明了（dispatch_semaphore_create（long value）），
 调用一次dispatch_semaphore_signal，剩余的车位就增加一个；调用一次dispatch_semaphore_wait剩余车位就减少一个；
 当剩余车位为0时，再来车（即调用dispatch_semaphore_wait）就只能等待。有可能同时有几辆车等待一个停车位。有些车主
 没有耐心，给自己设定了一段等待时间，这段时间内等不到停车位就走了，如果等到了就开进去停车。而有些车主就像把车停在这，
 所以就一直等下去。
 */

//保持线程同步，将异步操作转换为同步操作
- (void)dispatch_semaphore_1
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_async(queue, ^{
        NSLog(@"请求中……");
        sleep(5);
        NSLog(@"请求回调中……");
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"over");
}

//为线程加锁
- (void)dispatch_semaphore_2
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    for (int i = 0; i < 100; i++) {
        dispatch_async(queue, ^{
            long semaphorecount = dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            NSLog(@"i = %tu, count = %ld",i,semaphorecount);
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    /**
     当线程1执行到dispatch_semaphore_wait这一行时，semaphore的信号量为1，所以使信号量-1变为0，并且线程1继续往下执行；如果当在线程1NSLog这一行代码还没执行完的时候，又有线程2来访问
     执行dispatch_semaphore_wait时由于此时信号量为0，且时间为DISPATCH_TIME_FOREVER,所以会一直阻塞线程2（此时线程2处于等待状态），直到线程1执行完NSLog并执行
     dispatch_semaphore_signal使信号量为1后，线程2才能解除阻塞继续住下执行。以上可以保证同时只有一个线程执行NSLog这一行代码。
     */
}

//使用 Dispatch Semaphore 控制并发线程数量
- (void)dispatch_semaphore_3
{
    dispatch_queue_t queue = dispatch_queue_create("com.limit.queue", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 100; i++) {
        dispatch_async_limit(queue, 5, ^{
            sleep(5);
            NSLog(@"%tu = %@",i,[NSThread currentThread]);
        });
    }
}

void dispatch_async_limit(dispatch_queue_t queue,NSUInteger limitSemaphoreCount, dispatch_block_t block) {
    //控制并发数的信号量
    static dispatch_semaphore_t limitSemaphore;
    
    //专门控制并发等待的线程
    static dispatch_queue_t receiverQueue;
    
    //使用 dispatch_once而非 lazy 模式，防止可能的多线程抢占问题
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        limitSemaphore = dispatch_semaphore_create(limitSemaphoreCount);
        receiverQueue = dispatch_queue_create("receiver", DISPATCH_QUEUE_SERIAL);
    });
    // 如不加 receiverQueue 放在主线程会阻塞主线程
    dispatch_async(receiverQueue, ^{
        //可用信号量后才能继续，否则等待
        dispatch_semaphore_wait(limitSemaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(queue, ^{
            !block ? : block();
            //在该工作线程执行完成后释放信号量
            dispatch_semaphore_signal(limitSemaphore);
        });
    });
}

//MARK: --------other

//MARK: dispatch source
/**
 与Dispatch Queue不同的是，dispatch_source是可以进行取消的，而且可以添加取消的block回调；dispatch_source可以做异步读取文件映像、定时器、监听文件目录变化等等，具体请见下表：
 方法                                     说明
 DISPATCH_SOURCE_TYPE_DATA_ADD          变量增加
 DISPATCH_SOURCE_TYPE_DATA_OR           变量OR
 DISPATCH_SOURCE_TYPE_MACH_SEND         Mach端口发送
 DISPATCH_SOURCE_TYPE_MACH_RECV         Mach端口接收
 DISPATCH_SOURCE_TYPE_MEMORYPRESSURE    内存情况
 DISPATCH_SOURCE_TYPE_PROC              检测到与进程相关的事件
 DISPATCH_SOURCE_TYPE_READ              可读取文件映像
 DISPATCH_SOURCE_TYPE_SIGNAL            接收信号
 DISPATCH_SOURCE_TYPE_TIMER             定时器
 DISPATCH_SOURCE_TYPE_VNODE             文件系统有变更
 DISPATCH_SOURCE_TYPE_WRITE             可写入文件映像
 */
//定时器
- (void)dispatch_source_1
{
    self.progressView.progress = 1.0;
    __block NSInteger timeout = 10;
    dispatch_queue_t queue = dispatch_queue_create("com.yiqi.dmgcd", DISPATCH_QUEUE_SERIAL);
    dispatch_source_t timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t time = dispatch_walltime(NULL, 0);
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(<#delayInSeconds#> * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        <#code to be executed after a specified delay#>
//    });
    
    dispatch_source_set_timer(timerSource, time, 1.0*NSEC_PER_SEC, 0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timerSource, ^{
        if (timeout <= 0) {
            dispatch_source_cancel(timerSource);
            NSLog(@"cancel");
        } else {
            timeout--;
            NSLog(@"timeout = %tu",timeout);
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progressView.progress = timeout/10.;
            });
        }
    });
    
    //开始执行
    dispatch_resume(timerSource);
}

//文件系统
- (void)dispatch_source_2
{
    //创建文件夹，写入文件，用来进行测试
    NSString *cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *directory = [NSString stringWithFormat:@"%@/test", cacheDirectory];
    if(![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    
    NSURL *directoryURL = [NSURL URLWithString:directory]; // assume this is set to a directory
    int const fd = open([[directoryURL path] fileSystemRepresentation], O_EVTONLY);
    if (fd < 0) {
        char buffer[80];
        strerror_r(errno, buffer, sizeof(buffer));
        NSLog(@"Unable to open \"%@\": %s (%d)", [directoryURL path], buffer, errno);
        return;
    }
    //设置源监听文件夹的变化，其中监听的是写入、删除、更改名字
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd,
                                                      DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME, DISPATCH_TARGET_QUEUE_DEFAULT);
    dispatch_source_set_event_handler(source, ^(){
        //获取源变化的具体标志
        unsigned long const data = dispatch_source_get_data(source);
        if (data & DISPATCH_VNODE_WRITE) {
            NSLog(@"The directory changed.");
        }
        if (data & DISPATCH_VNODE_DELETE) {
            NSLog(@"The directory has been deleted.");
        }
    });
    dispatch_source_set_cancel_handler(source, ^(){
        NSLog(@"cancel");
        close(fd);
    });
    dispatch_resume(source);
    
    NSError *error;
//    [[NSFileManager defaultManager] removeItemAtPath:directory error:&error];
//    if (error) {
//        NSLog(@"error%@",error.localizedDescription);
//    }
    
    NSString *filePath = [NSString stringWithFormat:@"%@/test.txt", directory];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [@"hello" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"error%@",error.localizedDescription);
        }

    }
}

//内存压力情况变化.
- (void)dispatch_source_3
{
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_MEMORYPRESSURE, 0, DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL, dispatch_get_main_queue());
    dispatch_source_set_event_handler(source, ^{
        dispatch_source_memorypressure_flags_t pressureLevel = dispatch_source_get_data(source);
        if (pressureLevel & DISPATCH_MEMORYPRESSURE_WARN) {
            NSLog(@"memeory warn");
        }
        
        if (pressureLevel & DISPATCH_MEMORYPRESSURE_CRITICAL) {
            NSLog(@"memeory critical");
        }
    });
    dispatch_resume(source);
}

- (void)dispatch_source_4
{
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    
    __block NSUInteger totalComplete = 0;
    
    //在主线程繁忙的时候将操作联结起来，等主线程空闲时 刷新UI 避免频繁的在主线程刷新UI
    dispatch_source_set_event_handler(source, ^{
        //当处理事件被最终执行时，计算后的数据可以通过dispatch_source_get_data来获取。这个数据的值在每次响应事件执行后会被重置，所以totalComplete的值是最终累积的值。
        NSUInteger value = dispatch_source_get_data(source);
        
        NSLog(@"value：%@", @(value));
        
        //最终totalComplete = kMaxIndex * kPerValue；
        totalComplete += value;
        
        NSLog(@"进度：%@", @((CGFloat)totalComplete/(kMaxIndex * kPerValue)));
        
        CGFloat progress = totalComplete / (kMaxIndex * kPerValue);
        
        self.progressView.progress = progress;
        
        NSLog(@"线程号：%@", [NSThread currentThread]);
    });
    
    dispatch_resume(source);
    
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    for (NSUInteger index = 0; index < kMaxIndex; index++) {
        dispatch_async(globalQ, ^{
            dispatch_source_merge_data(source, kPerValue);
            NSLog(@"线程号：%@~~~~~~~~~~~~i = %ld", [NSThread currentThread], index);
            usleep(2000000);//0.02秒
        });
    }
}

//
- (void)dispatch_source_5
{
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
    //在主线程繁忙的时候将操作联结起来，等主线程空闲时 刷新UI 避免频繁的在主线程刷新UI
    dispatch_source_set_event_handler(source, ^{
        //当处理事件被最终执行时，计算后的数据可以通过dispatch_source_get_data来获取。这个数据的值在每次响应事件执行后会被重置，所以totalComplete的值是最终累积的值。
        NSUInteger value = dispatch_source_get_data(source);
        
        NSLog(@"value：%@", @(value));
        value = value == 100 ? 0 : value;
        self.progressView.progress = value/10.;
        
        NSLog(@"线程号：%@", [NSThread currentThread]);
    });
    
    dispatch_resume(source);
    
    self.progressView.progress = 1.0;
    __block NSInteger timeout = 10;
    dispatch_queue_t queue = dispatch_queue_create("com.yiqi.dmgcd", DISPATCH_QUEUE_SERIAL);
    dispatch_source_t timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t time = dispatch_walltime(NULL, 0);
    dispatch_source_set_timer(timerSource, time, 1.0*NSEC_PER_SEC, 0);
    
    dispatch_source_set_event_handler(timerSource, ^{
        if (timeout <= 0) {
            dispatch_source_cancel(timerSource);
            NSLog(@"cancel");
        } else {
            timeout--;
            NSLog(@"timeout = %tu  %f",timeout,timeout/10.);
            NSInteger a = timeout == 0 ? 100 : timeout;
            dispatch_source_merge_data(source,  a);//timeout == 0 时不会触发事件
        }
    });
    
    //开始执行
    dispatch_resume(timerSource);
}

- (void)demo4
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"aa" ofType:@"json"];
    NSData *data = [path dataUsingEncoding:NSUTF8StringEncoding];
    char *buf = (char *)[data bytes];
    ProcessContentsOfFile(buf);
    
}


dispatch_source_t ProcessContentsOfFile(const char* filename)
{
    // Prepare the file for reading.
    int fd = open(filename, O_RDONLY);
    if (fd == -1){return NULL;}
    fcntl(fd, F_SETFL, O_NONBLOCK); // Avoid blocking the read operation
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, fd, 0, queue);
    if (!readSource)
    {
        close(fd);
        return NULL;
    }
    // Install the event handler
    dispatch_source_set_event_handler(readSource, ^{
        size_t estimated = dispatch_source_get_data(readSource) + 1;
        char* buffer = (char*)malloc(estimated);
        if (buffer)
        {
            ssize_t actual = read(fd, buffer, (estimated));
            if(actual > 0){
                NSLog(@"Got data from stdin: %.*s", (int)actual, buffer);
            }
        }
    });
    dispatch_source_set_cancel_handler(readSource, ^{close(fd);}); // Install the cancellation handler
    dispatch_resume(readSource); // Start reading the file.
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
    });
    return readSource;
}

- (void)demo5
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"aa" ofType:@"json"];
    NSData *data = [path dataUsingEncoding:NSUTF8StringEncoding];
    char *buf = (char *)[data bytes];
    WriteDataToFile(buf);
}

dispatch_source_t WriteDataToFile(const char* filename)
{
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, (S_IRUSR | S_IWUSR | S_ISUID | S_ISGID));
    if (fd == -1)
        return NULL;
    fcntl(fd, F_SETFL); // Block during the write.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, fd, 0, queue);
    if (!writeSource)
    {
        close(fd);
        return NULL;
    }
    dispatch_source_set_event_handler(writeSource, ^{
        NSString *str = @"hello world";
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        char *buf = (char *)[data bytes];
        size_t bufferSize = sizeof(buf);
        void* buffer = malloc(bufferSize);
        ssize_t a = write(fd, buffer, bufferSize);
        if (a == -1) {
            NSLog(@"error: %s(errno: %d)",strerror(errno),errno);
        }
        free(buffer);
        dispatch_source_cancel(writeSource); // Cancel and release the dispatch source when done.
    });
    dispatch_source_set_cancel_handler(writeSource, ^{close(fd);});
    dispatch_resume(writeSource);
    return (writeSource);
}


//dispatch_apply
/*
 如果每次迭代执行的任务与其它迭代独立无关，而且循环迭代执行顺序也无关紧要的话，你可以调用 dispatch_apply 或 dispatch_apply_f 函数来替换循环。这两个函数为每次循环迭代将指定的 block 或函数提交到 queue。当 dispatch 到并发 queue 时，就有可能同时执行多个循环迭代。
 
 调用 dispatch_apply 或 dispatch_apply_f 时你虽然可以指定串行或并发 queue。 并发 queue 允许同时执行多个循环迭代，而串行 queue 就没太大必要使用了。
 
 需要注意：这两个函数会阻塞当前线程，而且和普通 for 循环一样，dispatch_apply 和 dispatch_apply_f 函数也是在所有迭代完成之后才会返回。所以如果你传递的参数是串行 queue，而且正是执行当前代码的 Queue, 就会产生死锁。主线程中调用这两个函数必须小心，可能会阻止事件处理循环并无法响应用户事件。
 */

/*! dispatch_apply函数说明
 *
 *  @brief  dispatch_apply函数是dispatch_sync函数和Dispatch Group的关联API
 *         该函数按指定的次数将指定的Block追加到指定的Dispatch Queue中,并等到全部的处理执行结束
 */
- (void)demo6
{
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(10, q, ^(size_t i) {
        NSLog(@"iterations task == %tu",i);
    });
    
    NSLog(@"finish");
}


// 当 queue 的引用计数到达 0 时执行清理函数
void myFinalizerFunction(void *context) {
    char *theData = (char *)context;
    printf("myFinalizerFunction - data = %s\n", theData);
    
    // 具体清理细节可以另写一个函数
    myCleanUpDataContextFunction(theData);
}

// 具体清理细节
void myCleanUpDataContextFunction(char *data) {
    printf("myCleanUpDataContextFunction - data = %s\n", data);
}

// 具体初始化细节
void myInitializeDataContextFunction(char **data) {
    *data = "Lision";
    printf("myInitializeDataContextFunction - data = %s\n", *data);
}

// 自定义创建队列函数
dispatch_queue_t createMyQueue() {
    char *data = (char *) malloc(sizeof(char));
    myInitializeDataContextFunction(&data);
    
    // 创建队列并为其设置上下文
    dispatch_queue_t serialQueue = dispatch_queue_create("test.Lision.CriticalTaskQueue", NULL);
    if (serialQueue) {
        dispatch_set_context(serialQueue, data);
        dispatch_set_finalizer_f(serialQueue, &myFinalizerFunction);
    }
    return serialQueue;
}

/*
 dispatch_set_finalizer_f 函数为 queue 指定一个清理函数
 */
- (void)demo7
{
    // 通过自定义函数创建队列
    dispatch_queue_t queue = createMyQueue();
    
    // 异步执行队列，并在队列中修改上下文
    dispatch_async(queue, ^{
        char *name = dispatch_get_context(queue);
        NSLog(@"name=====%s",name);
        name = "LiXin";
        dispatch_set_context(queue, name);
    });
}










@end
