// Note: this is Android only
// We will require the package RNFS to easily work with file-system operations
import RNFS from 'react-native-fs';
import {PDFDocument, PDFPage} from '@shogobg/react-native-pdf';

const createPDF = async () => {
  // Get a writable path, where we can copy the asset file for editing
  const filePath = `${RNFS.TemporaryDirectoryPath}/Temp.pdf`;
  // Next line will search for a file named 'Template.pdf' in your application's assets directory
  //      and copy it to our temporary directory
  // If you need to look into a subfolter, just add it to the path like usual 'SubFolder/Template.pdf'
  await RNFS.copyFileAssets('Template.pdf', filePath);

  // Set our PDF file destination path to someplace where we can access it later
  const pdfPath = '/mnt/sdcard/DCIM/Camera/sample.pdf';
  console.log('Write PDF file to path: ', pdfPath);

  // Update the first page
  const page1 = PDFPage.modify(0).
  drawText("Oh, Hi there!", {x: 100, y: 100})

  // Append one more page
  const page2 = PDFPage.create().
  drawText("This page will appear at the end of the PDF file!", {x: 100, y: 100})

  // Now put everything together, to save our PDF
  await PDFDocument
    .create(pdfPath)
    .modify(page1)
    .addPages(page2)
    .write() // Returns a promise that resolves with the PDF's path
    .then((path) => {
      console.log(`PDF created at: ${path}`);
    });
}

createPDF();