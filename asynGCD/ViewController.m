//
//  ViewController.m
//  asynGCD
//
//  Created by YZK on 2019/5/8.
//  Copyright © 2019 YZK. All rights reserved.
//

#import "ViewController.h"
#import "MyObject.h"
#import "MyDataManager.h"

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

- (IBAction)buttonclicked3:(id)sender {
    //创建一个新的DataManager，模拟我们日常工作中的数据层
    MyDataManager *dm = [[MyDataManager alloc] init];

    // 创建一个请求，由于和self、dm等没有引用关系，所以这里不使用__weak修饰，不会有循环引用的问题。
    MyObject *request = [[MyObject alloc] init];
    request.completion = ^{
        //模拟接口请求回来后，刷新数据逻辑
        [dm refresh];
    };
    
    //模拟异步请求，3s后收到response
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        // do something parse data，例如JSON解析
        
        //模拟异步主线程，回调完成
        dispatch_async(dispatch_get_main_queue(), ^{
            request.completion();
            
            //模拟结束后,异步线程做一些性能统计等事情。
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [request doSomething];
            });
        });
    });
    
    //模拟页面请求，接口完成前退出页面，需要销毁的情况
    NSLog(@"finish, dm should dealloc");
}

/* log
 finish, dm should dealloc
 refresh with data
 do something
 MyObject dealloc
 MyDataManager dealloc: <NSThread: 0x600001e57a80>{number = 6, name = (null)}
 */

@end
