//
//  ViewController.m
//  DMGCD
//
//  Created by lbq on 2017/9/12.
//  Copyright © 2017年 lbq. All rights reserved.
//

#import "ViewController.h"

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
//    [self demo1];
//    [self demo2];
    [self demo3];
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
@end
