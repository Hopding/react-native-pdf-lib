// Note: this is Android only, as iPhones do not have SDCard support
import {PDFDocument, PDFPage} from '@shogobg/react-native-pdf';

const createPDF = async () => {
  // Set our PDF file destination path to a folder on the SD Card
  const pdfPath = '/mnt/sdcard/DCIM/Camera/sample.pdf';
  console.log('Write PDF file to path: ', pdfPath);

  // Create some PDF pages
  const page1 = PDFPage.create().
  drawText("Oh, Hi there!", {x: 100, y: 100})

  const page2 = PDFPage.create().
  drawText("This is the second page of the PDF file!", {x: 100, y: 100})

  // Now put everything together, to save our PDF
  await PDFDocument
    .create(pdfPath)
    .addPages(page1, page2)
    .write() // Returns a promise that resolves with the PDF's path
    .then((path) => {
      console.log(`PDF created at: ${path}`);
    });
}

createPDF();