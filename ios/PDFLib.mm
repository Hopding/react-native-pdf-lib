#import "PDFLib.h"
#import "PDFWriterFactory.h"

#include <PDFWriter.h>
#include <PDFPage.h>
#include <PageContentContext.h>
#include <libgen.h>
#include <PDFModifiedPage.h>

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
    NSString* path = PDFWriterFactory::create(documentActions);
    if (path == nil)
    {
        reject(@"error", @"Error generating PDF!", nil);
    }
    else
    {
        resolve(path);
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

RCT_REMAP_METHOD(launchPDFViewer,
                 forFile:(NSString*)pdfFile
                 :(RCTPromiseResolveBlock)resolve
                 :(RCTPromiseRejectBlock)reject)
{
    reject(@"error", @"launchPDFViewer is only supported for Android", nil);
}

RCT_REMAP_METHOD(getPDFsDir,
                  resolverPDFsDir:(RCTPromiseResolveBlock)resolve
                  rejecterPDFsDir:(RCTPromiseRejectBlock)reject)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    resolve(paths.firstObject);
}

RCT_REMAP_METHOD(getDocumentsDirectory,
                 resolverDocssDir:(RCTPromiseResolveBlock)resolve
                 rejecterDocssDir:(RCTPromiseRejectBlock)reject)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    resolve(paths.firstObject);
}

RCT_REMAP_METHOD(unloadAsset,
                 :(NSString*)path
                 :(NSString*)nada // Need this for consistent interface with Android
                 resolverUnloadAsset:(RCTPromiseResolveBlock)resolve
                 rejecterUnloadAsset:(RCTPromiseRejectBlock)reject)
{
    resolve([[NSBundle mainBundle] pathForResource:path ofType:nil]);
}

@end































