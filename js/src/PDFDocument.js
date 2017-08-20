/* @flow */
import PDFLib from './PDFLib';

export default class PDFDocument {
  document = {
    path: '',
    pages: [],
  };

  static create = (path) => {
    const pdfDocument = new PDFDocument();
    pdfDocument.setPath(path);
    return pdfDocument;
  }

  static modify = (path) => {
    const pdfDocument = new PDFDocument();
    pdfDocument.setPath(path);
    pdfDocument.document.modifyPages = [];
    return pdfDocument;
  }

  setPath = (path) => {
    this.document.path = path;
    return this;
  }

  modifyPage = ({ page }) => {
    if (page.pageIndex === undefined) {
      throw new Error(
        'Pages created with Page.create() must be added to document with ' +
        'PDFDocument.addPage(), instead of PDFDocument.modifyPage()'
      );
    }
    this.document.modifyPages.push(page);
    return this;
  }

  modifyPages = (...pages) => {
    pages.forEach(page => {
      this.modifyPage(page);
    })
  }

  addPage = ({ page }) => {
    if (page.pageIndex !== undefined) {
      throw new Error(
        'Pages created with Page.modify() must be added to document with ' +
        'PDFDocument.modifyPage(), instead of PDFDocument.addPage()'
      );
    }
    this.document.pages.push(page);
    return this;
  };

  addPages = (...pages) => {
    pages.forEach(page => {
      this.addPage(page);
    });
    return this;
  }

  write = () => {
    // console.log('Creating this PDFDocument:');
    // console.log(this.document);
    if (!this.document.path) {
      return Promise.reject('PDFDocument must have a path specified!');
    }
    if (this.document.modifyPages !== undefined) {
      return PDFLib.modifyPDF(this.document);
    }
    if (this.document.pages.length < 1) {
      return Promise.reject('PDFDocument must have at least one page!');
    }
    return PDFLib.createPDF(this.document);
  }
}
