# \_\_strong和\_\_weak的用处


#### 背景
iOS日常开发中，当我们用到block的时候，常常需要将变量声明为`__weak`，用来防止循环引用。但是在block内部，为什么要再声明为`__strong`？

#### 示例

`Don't BB, show me the code.` 作为一名程序猿，还是直接上代码比较直观，便于理解。

* __eg1__，单纯使用`__weak`的缺点：

``` objc
@interface MyObject : NSObject
@end

@implementation MyObject
- (void)dealloc {
    NSLog(@"MyObject dealloc");
}
@end


- (IBAction)buttonClickedWeak:(id)sender {
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
```

如上所示代码，各位看官可以先分析一下，控制台输出的log应该是什么样的，看看和实际结果是否一样。

下面是实际的log输出

``` objc
 GCD--sleepBefore obj:<MyObject: 0x60c00000eed0>
 MyObject dealloc
 已经设为nil
 GCD--sleepAfter obj:(null)
```

这里我们把第一个并行队列叫作队列 A ，第二个为队列 B ，显然，当队列 A `sleep`时，队列 B 已经执行到第一行log，所以这里`GCD--sleepBefore`的log 可以正常打印出obj。跟着队列 A 被唤醒，obj被置为nil，被释放。所以队列 B 3秒唤醒后，`GCD--sleepAfter`的log打印的obj为`null`。



* __eg2__，联合使用`__weak`和`__strong`：

``` objc
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
```

这次我在block内部强引用了obj，是否可以在队列 B 3s被唤醒后正确的输出呢？

下面是实际的log输出

``` objc
 MyObject dealloc
 已经设为nil
 GCD--obj:(null)
```

我们看到，依然不能正确输出，这是因为，block内部声明为`__strong`只能保证对象在block内部会被强引用，也就是在block执行过程中不会被释放，但是如果在执行到block的时候，对象已经被释放，声明`__strong`也并不能解决这个问题。上面所示代码，因为block引用到的外部变量`weakObj`被声明为`__weak`，所以block不会强引用obj，所以obj被赋值为nil，会立马触发析构函数，释放obj。所以当执行到block内部的`__strong typeof(weakObj) strongObj = weakObj;`这条语句时，实际上相当于`__strong typeof(weakObj) strongObj = nil;`



* __eg3__，联合使用`__weak`和`__strong`：

``` objc
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
```

这次我在 obj 赋值`nil`之前，使队列 A `sleep`1秒，保证进入队列 B 的时候，obj没有被释放，是否可以在队列 B 3s被唤醒后正确的输出呢？

下面是实际的log输出

``` objc
 已经设为nil
 GCD--obj:<MyObject: 0x60800000f080>
 MyObject dealloc
```

这次被正常的输出了，这是因为obj 赋值`nil`之前，已经执行了对列 B 中的`__strong`声明，此时obj会被block强引用，当obj 在外面被赋值`nil`后，并不会触发析构函数，而是在block走完后触发析构。

#### 结论

单纯使用`__weak`，有可能造成block中的变量，在执行过程中被释放，导致代码上逻辑错误。所以推荐在block内部使用`__strong`。当然，在block内部使用`__strong`也只能保证block内部执行过程中不会释放对应的对象，并不能保证该对象在执行到block时没有被释放。

最后附上[demo](https://github.com/whlpkk/asynGCD)，小伙伴可以下载代码进行测试。