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
/*
 串行队列
- (instancetype)init
{
    self = [super init];
    self.queue = dispatch_queue_create("com.person.syncQueue", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)setName:(NSString *)name
{
    dispatch_sync(self.queue, ^{
        _name = [name copy];
    });
}

- (NSString *)name{
    __block NSString *tmpName;
    dispatch_sync(self.queue, ^{
        tmpName = _name;
    });
    return tmpName;
}*/

- (instancetype)init
{
    self = [super init];
//    self.queue = dispatch_queue_create("com.person.syncQueue", DISPATCH_QUEUE_SERIAL);
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    return self;
}

- (void)setName:(NSString *)name
{
    dispatch_barrier_async(self.queue, ^{
        _name = [name copy];
    });
}

- (NSString *)name{
    __block NSString *tmpName;
    dispatch_sync(self.queue, ^{
        tmpName = _name;
    });
    return tmpName;
}
@end
