//
//  ViewController.m
//  asynGCD
//
//  Created by YZK on 2019/5/8.
//  Copyright © 2019 YZK. All rights reserved.
//

#import "ViewController.h"
#import "MyObject.h"

@interface ViewController ()

@end

@implementation ViewController

+ (dispatch_queue_t)layoutQueue
{
    static dispatch_queue_t layoutQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        layoutQueue = dispatch_queue_create("com.immomo.layout", NULL);
    });
    return layoutQueue;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)buttonclickedasyn:(id)sender {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"1");
        dispatch_sync(queue, ^{
            NSLog(@"2");
        });
        NSLog(@"3");
    });
}
//  输出 1、2、3

- (IBAction)buttonclickedSerial:(id)sender {
    dispatch_queue_t serialQueue = dispatch_queue_create("test", NULL);
    dispatch_async(serialQueue, ^{
        NSLog(@"4");
        dispatch_sync(serialQueue, ^{
            NSLog(@"5");
        });
        NSLog(@"6");
    });
}
// 死锁



- (IBAction)buttonclickedweak:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        MyObject *obj = [[MyObject alloc] init];
        
        __weak typeof(obj) weakObj = obj;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"GCD--sleepBefore obj:%@",weakObj);
            sleep(3);
            NSLog(@"GCD--sleepAfter obj:%@",weakObj);
        });
        sleep(1);
        obj = nil;
        NSLog(@"已经设为nil");
    });
}

/* log
 GCD--sleepBefore obj:<MyObject: 0x60c00000eed0>
 MyObject dealloc
 已经设为nil
 GCD--sleepAfter obj:(null)
 */



- (IBAction)buttonclicked:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        MyObject *obj = [[MyObject alloc] init];
        __weak typeof(obj) weakObj = obj;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            __strong typeof(weakObj) strongObj = weakObj;
            sleep(3);
            NSLog(@"GCD--obj:%@",strongObj);
        });
        sleep(1);
        obj = nil;
        NSLog(@"已经设为nil");
    });
}

/* log:
 已经设为nil
 GCD--obj:<MyObject: 0x60800000f080>
 MyObject dealloc
 */



- (IBAction)buttonclicked2:(id)sender {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        MyObject *obj = [[MyObject alloc] init];
        
        __weak typeof(obj) weakObj = obj;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            __strong typeof(weakObj) strongObj = weakObj;
            sleep(3);
            NSLog(@"GCD--obj:%@",strongObj);
        });
        obj = nil;
        NSLog(@"已经设为nil");
    });
}

/* log
 MyObject dealloc
 已经设为nil
 GCD--obj:(null)
 */


@end
