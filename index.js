import { NativeModules } from 'react-native';

export class PDFDocument {
  document = {
    path: '',
    pages: [],
  };

  constructor(path) {
    this.document.path = path;
    return this;
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

  create = () => {
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
}

export default NativeModules.PDFLib;
