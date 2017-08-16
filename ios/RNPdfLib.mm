#import "RNPdfLib.h"
#import "PDFWriter.h"

#if __has_include(<React/RCTEventDispatcher.h>)
#else
#import "RCTEventDispatcher.h"
#endif

@implementation RNPdfLib

RCT_EXPORT_MODULE()

//@property (NSString*) test

RCT_REMAP_METHOD(testGetStrProm,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve(@"This is another module's promise resolution!");
}

//@property (NSString*) test
//
//RCT_EXPORT_METHOD(testPDFWriter:(RCTResponseSenderBlock)callback)
//{
//    resolve(@"This is another module's promise resolution!");
//}


@end

