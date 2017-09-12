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
    ////https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html#//apple_ref/doc/uid/TP40008091-CH103-SW22
//    [self demo1];
//    [self demo2];
//    [self demo4];
    [self demo5];
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
@end
