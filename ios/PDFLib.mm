#import "PDFLib.h"
#import "PDFWriterFactory.h"

#include <PDFWriter.h>
#include <PDFPage.h>
#include <PDFUsedFont.h>
#include <PageContentContext.h>
#include <libgen.h>
#include <PDFModifiedPage.h>

#import <stdexcept>

#if __has_include(<React/RCTEventDispatcher.h>)
#else
#import "RCTEventDispatcher.h"
#endif

@implementation PDFLib

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(createPDF,
                 :(NSDictionary*)documentActions
                 createPDFResolve:(RCTPromiseResolveBlock)resolve
                 createPDFReject:(RCTPromiseRejectBlock)reject)
{
    try {
        NSString* path = PDFWriterFactory::create(documentActions);
        if (path == nil)
        {
            reject(@"error", @"Error generating PDF!", nil);
        }
        else
        {
            resolve(path);
        }
    } catch( const std::invalid_argument& e) {
        NSString *msg = [NSString stringWithCString:e.what()
                                  encoding:[NSString defaultCStringEncoding]];
        reject(@"error", msg, nil);
    }
}

RCT_REMAP_METHOD(modifyPDF,
                 :(NSDictionary*)documentActions
                 modifyPDFResolve:(RCTPromiseResolveBlock)resolve
                 modifyPDFReject:(RCTPromiseRejectBlock)reject)
{
    NSString* path = PDFWriterFactory::modify(documentActions);
    if (path == nil)
    {
        reject(@"error", @"Error modifying PDF!", nil);
    }
    else
    {
        resolve(path);
    }
}

RCT_REMAP_METHOD(test,
                 :(NSString*)text
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = paths.firstObject;
    
    // Open new PDF
    NSString *pdfPath = [NSString stringWithFormat:@"%@/%@", documentsDir, @"test.pdf"];
    PDFWriter pdfWriter;
    EStatusCode esc1 = pdfWriter.StartPDF(pdfPath.UTF8String, ePDFVersionMax);
    
    if (esc1 == EStatusCode::eFailure) {
        reject(@"error", @"pdfWriter.StartPDF FAILED!!!!", nil);
    }

    // First page
    PDFPage *page = new PDFPage();
    page->SetMediaBox(PDFRectangle(0, 0, 595, 842));
    PageContentContext* contentContext = pdfWriter.StartPageContentContext(page);
    
    NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"Times New Roman" ofType:@".ttf"];
    NSLog(@"\n---\n%@\n---", fontPath);
    PDFUsedFont *font = pdfWriter.GetFontForFile(fontPath.UTF8String);
    AbstractContentContext::TextOptions textOptions(font, 14, AbstractContentContext::eGray, 0);
    contentContext->WriteText(10, 100, text.UTF8String, textOptions);
    
    pdfWriter.EndPageContentContext(contentContext);
    pdfWriter.WritePageAndRelease(page);

    // Second page
    PDFPage *page2 = new PDFPage();
    page2->SetMediaBox(PDFRectangle(0, 0, 595, 842));
    PageContentContext* contentContext2 = pdfWriter.StartPageContentContext(page2);
    AbstractContentContext::GraphicOptions pathFillOptions2(AbstractContentContext::eFill,
                                                            AbstractContentContext::eCMYK,
                                                            0xFF00FF);
    contentContext2->DrawRectangle(375, 220, 50, 160, pathFillOptions2);
    pdfWriter.EndPageContentContext(contentContext2);
    pdfWriter.WritePageAndRelease(page2);
    
    // Third page
    PDFPage *page3 = new PDFPage();
    page3->SetMediaBox(PDFRectangle(0, 0, 595, 842));
    PageContentContext* contentContext3 = pdfWriter.StartPageContentContext(page3);
    contentContext3->q();
    contentContext3->k(100,0,0,0);
    contentContext3->re(100,500,100,100);
    contentContext3->f();
    contentContext3->Q();
    pdfWriter.EndPageContentContext(contentContext3);
    pdfWriter.WritePageAndRelease(page3);
    
    // Close PDF
    EStatusCode esc2 = pdfWriter.EndPDF();
    if (esc2 == EStatusCode::eFailure) {
        reject(@"error", @"pdfWriter.EndPDF FAILED!!!", nil);
    }

    resolve(pdfPath);
}

RCT_REMAP_METHOD(getDocumentsDirectory,
                 resolverDocssDir:(RCTPromiseResolveBlock)resolve
                 rejecterDocssDir:(RCTPromiseRejectBlock)reject)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    resolve(paths.firstObject);
}

RCT_REMAP_METHOD(unloadAsset,
                 :(NSString*)assetName
                 :(NSString*)destPath
                 resolverUnloadAsset:(RCTPromiseResolveBlock)resolve
                 rejecterUnloadAsset:(RCTPromiseRejectBlock)reject)
{
    reject(@"error", @"PDFLib.unloadAsset() is only available on Android. Try PDFLib.getAssetpath().", nil);
}

RCT_REMAP_METHOD(getAssetPath,
                 :(NSString*)assetName
                 resolverUnloadAsset:(RCTPromiseResolveBlock)resolve
                 rejecterUnloadAsset:(RCTPromiseRejectBlock)reject)
{
    resolve([[NSBundle mainBundle] pathForResource:assetName ofType:nil]);
}

RCT_REMAP_METHOD(measureText,
                :(NSString*)text
                :(NSString*)fontName
                :(NSInteger*)fontSize
                 resolverMeasureText:(RCTPromiseResolveBlock)resolve
                 rejecterMeasureText:(RCTPromiseRejectBlock)reject)
{
    try {
        PDFWriter pdfWriter;
        NSString *fontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@".ttf"];
        PDFUsedFont *font  = pdfWriter.GetFontForFile(fontPath.UTF8String);
        PDFUsedFont::TextMeasures measures = font->CalculateTextDimensions(text.UTF8String, (long)fontSize);
        NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys
          :@(measures.width),@"width"
          ,@(measures.height),@"height"
          ,nil];
        resolve(result);
    } catch (NSException *exception) {
        reject(@"error", exception.reason, nil);
    }
}

@end































