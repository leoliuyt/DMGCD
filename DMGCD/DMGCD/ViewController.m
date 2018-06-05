//
//  ViewController.m
//  DMGCD
//
//  Created by lbq on 2017/9/12.
//  Copyright © 2017年 lbq. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_queue_t q = dispatch_queue_create("aaa", DISPATCH_QUEUE_SERIAL);
    
    dispatch_queue_t qq = dispatch_queue_create("aaa", DISPATCH_QUEUE_SERIAL);
    
    if (q == qq) {
        NSLog(@"相等");
    } else {
        NSLog(@"不等");
    }
    //不等
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
