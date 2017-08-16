#import "RNReactNativePdfLib.h"
#if __has_include(<React/RCTEventDispatcher.h>)
#else
#import "RCTEventDispatcher.h"
#endif

@implementation RNReactNativePdfLib

+ (void) testLog
{
    NSLog(@"This is logged from my library LMAO");
}

+ (void) letsTryAgain
{
    NSLog(@"Lets try again..");
}

+ (NSString*) oneLastTime
{
    return @"one last time...";
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(testGetStr:(RCTResponseSenderBlock)callback)
{
    callback(@[@"This is from Objective C!"]);
}

RCT_REMAP_METHOD(testGetStrProm,
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(@"This is a promise resolution!");
}

RCT_EXPORT_METHOD(testObjCLog)
{
    NSLog(@"This is a log from objective c!");
}

@end
  
