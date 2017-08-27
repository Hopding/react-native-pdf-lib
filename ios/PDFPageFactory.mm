#include <Foundation/Foundation.h>
#include <React/RCTConvert.h>
#include <stdexcept>
#include "PDFPageFactory.h"
#include "IByteReaderWithPosition.h"
#include "InputByteArrayStream.h"
#include "IPageEndWritingTask.h"

class PageImageWritingTask : public IPageEndWritingTask
{
public:
    PageImageWritingTask(const std::string& inImagePath,unsigned long inImageIndex,ObjectIDType inObjectID,const PDFParsingOptions& inPDFParsingOptions)
    {
        mImagePath = inImagePath;
        mImageIndex = inImageIndex;
        mObjectID = inObjectID;
        mPDFParsingOptions = inPDFParsingOptions;
    }
    
    virtual ~PageImageWritingTask(){}
    
    virtual PDFHummus::EStatusCode Write(PDFPage* inPageObject,
                                         ObjectsContext* inObjectsContext,
                                         PDFHummus::DocumentContext* inDocumentContext)
    {
        return inDocumentContext->WriteFormForImage(mImagePath,mImageIndex,mObjectID,mPDFParsingOptions);
    }

private:
    std::string mImagePath;
    unsigned long mImageIndex;
    ObjectIDType mObjectID;
    PDFParsingOptions mPDFParsingOptions;
};

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, PDFPage* page, AbstractContentContext* context) {
    NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"Times New Roman" ofType:@".ttf"];

    this->pdfWriter = pdfWriter;
    this->page      = page;
    this->context   = context;
    this->font      = pdfWriter->GetFontForFile(fontPath.UTF8String);
}

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, PDFModifiedPage* page, AbstractContentContext* context) {
    NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"Times New Roman" ofType:@".ttf"];
    
    this->pdfWriter    = pdfWriter;
    this->modifiedPage = page;
    this->context      = context;
    this->font         = pdfWriter->GetFontForFile(fontPath.UTF8String);
}

ResourcesDictionary* PDFPageFactory::getResourcesDict () {
    // Determine if we have a PDFPage or a PDFModifiedPage
    if (this->page != nullptr) {
        return &this->page->GetResourcesDictionary();
    }
    else if (this->modifiedPage != nullptr) {
        return this->modifiedPage->GetCurrentResourcesDictionary();
    }
    return nullptr; // This should never happen...
}

void PDFPageFactory::createAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions) {
    PDFPage* page = new PDFPage();
    PageContentContext* context = pdfWriter->StartPageContentContext(page);
    PDFPageFactory factory(pdfWriter, page, context);
    
    NumberPair coords = getCoords(pageActions[@"mediaBox"]);
    NumberPair dims   = getDims(pageActions[@"mediaBox"]);
    page->SetMediaBox(PDFRectangle(coords.a.intValue,
                                   coords.b.intValue,
                                   dims.a.intValue,
                                   dims.b.intValue));
    factory.applyActions(pageActions[@"actions"]);
    pdfWriter->EndPageContentContext(context);
    pdfWriter->WritePageAndRelease(page);
}

void PDFPageFactory::modifyAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions) {
    NSInteger pageIndex = [RCTConvert NSInteger:pageActions[@"pageIndex"]];
    PDFModifiedPage page(pdfWriter, pageIndex);
    AbstractContentContext* context = page.StartContentContext();
    PDFPageFactory factory(pdfWriter, &page, context);
    
    factory.applyActions(pageActions[@"actions"]);
    page.EndContentContext();
    page.WritePage();
}

void PDFPageFactory::applyActions (NSDictionary* actions) {
    for (NSDictionary *action in actions) {
        NSString *type = [RCTConvert NSString:action[@"type"]];
        if ([type isEqualToString:@"text"]) {
            drawText(action);
        }
        else if([type isEqualToString:@"rectangle"]) {
            drawRectangle(action);
        }
        else if([type isEqualToString:@"image"]) {
            drawImage(action);
        }
        else if([type isEqualToString:@"pdfImage"]) {
            drawImageAsPDF(action);
        }
    }
}

void PDFPageFactory::drawText (NSDictionary* textActions) {
    NSString* value    = [RCTConvert NSString:textActions[@"value"]];
    NSInteger fontSize = [RCTConvert NSInteger:textActions[@"fontSize"]];
    NumberPair coords  = getCoords(textActions);
    unsigned hexColor  = hexIntFromString(textActions[@"color"]);
    
    AbstractContentContext::TextOptions textOptions(font, fontSize, AbstractContentContext::eRGB, hexColor);
    context->WriteText(coords.a.intValue, coords.b.intValue, value.UTF8String, textOptions);
}

void PDFPageFactory::drawRectangle (NSDictionary* rectActions) {
    NumberPair coords = getCoords(rectActions);
    NumberPair dims   = getDims(rectActions);
    unsigned hexColor = hexIntFromString(rectActions[@"color"]);
    
    AbstractContentContext::GraphicOptions options(AbstractContentContext::eFill,
                                                   AbstractContentContext::eRGB,
                                                   hexColor);
    context->DrawRectangle(coords.a.intValue,
                           coords.b.intValue,
                           dims.a.intValue,
                           dims.b.intValue,
                           options);
}

void PDFPageFactory::drawImage (NSDictionary* imageActions) {
    NSString *imageType = [RCTConvert NSString:imageActions[@"imageType"]];
    NSString *imagePath = [RCTConvert NSString:imageActions[@"imagePath"]];
    NumberPair coords   = getCoords(imageActions);
    NumberPair dims     = getDims(imageActions);
    AbstractContentContext::ImageOptions options;
    
    if ([imageType isEqualToString:@"jpg"]) {
        if (dims.a && dims.b) {
            options.transformationMethod = AbstractContentContext::EImageTransformation::eFit;
            options.fitPolicy            = AbstractContentContext::EFitPolicy::eAlways;
            options.boundingBoxWidth     = dims.a.intValue;
            options.boundingBoxHeight    = dims.b.intValue;
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            NSString *msg = [NSString stringWithFormat:@"%@%@", @"No image found at path: ", imagePath];
            throw std::invalid_argument(msg.UTF8String);
        }
        context->DrawImage(coords.a.intValue, coords.b.intValue, imagePath.UTF8String, options);
    }
}

void PDFPageFactory::drawImageAsPDF (NSDictionary* imageActions) {
    NSString *imageType = [RCTConvert NSString:imageActions[@"imageType"]];
    NSString *imagePath = [RCTConvert NSString:imageActions[@"imagePath"]];
    NumberPair coords   = getCoords(imageActions);
    NumberPair dims     = getDims(imageActions);
    AbstractContentContext::ImageOptions options;
    
    if ([imageType isEqualToString:@"jpg"] || [imageType isEqualToString:@"png"]) {
        if (dims.a && dims.b) {
            options.transformationMethod = AbstractContentContext::EImageTransformation::eFit;
            options.fitPolicy            = AbstractContentContext::EFitPolicy::eAlways;
            options.boundingBoxWidth     = dims.a.intValue;
            options.boundingBoxHeight    = dims.b.intValue;
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            NSString *msg = [NSString stringWithFormat:@"%@%@", @"No image found at path: ", imagePath];
            throw std::invalid_argument(msg.UTF8String);
        }
        
        UIImage* image   = [UIImage imageWithContentsOfFile:imagePath];
        NSData* imagePDF = PDFPageFactory::convertImageToPDF(image);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docsDir = paths.firstObject;
        NSString* path = [NSString stringWithFormat:@"%@/%@", docsDir, @"image.pdf"];
        
        [imagePDF writeToFile:path atomically:true];
        pdfWriter->EndPageContentContext((PageContentContext*)context);
        EStatusCodeAndObjectIDTypeList result =
            pdfWriter->CreateFormXObjectsFromPDF(path.UTF8String,
                                                    PDFPageRange(),
                                                    ePDFPageBoxMediaBox);
        context = pdfWriter->StartPageContentContext(page);
        
//        ObjectIDTypeAndBool result = pdfWriter->GetDocumentContext().RegisterImageForDrawing(path.UTF8String, options.imageIndex);
//        if(result.second)
//        {
//            // if first usage, write the image
////            ScheduleImageWrite(path.UTF8String, options.imageIndex, result.first, options.pdfParsingOptions);
////            pdfWriter->GetDocumentContext().RegisterPageEndWritingTask(page,
//            //                                                         new PageImageWritingTask(inImagePath,inImageIndex,inObjectID,inParsingOptions));
//            NSLog(@"Doing RegisterPageEndWritingTask...");
//            pdfWriter->GetDocumentContext().RegisterPageEndWritingTask(page,
//                                                                       new PageImageWritingTask(path.UTF8String,
//                                                                                                     options.imageIndex,
//                                                                                                     result.first,
//                                                                                                     options.pdfParsingOptions));
////            pdfWriter->GetDocumentContext().WriteFormForImage(path.UTF8String, options.imageIndex, result.first);
//        }
//        double transformation[6] = {1,0,0,1,0,0};
//        context->q();
//        context->cm(transformation[0],transformation[1],transformation[2],transformation[3],transformation[4],transformation[5]);
//        context->Do(getResourcesDict()->AddFormXObjectMapping(result.first));
//        context->Q();

        
//        IOBasicTypes::Byte* bytes = (unsigned char*)[imagePDF bytes];
//        InputByteArrayStream imageStream(bytes, 0);
//        EStatusCodeAndObjectIDTypeList result =
//            pdfWriter->CreateFormXObjectsFromPDF((IByteReaderWithPosition*)&imageStream,
//                                                 PDFPageRange(),
//                                                 ePDFPageBoxMediaBox);
//        if (result.first == EStatusCode::eFailure) {
//            NSLog(@"%@", @"IT DIDNT WORK!!!");
//        }
//        NSLog(@"%@%lu", @"Form ID: ", result.second.front());
        
//        std::string x = getResourcesDict()->AddFormXObjectMapping(result.second.front());
//        NSString *msg = [NSString stringWithCString:x.c_str()
//                                                    encoding:[NSString defaultCStringEncoding]];
//        NSLog(@"%@%@", @"...AddFormXObjectMapping...: ", msg);
//        ObjectIDTypeList::iterator it = result.second.begin();
//        ObjectIDType firstPageID = *it;
//
        context->q();
        double transformation[6] = {1,0,0,1,0,0};
        context->cm(transformation[0],transformation[1],transformation[2],transformation[3],transformation[4],transformation[5]);
//        context->cm(0.5,0,0,0.5,0,421);
//        context->Do(getResourcesDict()->AddFormXObjectMapping(result.first));
        context->Do(getResourcesDict()->AddFormXObjectMapping(result.second.front()));
//        context->Do(getResourcesDict()->AddFormXObjectMapping(firstPageID));
        context->Q();
        
//        context->DrawImage(coords.a.intValue, coords.b.intValue, path.UTF8String, options);
    }
}

NSData* PDFPageFactory::convertImageToPDF (UIImage* image) {
    NSMutableData *pdfData = [[NSMutableData alloc] init];
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)pdfData);
    const CGRect mediaBox = CGRectMake(0.0f, 0.0f, [image size].width, [image size].height);
    CGContextRef pdfContext = CGPDFContextCreate(dataConsumer, &mediaBox, NULL);
    
    CGContextBeginPage(pdfContext, &mediaBox);
    CGContextDrawImage(pdfContext, mediaBox, [image CGImage]);
    CGContextEndPage(pdfContext);
    
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);
    CGDataConsumerRelease(dataConsumer);
    
    return pdfData;
}

NumberPair PDFPageFactory::getCoords (NSDictionary* coordsMap) {
    return PDFPageFactory::getNumberKeyPair(coordsMap, @"x", @"y");
}

NumberPair PDFPageFactory::getDims (NSDictionary* dimsMap) {
    return PDFPageFactory::getNumberKeyPair(dimsMap, @"width", @"height");
}

NumberPair PDFPageFactory::getNumberKeyPair (NSDictionary* map, NSString* key1, NSString* key2) {
    NSNumber *a = nil;
    NSNumber *b = nil;
    
    if (map[key1] && map[key2]) {
        a = [RCTConvert NSNumber:map[key1]];
        b = [RCTConvert NSNumber:map[key2]];
    }
    
    return NumberPair { a, b };
}

unsigned PDFPageFactory::hexIntFromString (NSString* hexStr) {
    unsigned hexColor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&hexColor];
    return hexColor;
}

































