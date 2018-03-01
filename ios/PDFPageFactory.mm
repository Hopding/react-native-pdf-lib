#include <Foundation/Foundation.h>
#include <React/RCTConvert.h>
#include <stdexcept>
#include "PDFPageFactory.h"
#include "IByteReaderWithPosition.h"
#include "InputByteArrayStream.h"
#include "InputFileStream.h"
#include "InputStringBufferStream.h"
#include "MyStringBuf.h"

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, PDFPage* page) {
    this->pdfWriter    = pdfWriter;
    this->page         = page;
    this->modifiedPage = nullptr;
}

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, PDFModifiedPage* page) {
    this->pdfWriter    = pdfWriter;
    this->modifiedPage = page;
    this->page         = nullptr;
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

void PDFPageFactory::endContext () {
    // Determine if we have a PDFPage or a PDFModifiedPage
    if (this->page != nullptr) {
        pdfWriter->EndPageContentContext((PageContentContext*)context);
    }
    else if (this->modifiedPage != nullptr) {
        modifiedPage->EndContentContext();
    }
    else {
        throw std::invalid_argument(@"No pages found - this should never happen!".UTF8String);
    }
}

void PDFPageFactory::createAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions) {
    PDFPage* page = new PDFPage();
    PDFPageFactory factory(pdfWriter, page);
    
    NumberPair coords = getCoords(pageActions[@"mediaBox"]);
    NumberPair dims   = getDims(pageActions[@"mediaBox"]);
    page->SetMediaBox(PDFRectangle(coords.a.intValue,
                                   coords.b.intValue,
                                   dims.a.intValue,
                                   dims.b.intValue));
    factory.applyActions(pageActions[@"actions"]);
    factory.endContext();
    pdfWriter->WritePageAndRelease(page);
}

void PDFPageFactory::modifyAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions) {
    NSInteger pageIndex = [RCTConvert NSInteger:pageActions[@"pageIndex"]];
    PDFModifiedPage page(pdfWriter, pageIndex);
    PDFPageFactory factory(pdfWriter, &page);
    
    factory.applyActions(pageActions[@"actions"]);
    factory.endContext();
    page.WritePage();
}

void PDFPageFactory::applyActions (NSDictionary* actions) {
    // Add any necessary FormXObjects before opening the Page's ContentContext
    for (NSDictionary *action in actions) {
        NSString *type = [RCTConvert NSString:action[@"type"]];
        if ([type isEqualToString:@"image"]) {
            addPDFImageFormXObject(action);
        }
    }
    
    // Start the Page's ContentContext
    if (page != nullptr) {
        context = pdfWriter->StartPageContentContext(page);
    }
    else if (modifiedPage != nullptr) {
        context = modifiedPage->StartContentContext();
    }
    else {
        throw std::invalid_argument(@"No pages found - this should never happen!".UTF8String);
    }
    
    // Operate on the Page's ContentContext
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
    }
}

// Add a FormXObject to the PDFWriter for the image specified in the given `pdfImageActions`.
void PDFPageFactory::addPDFImageFormXObject (NSDictionary* pdfImageActions) {
    NSString *imageType = [RCTConvert NSString:pdfImageActions[@"imageType"]];
    NSString *imagePath = [RCTConvert NSString:pdfImageActions[@"imagePath"]];
    AbstractContentContext::ImageOptions options;
    
    if ([imageType isEqualToString:@"png"]) {
        if(![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            NSString *msg = [NSString stringWithFormat:@"%@%@", @"No image found at path: ", imagePath];
            throw std::invalid_argument(msg.UTF8String);
        }
        
        UIImage* image   = [UIImage imageWithContentsOfFile:imagePath];
        NSData* imagePDF = PDFPageFactory::convertImageToPDF(image);
        
        IOBasicTypes::Byte* bytes = (unsigned char*)[imagePDF bytes];
        InputByteArrayStream imageStream(bytes, [imagePDF length]*sizeof(char));
        EStatusCodeAndObjectIDTypeList result = pdfWriter->CreateFormXObjectsFromPDF((IByteReaderWithPosition*)&imageStream,
                                                                                     PDFPageRange(),
                                                                                     ePDFPageBoxMediaBox);
        if (result.first == EStatusCode::eFailure) {
            throw std::invalid_argument(@"Failed to embed PDF!".UTF8String);
        }
        
        // Store the FormXObject's ID under the key for the image
        formXObjectMap.insert(std::pair<NSString*, unsigned long>(imagePath, result.second.front()));
    }
}

void PDFPageFactory::drawText (NSDictionary* textActions) {
    NSString* value    = [RCTConvert NSString:textActions[@"value"]];
    NSString* fontName = [RCTConvert NSString:textActions[@"fontName"]];
    NSInteger fontSize = [RCTConvert NSInteger:textActions[@"fontSize"]];
    NumberPair coords  = getCoords(textActions);
    unsigned hexColor  = hexIntFromString(textActions[@"color"]);

    NSString *fontPath = [[NSBundle mainBundle] pathForResource:fontName ofType:@".ttf"];
    PDFUsedFont* font  = pdfWriter->GetFontForFile(fontPath.UTF8String);

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
    
    if ([imageType isEqualToString:@"jpg"]) {
        NSString *imagePath = [RCTConvert NSString:imageActions[@"imagePath"]];
        NumberPair coords   = getCoords(imageActions);
        NumberPair dims     = getDims(imageActions);
        AbstractContentContext::ImageOptions options;
        
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
    else if ([imageType isEqualToString:@"png"]) {
        drawImageAsPDF(imageActions);
    }
}

void PDFPageFactory::drawImageAsPDF (NSDictionary* imageActions) {
    // Initialize relevant variables
    NSString *imageType = [RCTConvert NSString:imageActions[@"imageType"]];
    NSString *imagePath = [RCTConvert NSString:imageActions[@"imagePath"]];
    NumberPair coords   = getCoords(imageActions);
    NumberPair dims     = getDims(imageActions);
    AbstractContentContext::ImageOptions options;
    
    // Only go this for JPGs & PNGs
    if ([imageType isEqualToString:@"jpg"] || [imageType isEqualToString:@"png"]) {
        UIImage* image = [UIImage imageWithContentsOfFile:imagePath];

        if (dims.a && dims.b) {
            options.transformationMethod = AbstractContentContext::EImageTransformation::eFit;
            options.fitPolicy            = AbstractContentContext::EFitPolicy::eAlways;
            options.boundingBoxWidth     = dims.a.intValue;
            options.boundingBoxHeight    = dims.b.intValue;
//            options.fitProportional = true;
        }
        
        double transformation[6] = {1,0,0,1,0,0};
        /* --- Adjust transform matrix to scale the image appropriately --- */
        if(options.transformationMethod == AbstractContentContext::eMatrix) {
            for(int i = 0; i < 6; ++i)
                transformation[i] = options.matrix[i];
        }
        else if(options.transformationMethod == AbstractContentContext::eFit) {
            double scaleX = 1;
            double scaleY = 1;
            
            if(options.fitPolicy == AbstractContentContext::eAlways) {
                scaleX = options.boundingBoxWidth  / [image size].width;
                scaleY = options.boundingBoxHeight / [image size].height;
            }
            else if([image size].width  > options.boundingBoxWidth ||
                    [image size].height > options.boundingBoxHeight)
            { // Overflow
                scaleX = [image size].width  > options.boundingBoxWidth  ? options.boundingBoxWidth  / [image size].width  : 1;
                scaleY = [image size].height > options.boundingBoxHeight ? options.boundingBoxHeight / [image size].height : 1;
            }
            
            if(options.fitProportional) {
                scaleX = std::min(scaleX, scaleY);
                scaleY = scaleX;
            }
            
            transformation[0] = scaleX;
            transformation[3] = scaleY;
        }
        
        transformation[4] += coords.a.intValue;
        transformation[5] += coords.b.intValue;
        /* ----------------------------------------------------------------- */
        
        // Retrieve & use the formXObject that we previously generated for this image
        std::string formXObjectName = getResourcesDict()->AddFormXObjectMapping(formXObjectMap.at(imagePath));
        
        // Draw on the page's context
        context->q();
        context->cm(transformation[0],
                    transformation[1],
                    transformation[2],
                    transformation[3],
                    transformation[4],
                    transformation[5]);
        context->Do(formXObjectName);
        context->Q();
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

































