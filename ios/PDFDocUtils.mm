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

+ (NSString*)modify :(NSDictionary*)documentActions
{
    NSString *path = documentActions[@"path"];
    PDFWriter pdfWriter;
    EStatusCode esc;
    
    esc = pdfWriter.ModifyPDF(path.UTF8String, ePDFVersionMax, @"".UTF8String);
    if (esc == EStatusCode::eFailure)
    {
        return nil;
    }
    
    // Process pages
    NSArray *modifyPages = documentActions[@"modifyPages"];
    for (NSDictionary *page in modifyPages)
    {
        [PDFDocUtils modifyPageWithWriter:&pdfWriter andActions:page];
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
        else if([type isEqualToString:@"rectangle"])
        {
            [PDFDocUtils addRectToContext:context withActions:action];
        }
        else if([type isEqualToString:@"image"])
        {
            [PDFDocUtils addImageToContext:context withActions:action];
        }
    }
    
    pdfWriter->EndPageContentContext(context);
    pdfWriter->WritePageAndRelease(page);
}

+ (void) modifyPageWithWriter:(PDFWriter*)pdfWriter andActions:(NSDictionary*)pageActions
{
    NSInteger pageIndex = [RCTConvert NSInteger:pageActions[@"pageIndex"]];
    PDFModifiedPage page(pdfWriter, pageIndex);
    AbstractContentContext *context = page.StartContentContext();
    
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
        else if([type isEqualToString:@"rectangle"])
        {
            [PDFDocUtils addRectToContext:context withActions:action];
        }
        else if([type isEqualToString:@"image"])
        {
            [PDFDocUtils addImageToContext:context withActions:action];
        }
    }
    
    page.EndContentContext();
    page.WritePage();
}

+ (void) addTextToContext:(AbstractContentContext*)context withActions:(NSDictionary*)textActions andFont:(PDFUsedFont*)font
{
    NSString *value    = [RCTConvert NSString:textActions[@"value"]];
    NSInteger fontSize = [RCTConvert NSInteger:textActions[@"fontSize"]];
    
    NSInteger xCoord   = [RCTConvert NSInteger:textActions[@"position"][@"x"]];
    NSInteger yCoord   = [RCTConvert NSInteger:textActions[@"position"][@"y"]];
    
    unsigned hexColor = [PDFDocUtils hexIntFromString:textActions[@"color"]];

    AbstractContentContext::TextOptions textOptions(font, fontSize, AbstractContentContext::eRGB, hexColor);
    context->WriteText(xCoord, yCoord, value.UTF8String, textOptions);
}

+ (void) addRectToContext:(AbstractContentContext*)context withActions:(NSDictionary*)rectActions
{
    NSInteger x      = [RCTConvert NSInteger:rectActions[@"x"]];
    NSInteger y      = [RCTConvert NSInteger:rectActions[@"y"]];
    NSInteger width  = [RCTConvert NSInteger:rectActions[@"width"]];
    NSInteger height = [RCTConvert NSInteger:rectActions[@"height"]];
    
    unsigned hexColor = [PDFDocUtils hexIntFromString:rectActions[@"color"]];
    
    AbstractContentContext::GraphicOptions options(AbstractContentContext::eFill,
                                                   AbstractContentContext::eRGB,
                                                   hexColor);
    context->DrawRectangle(x, y, width, height, options );
}

+ (void) addImageToContext:(AbstractContentContext*)context withActions:(NSDictionary*)imageActions
{
    NSString *imageType = [RCTConvert NSString:imageActions[@"imageType"]];
    NSString *imagePath = [RCTConvert NSString:imageActions[@"imagePath"]];
    
    NSInteger x = [RCTConvert NSInteger:imageActions[@"x"]];
    NSInteger y = [RCTConvert NSInteger:imageActions[@"y"]];
    
    AbstractContentContext::ImageOptions options;
    
    if ([imageType isEqualToString:@"jpg"])
    {
        if (imageActions[@"width"] && imageActions[@"height"])
        {
            NSInteger width  = [RCTConvert NSInteger:imageActions[@"width"]];
            NSInteger height = [RCTConvert NSInteger:imageActions[@"height"]];
            options.transformationMethod = AbstractContentContext::EImageTransformation::eFit;
            options.fitPolicy = AbstractContentContext::EFitPolicy::eAlways;
            options.boundingBoxWidth  = width;
            options.boundingBoxHeight = height;
        }
        context->DrawImage(x, y, imagePath.UTF8String, options);
    }
}

// We get a color as a hex string, e.g. "#F0F0F0" - so parse to an integer
+ (unsigned) hexIntFromString:(NSString*)hexStr
{
    unsigned hexColor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&hexColor];
    return hexColor;
}

@end

























































