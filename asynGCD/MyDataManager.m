//
//  MyDataManager.m
//  asynGCD
//
//  Created by ByteDance on 2023/9/14.
//  Copyright © 2023 YZK. All rights reserved.
//

#import "MyDataManager.h"

@implementation MyDataManager

- (void)dealloc {
    NSLog(@"MyDataManager dealloc: %@", [NSThread currentThread]);
}

- (void)refresh {
    NSLog(@"refresh with data");
}


@end
