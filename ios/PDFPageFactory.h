#include <stdio.h>
#include <PDFWriter.h>
#include <PDFPage.h>
#include <PageContentContext.h>
#include <PDFModifiedPage.h>


typedef struct {
    NSNumber* a;
    NSNumber* b;
} NumberPair;

class PDFPageFactory {
private:
    
    PDFWriter*              pdfWriter;
    AbstractContentContext* context;
    PDFUsedFont*            font;
    
    PDFPageFactory  (PDFWriter*, AbstractContentContext*);
    
    void         applyActions       (NSDictionary* actions);
    PDFRectangle createPDFRectangle (NSDictionary* rectangleActions);
    void         drawText           (NSDictionary* textActions);
    void         drawRectangle      (NSDictionary* rectActions);
    void         drawImage          (NSDictionary* imageActions);
    
    static NumberPair getCoords        (NSDictionary* coordsMap);
    static NumberPair getDims          (NSDictionary* coordsMap);
    static NumberPair getNumberKeyPair (NSDictionary* map, NSString* key1, NSString* key2);
    static unsigned   hexIntFromString (NSString* hexStr);


    
public:
    static void createAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions);
    static void modifyAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions);

};
