/* @flow */
import PDFLib from './PDFLib';
import PDFPage from './PDFPage';

import type { PageAction } from './PDFPage';

export type DocumentAction = {
  path: string,
  pages: PageAction[],
  modifyPages?: PageAction[],
};

/**
 * Here is some docs...
 */
export default class PDFDocument {
  document: DocumentAction = {
    path: '',
    pages: [],
  };

  /**
   * Create a new PDFDocument that will be written at the specified path
   * @param {string} path - The absolute file path for this document to be
   *                        written to.
   */
  static create = (path: string) => {
    const pdfDocument = new PDFDocument();
    pdfDocument.setPath(path);
    return pdfDocument;
  }

  static modify = (path: string) => {
    const pdfDocument = new PDFDocument();
    pdfDocument.setPath(path);
    pdfDocument.document.modifyPages = [];
    return pdfDocument;
  }

  setPath = (path: string) => {
    this.document.path = path;
    return this;
  }

  modifyPage = ({ page }: PDFPage) => {
    if (page.pageIndex === undefined) {
      throw new Error(
        'Pages created with Page.create() must be added to document with ' +
        'PDFDocument.addPage(), instead of PDFDocument.modifyPage()'
      );
    }
    if (this.document.modifyPages === undefined) {
      throw new Error(
        'Cannot modify pages on PDFDocument initialized with PDFDocument.create(),' +
        ' please use PDFDocument.modify()'
      )
    }
    this.document.modifyPages.push(page);
    return this;
  }

  modifyPages = (...pages: PDFPage[]) => {
    pages.forEach(page => {
      this.modifyPage(page);
    })
    return this;
  }

  addPage = ({ page }: PDFPage) => {
    if (page.pageIndex !== undefined) {
      throw new Error(
        'Pages created with Page.modify() must be added to document with ' +
        'PDFDocument.modifyPage(), instead of PDFDocument.addPage()'
      );
    }
    this.document.pages.push(page);
    return this;
  };

  addPages = (...pages: PDFPage[]) => {
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
