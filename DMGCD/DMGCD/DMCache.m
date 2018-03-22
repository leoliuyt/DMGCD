//
//  DMCache.m
//  DMGCD
//
//  Created by lbq on 2018/3/22.
//  Copyright © 2018年 lbq. All rights reserved.
//

#import "DMCache.h"
@interface DMCache()
{
    dispatch_queue_t _queue;
}
@property (nonatomic, strong) NSMutableDictionary *cache;
@end
@implementation DMCache
+ (instancetype)shared
{
    static DMCache *share;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[DMCache alloc] init];
    });
    
    return share;
}

- (instancetype)init
{
    self = [super init];
    self.cache = [NSMutableDictionary dictionary];
    _queue = dispatch_queue_create("com.cache.concurrent", DISPATCH_QUEUE_CONCURRENT);
    return self;
}

- (id)cacheWithKey:(id)key
{
    __block id obj;
    
    // 任意线程都可以'读'
    dispatch_sync(_queue, ^{
        obj = [self.cache objectForKey:key];
    });
    
    return obj;
}

- (void)setCacheObject:(id)obj withKey:(id)key
{
    // 保证同时'写'的的只有一个
    dispatch_barrier_async(_queue, ^{
        [self.cache setObject:obj forKey:key];
    });
}
@end
