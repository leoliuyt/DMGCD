//
//  Person.m
//  DMGCD
//
//  Created by leoliu on 2017/9/24.
//  Copyright © 2017年 lbq. All rights reserved.
//

#import "Person.h"
@interface Person()

@property (nonatomic, strong) dispatch_queue_t queue;

@end
@implementation Person

@synthesize name = _name;

- (instancetype)init
{
    self = [super init];
    self.queue = dispatch_queue_create("com.person.concurrent", DISPATCH_QUEUE_CONCURRENT);
    return self;
}

- (void)setName:(NSString *)name
{
    // 保证同时'写'的的只有一个
    dispatch_barrier_async(self.queue, ^{
        _name = [name copy];
    });
}

- (NSString *)name{
    __block NSString *tmpName;
    // 任意线程都可以'读'
    dispatch_sync(self.queue, ^{
        tmpName = _name;
    });
    return tmpName;
}
@end
