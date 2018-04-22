//
//  OperationViewController.m
//  DMGCD
//
//  Created by lbq on 2018/4/19.
//  Copyright © 2018年 lbq. All rights reserved.
//

#import "OperationViewController.h"
#import "DMOperation.h"

@interface OperationViewController ()

@end

@implementation OperationViewController

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
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [self demo1];
//    });
}

- (void)demo1
{
    NSInvocationOperation *invocation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(invokeAction:) object:nil];
    [invocation start];
}

- (void)demo2
{
    __weak typeof(self) weakSelf = self;
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf invokeAction:nil];
    }];
    [op start];
}

- (void)demo3
{
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"1-1=%@",[NSThread currentThread]);
        }
    }];
    
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"1=%@",[NSThread currentThread]);
        }
    }];
    
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"2=%@",[NSThread currentThread]);
        }
    }];
    
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"3=%@",[NSThread currentThread]);
        }
    }];
    
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"4=%@",[NSThread currentThread]);
        }
    }];
    
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
            NSLog(@"5=%@",[NSThread currentThread]);
        }
    }];
    
    [op addExecutionBlock:^{
        for (int i = 0; i < 2; i++) {
            NSLog(@"6=%@",[NSThread currentThread]);
            [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
        }
    }];
    [op start];
}

- (void)invokeAction:(id)sender
{
    for (int i = 0; i < 2; i++) {
        [NSThread sleepForTimeInterval:2]; // 模拟耗时操作
        NSLog(@"block- %@",[NSThread currentThread]);
    }
}


- (void)demo4
{
    NSOperationQueue *q = [[NSOperationQueue alloc] init];
    q.maxConcurrentOperationCount = 1;
    DMOperation *op1 = [[DMOperation alloc] init];
    DMOperation *op2 = [[DMOperation alloc] init];
    DMOperation *op3 = [[DMOperation alloc] init];
    [q addOperation: op1];
    [q addOperation: op2];
    [q addOperation: op3];
}
@end
