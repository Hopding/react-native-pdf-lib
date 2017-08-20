#import <Foundation/Foundation.h>

@interface PDFDocUtils : NSObject

+ (NSString*)generate :(NSDictionary*)documentActions;

+ (NSString*)modify :(NSDictionary*)documentActions;

@end
