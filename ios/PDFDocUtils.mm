#import <Foundation/Foundation.h>
#import "PDFDocUtils.h"

#include <PDFWriter.h>
#include <PDFPage.h>
#include <PageContentContext.h>
#include <libgen.h>
#include <PDFModifiedPage.h>

#include <React/RCTConvert.h>

@implementation PDFDocUtils

+ (NSString*)generate :(NSDictionary*)documentActions
{
    NSString *path = documentActions[@"path"];
    NSLog(@"Saving PDF to path: %@", path);
    
    PDFWriter pdfWriter;
    EStatusCode esc;
    
    esc = pdfWriter.StartPDF(path.UTF8String, ePDFVersion13);
    if (esc == EStatusCode::eFailure)
    {
        return nil;
    }
    
    // Process pages
    NSArray *pages = documentActions[@"pages"];
    for (NSDictionary *page in pages)
    {
        [PDFDocUtils addPageToWriter:&pdfWriter withActions:page];
    }
    
    esc = pdfWriter.EndPDF();
    if (esc == EStatusCode::eFailure)
    {
        return nil;
    }
    
    return path;
}

+ (PDFRectangle) createPDFRectangle:(NSDictionary*)rectangleActions
{
    NSInteger x      = [RCTConvert NSInteger:rectangleActions[@"x"]];
    NSInteger y      = [RCTConvert NSInteger:rectangleActions[@"y"]];
    NSInteger width  = [RCTConvert NSInteger:rectangleActions[@"width"]];
    NSInteger height = [RCTConvert NSInteger:rectangleActions[@"height"]];
    
    return PDFRectangle(x, y, width, height);
}

+ (void) addPageToWriter:(PDFWriter*)pdfWriter withActions:(NSDictionary*)pageActions
{
    PDFPage *page = new PDFPage();
    page->SetMediaBox([PDFDocUtils createPDFRectangle:pageActions[@"mediaBox"]]);
    PageContentContext *context = pdfWriter->StartPageContentContext(page);
    
    // Apply actions to the page
    NSArray *actions = pageActions[@"actions"];
    for (NSDictionary *action in actions)
    {
        NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"Times New Roman" ofType:@".ttf"];
        PDFUsedFont *font = pdfWriter->GetFontForFile(fontPath.UTF8String);
        
        NSString *type = [RCTConvert NSString:action[@"type"]];
        if ([type isEqualToString:@"text"])
        {
            [PDFDocUtils addTextToContext:context withActions:action andFont:font];
        }
    }
    
    pdfWriter->EndPageContentContext(context);
    pdfWriter->WritePageAndRelease(page);
}

+ (void) addTextToContext:(PageContentContext*)context withActions:(NSDictionary*)textActions andFont:(PDFUsedFont*)font
{
    NSString *value    = [RCTConvert NSString:textActions[@"value"]];
    NSInteger fontSize = [RCTConvert NSInteger:textActions[@"fontSize"]];
    
    NSInteger xCoord   = [RCTConvert NSInteger:textActions[@"position"][@"x"]];
    NSInteger yCoord   = [RCTConvert NSInteger:textActions[@"position"][@"y"]];
    
    // We get a color as a hex string, e.g. "#F0F0F0" - so parse to an integer
    unsigned hexColor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:textActions[@"color"]];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&hexColor];

    AbstractContentContext::TextOptions textOptions(font, fontSize, AbstractContentContext::eRGB, hexColor);
    context->WriteText(xCoord, yCoord, value.UTF8String, textOptions);
}

@end
