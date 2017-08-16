
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface RNReactNativePdfLib : NSObject <RCTBridgeModule>

+ (void) testLog;

+ (void) letsTryAgain;

+ (NSString*) oneLastTime;

@end
  
