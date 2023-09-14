//
//  MyObject.h
//  asynGCD
//
//  Created by YZK on 2019/5/8.
//  Copyright © 2019 YZK. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyObject : NSObject

@property (nonatomic, copy) void (^completion)(void);
- (void)doSomething;

@end

NS_ASSUME_NONNULL_END
