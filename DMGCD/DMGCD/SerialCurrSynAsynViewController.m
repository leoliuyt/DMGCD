//
//  SerialCurrSynAsynViewController.m
//  DMGCD
//
//  Created by lbq on 2018/4/19.
//  Copyright © 2018年 lbq. All rights reserved.
//

#import "SerialCurrSynAsynViewController.h"

@interface SerialCurrSynAsynViewController ()

@end

@implementation SerialCurrSynAsynViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self demo10];
}

//MARK: 串行同步、异步

- (void)demo1
{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    
    for (int i = 0; i < 1000; i++) {
        dispatch_sync(q, ^{
            NSLog(@"%@ %d", [NSThread currentThread], i);
        });
    }
    NSLog(@"over-main");
    /**
     结果固定：
      <NSThread: 0x17006e280>{number = 1, name = main} 0
      <NSThread: 0x17006e280>{number = 1, name = main} 1
      <NSThread: 0x17006e280>{number = 1, name = main} 2
      <NSThread: 0x17006e280>{number = 1, name = main} 3
      <NSThread: 0x17006e280>{number = 1, name = main} 4
      <NSThread: 0x17006e280>{number = 1, name = main} 5
      <NSThread: 0x17006e280>{number = 1, name = main} 6
      <NSThread: 0x17006e280>{number = 1, name = main} 7
      <NSThread: 0x17006e280>{number = 1, name = main} 8
      <NSThread: 0x17006e280>{number = 1, name = main} 9
      over-main
     
     同步操作不开新线程，在当前线程中执行操作，当前线程为主线程，所以主线程同在主线程中的over-main,要按照顺序执行over-main最后打印
     */
}

- (void)demo2
{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    
    for (int i = 0; i < 1000; i++) {
        dispatch_async(q, ^{
            NSLog(@"%@ %d", [NSThread currentThread], i);
        });
    }
    NSLog(@"over-main");
    /** over-main 顺序不固定 其他的固定
      <NSThread: 0x170279ac0>{number = 5, name = (null)} 38
      over-main
      <NSThread: 0x170279ac0>{number = 5, name = (null)} 39
      <NSThread: 0x170279ac0>{number = 5, name = (null)} 40
      <NSThread: 0x170279ac0>{number = 5, name = (null)} 41
      <NSThread: 0x170279ac0>{number = 5, name = (null)} 42
     
     串行队列中的任务是顺序执行的
     */
}

//MARK: 并行同步、异步
- (void)demo3
{
    dispatch_queue_t q = dispatch_queue_create("curren", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 1000; i++) {
        dispatch_sync(q, ^{
            NSLog(@"%@ %d", [NSThread currentThread], i);
        });
    }
    NSLog(@"over-main");
    
    /**
     同步操作不创建线程，在当前线程中顺序执行
      <NSThread: 0x174079800>{number = 1, name = main} 997
      <NSThread: 0x174079800>{number = 1, name = main} 998
      <NSThread: 0x174079800>{number = 1, name = main} 999
      over-main
     */
}

- (void)demo4
{
    dispatch_queue_t q = dispatch_queue_create("curren", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i < 1000; i++) {
        dispatch_async(q, ^{
            NSLog(@"%@ %d", [NSThread currentThread], i);
        });
    }
    NSLog(@"over-main");
    /**
     开很多线程，无序执行
     */
}

//MARK: 死锁  这里的死锁 是由于队列的循环等待引起的，与线程无关

//死锁
- (void)demo5
{
    NSLog(@"outer--1");
    dispatch_sync(dispatch_get_main_queue(), ^{
       NSLog(@"inner--1");
    });
    NSLog(@"outer--2");
}

//不会死锁
- (void)demo5_1{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    NSLog(@"outer--1");
    dispatch_sync(q, ^{
        NSLog(@"inner--1");
    });
    NSLog(@"outer--2");
}

- (void)demo6{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    NSLog(@"outer--1");
    dispatch_sync(q, ^{
        NSLog(@"inner--1--%@",[NSThread currentThread]);
        dispatch_sync(q, ^{
            NSLog(@"inner--2");
        });
    });
    
    NSLog(@"outer--2");
}

//死锁
- (void)demo6_1{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    NSLog(@"outer--1");
    dispatch_async(q, ^{//开辟了一条子线程 task1
        NSLog(@"inner--1--%@",[NSThread currentThread]);
        dispatch_sync(q, ^{//任务提交到串行队列中，并在当前子线程中执行 task2
            NSLog(@"inner--2");
        });
    });
    
    NSLog(@"outer--2");
    
    /*
     串行队列中加入task1
     在task1中又有一个任务task2被添加到了串行队列中，并要求在队列中同步执行，
     任务二的完成要等待串行队列任务一task1的完成
     而任务task1的完成要等待task2的完成
     */
}

//不会死锁
- (void)demo6_2{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    NSLog(@"outer--1");
    dispatch_sync(q, ^{//主线程 task1
        NSLog(@"inner--1--%@",[NSThread currentThread]);
        dispatch_async(q, ^{//子线程 task2
//            sleep(5);
            NSLog(@"inner---inner-2");
        });
        sleep(2);
        NSLog(@"inner--2--%@",[NSThread currentThread]);
    });
    
    sleep(2);
    NSLog(@"outer--2");
    /*
     task1加入串行队列
     task1中的task2也加入了队列中
     因为task1中的task2任务是在另一条子线程中完成的，
     task1不需要等待task2的完成就可以完成，
     所以task1完成后出队列，然后task2就可以执行
     */
    /*
      outer--1
      inner--1--<NSThread: 0x17007c440>{number = 1, name = main}
      inner--2--<NSThread: 0x17007c440>{number = 1, name = main}
      inner---inner-2
      outer--2
     
     //如果不sleep(2) 那么结果为下面，理论上最后两项的顺序应该是不一定的
     outer--1
     inner--1--<NSThread: 0x17007c440>{number = 1, name = main}
     inner--2--<NSThread: 0x17007c440>{number = 1, name = main}
     outer--2
     inner---inner-2
     */
}

//不会死锁
//串行队列： 任务依次执行，同一时间队列中只有一个任务在执行，每个任务只有在前一个任务执行完成后才能开始执行。
//并行队列：任务并发执行，你唯一能保证的是，这些任务会按照被添加的顺序开始执行。但是任务可以以任何顺序完成。
- (void)demo6_3{
    dispatch_queue_t q = dispatch_queue_create("CONCURRENT", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"outer--1");
    dispatch_sync(q, ^{//task1
        NSLog(@"inner--1");
        dispatch_sync(q, ^{//task2
            sleep(5);
            NSLog(@"inner--inner--2");
        });
        NSLog(@"inner--2");
    });
    
    NSLog(@"outer--2");
    /*
     task1 任务被添加到并行队列中后，开始执行
     执行到task2时，把task2后添加到并行队列中，
     由于task2是同步执行，所以task2中的任务开始执行
     task2执行完毕后，task1后续的任务开始执行
     */
}

- (void)demo6_4{
    dispatch_queue_t q = dispatch_queue_create("CONCURRENT", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"outer--1");
    dispatch_async(q, ^{//task1
        NSLog(@"inner--1");
        dispatch_sync(q, ^{//task2
            sleep(5);
            NSLog(@"inner--inner--2");
        });
        NSLog(@"inner--2");
    });
    
    NSLog(@"outer--2");
    /*
     task1 任务被添加到并行队列中后，开始执行
     执行到task2时，把task2后添加到并行队列中，
     由于task2是同步执行，所以task2中的任务开始执行
     task2执行完毕后，task1后续的任务开始执行
      outer--1
      outer--2
      inner--1
      inner--inner--2
      inner--2
     */
}

- (void)demo6_5{
    dispatch_queue_t q = dispatch_queue_create("CONCURRENT", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"outer--1");
    dispatch_sync(q, ^{//task1
        NSLog(@"inner--1");
        dispatch_async(q, ^{//task2
//            sleep(5);
            NSLog(@"inner--inner--2");
        });
        NSLog(@"inner--2");
    });
    
    NSLog(@"outer--2");
    /*
     task1 任务被添加到并行队列中后，开始执行
     执行到task2时，把task2后添加到并行队列中，
     由于task2是同步执行，所以task2中的任务开始执行
     task2执行完毕后，task1后续的任务开始执行
      outer--1
      inner--1
      inner--2
      outer--2
      inner--inner--2
     */
}


- (void)demo7
{
    dispatch_queue_t q = dispatch_queue_create("CONCURRENT", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"outer--1");
    for(int i = 0 ; i < 10000; i++){
        dispatch_sync(q, ^{
            NSLog(@"inner--%tu",i);
        });
    }
    
    NSLog(@"outer--2");
}

- (void)demo8
{
    dispatch_queue_t q = dispatch_queue_create("CONCURRENT", DISPATCH_QUEUE_SERIAL);
    NSLog(@"outer--1");
    for(int i = 0 ; i < 10000; i++){
        dispatch_async(q, ^{
            NSLog(@"inner--%tu",i);
        });
    }
    
    NSLog(@"outer--2");
}

- (void)demo9
{
    dispatch_queue_t q = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    dispatch_async(q, ^{
        NSLog(@"1");
        [self performSelector:@selector(printLog) withObject:nil afterDelay:0];
        NSLog(@"3");
    });
    
    /*
     GCD维持的线程池 其中的线程没有开启runloop，
     performSelector 方法调用所在的当前的线程，必须开启runloop
     */
}

- (void)demo10
{
    __weak typeof(self) weakSelf = self;
    [NSThread detachNewThreadWithBlock:^{
        NSLog(@"1:%@",[NSThread currentThread]);
        [weakSelf performSelector:@selector(printLog) withObject:nil afterDelay:0];
        NSLog(@"3:%@",[NSThread currentThread]);
    }];
}

- (void)printLog
{
    NSLog(@"2");
}
@end
