#import "PDFLib.h"

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

+ (NSString*) documentsDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(test,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    // Open new PDF
    NSString *pdfPath = [NSString stringWithFormat:@"%@/%@", [PDFLib documentsDir], @"test.pdf"];
    PDFWriter pdfWriter;
    EStatusCode esc1 = pdfWriter.StartPDF(pdfPath.UTF8String, ePDFVersionMax);
    
    if (esc1 == EStatusCode::eFailure) {
        NSError *error = [[NSError alloc] init];
        reject(@"Something went wrong?", @"pdfWriter.StartPDF FAILED!!!!", error);
    }

    // First page
    PDFPage *page = new PDFPage();
    page->SetMediaBox(PDFRectangle(0, 0, 595, 842));
    PageContentContext* contentContext = pdfWriter.StartPageContentContext(page);
    AbstractContentContext::GraphicOptions pathFillOptions(AbstractContentContext::eFill,
                                                           AbstractContentContext::eCMYK,
                                                           0x00FF99);
    contentContext->DrawRectangle(250, 100, 350, 350, pathFillOptions);
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
        NSError *error = [[NSError alloc] init];
        reject(@"Something went wrong?", @"pdfWriter.EndPDF FAILED!!!", error);
    }

    resolve(pdfPath);
}

@end

