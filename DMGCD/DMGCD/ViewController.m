//
//  ViewController.m
//  DMGCD
//
//  Created by lbq on 2017/9/12.
//  Copyright © 2017年 lbq. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"

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
//    [self demo1];
//    [self demo2];
//    [self demo4];
//    [self demo9];
    [self demo14];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)demo1
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

- (void)demo2
{
    self.progressView.progress = 1.0;
    __block NSInteger timeout = 10;
    dispatch_queue_t queue = dispatch_queue_create("com.yiqi.dmgcd", DISPATCH_QUEUE_SERIAL);
    dispatch_source_t timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t time = dispatch_walltime(NULL, 0);
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


- (void)demo3
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

/*
 Dispatch group 用来阻塞一个线程，直到一个或多个任务完成执行。
 */
- (void)demo8
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
    
    // 当你在 group 的任务没有完成的情况下不能做更多的事时，阻塞当前线程等待 group 完工
//    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//    NSLog(@"finish");
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"notify group finish");
    });
}
/*
 并发编程中不可避免的碰到资源争夺问题，解决这类问题有三种方法：
 
 加锁 @synchronized(//要锁对象){相关操作}
 使用异步执行串行队列的方式，这样可以控制对象的操作顺序
 上面两种方法的确已经足够好了，但还不是最优的，它只可以实现单读、单写。
 整体来看，我们最终要解决的问题是，在写的过程中不能被读，以免数据不对，但是读与读之间并没有任何的冲突

 dispatch_barrier ，没错使用它也可以做到这一点
 */
- (void)demo9
{
    Person *person = [[Person alloc] init];
    person.name = @"aaa";
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q, ^{
        person.name = @"bbb";
        NSLog(@"set");
    });
    
    dispatch_async(q, ^{
        NSLog(@"%@",person.name);
        NSLog(@"%@",person.name);
        NSLog(@"-----");
    });
    /* 会出现这种情况
     2017-09-24 17:48:27.552048+0800 DMGCD[35984:7956077] -----
     2017-09-24 17:48:27.710931+0800 DMGCD[35984:7956037] aaa
     2017-09-24 17:48:27.711346+0800 DMGCD[35984:7956037] bbb
     2017-09-24 17:48:27.711560+0800 DMGCD[35984:7956037] -----
     */
}

/*
 dispatch_barrier_sync与dispatch_barrier_async
 1、等待在它前面插入队列的任务先执行完
 
 2、等待他们自己的任务执行完再执行后面的任务
 
 不同点：
 
 1、dispatch_barrier_sync将自己的任务插入到队列的时候，需要等待自己的任务结束之后才会继续插入被写在它后面的任务，然后执行它们
 
 2、dispatch_barrier_async将自己的任务插入到队列之后，不会等待自己的任务结束，它会继续把后面的任务插入到队列，然后等待自己的任务结束后才执行后面任务。
 */
- (void)demo10
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
    dispatch_barrier_async(concurrentQueue, ^(){
        NSLog(@"dispatch-barrier");
    });
    dispatch_async(concurrentQueue, ^(){
        NSLog(@"dispatch-3");
    });
    dispatch_async(concurrentQueue, ^(){
        NSLog(@"dispatch-4");
    });
}

- (void)demo11
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
- (void)demo12
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

- (void)demo13
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


- (void)demo14
{
    dispatch_queue_t concurrentQueue1 = dispatch_queue_create("com.leoliu.gcd.concurrent1", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t serialQueue2 = dispatch_queue_create("com.leoliu.gcd.serial2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue3 = dispatch_queue_create("com.leoliu.gcd.serial3", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue4 = dispatch_queue_create("com.leoliu.gcd.serial4", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t serialQueue5 = dispatch_queue_create("com.leoliu.gcd.serial5", DISPATCH_QUEUE_SERIAL);
    
    dispatch_queue_t targetQueue = dispatch_queue_create("com.leoliu.gcd.target", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(concurrentQueue1, targetQueue);
    dispatch_set_target_queue(serialQueue3, targetQueue);
    dispatch_set_target_queue(serialQueue2, targetQueue);
    dispatch_set_target_queue(serialQueue4, targetQueue);
    dispatch_set_target_queue(serialQueue5, targetQueue);
    
    dispatch_async(concurrentQueue1, ^{
        NSLog(@"变更后 - 1-1");
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
     */
}

















@end
