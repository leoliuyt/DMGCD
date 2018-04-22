//
//  DMOperation.m
//  DMGCD
//
//  Created by leoliu on 2018/4/21.
//  Copyright © 2018年 lbq. All rights reserved.
//

#import "DMOperation.h"
@interface DMOperation ()
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@end
@implementation DMOperation

@synthesize finished = _finished;
@synthesize executing = _executing;
@synthesize cancelled = _cancelled;

//- (void)main
//{
//    NSLog(@"%s",__func__);
//    NSThread sleepForTimeInterval:3.0];
//    NSLog(@"%@-耗时操作执行结束",[NSThread currentThread]);
//}

- (void)start
{
    NSLog(@"%s",__func__);
    @synchronized(self){
        if (self.isCancelled) {
            self.finished = YES;
            return;
        }
    }
    self.executing = YES;
    [NSThread sleepForTimeInterval:3.0];
    self.executing = NO;
    self.finished = YES;
    NSLog(@"%@-执行结束",[NSThread currentThread]);
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
}


/**
 finished == YES后 operation 会被释放
 */
@end
