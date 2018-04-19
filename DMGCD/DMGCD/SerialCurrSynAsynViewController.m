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
    [self demo4];
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
    dispatch_queue_t q = dispatch_queue_create("curren", DISPATCH_CURRENT_QUEUE_LABEL);
    for (int i = 0; i < 1000; i++) {
        dispatch_sync(q, ^{
            NSLog(@"%@ %d", [NSThread currentThread], i);
        });
    }
    NSLog(@"over-main");
    
    /**
     同步操作不创建线程，在当前线程中顺序执行
     */
}

- (void)demo4
{
//    dispatch_queue_t q = dispatch_queue_create("curren", DISPATCH_CURRENT_QUEUE_LABEL);
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i < 1000; i++) {
        dispatch_async(q, ^{
            NSLog(@"%@ %d", [NSThread currentThread], i);
        });
    }
    NSLog(@"over-main");
    /**
     开很多线程，无序执行（实验发现 自己手动创建的并发队列，只创建了一条线程）
     */
}

@end
