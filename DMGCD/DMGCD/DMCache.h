//
//  DMCache.h
//  DMGCD
//
//  Created by lbq on 2018/3/22.
//  Copyright © 2018年 lbq. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMCache : NSObject
+ (instancetype)shared;
- (id)cacheWithKey:(id)key;
- (void)setCacheObject:(id)obj withKey:(id)key;
@end
