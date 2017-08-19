import { NativeModules } from 'react-native';

export class PDFDocument {
  document = {
    path: '',
    pages: [],
  };

  static create = (path) => {
    const pdfDocument = new PDFDocument();
    pdfDocument.setPath(path);
    return pdfDocument;
  }

  setPath = (path) => {
    this.document.path = path;
    return this;
  }

  addPage = ({ page }) => {
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
    console.log('Creating this PDFDocument:');
    console.log(this.document);
    if (!this.document.path) {
      return Promise.reject('PDFDocument must have a path specified!');
    }
    if (this.document.pages.length < 1) {
      return Promise.reject('PDFDocument must have at least one page!');
    }
    return NativeModules.PDFLib.createPDF(this.document);
  }
}

export class PDFPage {
  page = {
    mediaBox: { x: 0, y: 0, width: 250, height: 250 },
    actions: [],
  };

  static create = () => {
    return new PDFPage();
  }

  setMediaBox = (width, height, options={}) => {
    this.page.mediaBox = {
      x: 0,
      y: 0,
      ...options,
      width,
      height,
    };
    return this;
  }

  addText = (value, options={}) => {
    const textAction = {
      color: '#000000',
      fontSize: 12,
      position: { x: 5, y: this.page.mediaBox.height - 10 },
      ...options,
      type: 'text',
      value,
    };
    this.page.actions.push(textAction);
    return this;
  }

  addRectangle = (x, y, width, height, options={}) => {
    const rectAction = {
      color: '#000000',
      ...options,
      type: 'rectangle',
      x,
      y,
      width,
      height,
    };
    this.page.actions.push(rectAction);
    return this;
  }
}

export default NativeModules.PDFLib;
