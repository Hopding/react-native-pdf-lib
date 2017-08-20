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
      return NativeModules.PDFLib.modifyPDF(this.document);
    }
    if (this.document.pages.length < 1) {
      return Promise.reject('PDFDocument must have at least one page!');
    }
    return NativeModules.PDFLib.createPDF(this.document);
  }
}

export class PDFPage {
  page = {
    actions: [],
  };

  static create = () => {
    const newPage = new PDFPage();
    newPage.page.mediaBox = { x: 0, y: 0, width: 250, height: 250 };
    return newPage;
  }

  static modify = (pageIndex) => {
    const newPage = new PDFPage();
    newPage.page.pageIndex = pageIndex;
    return newPage;
  }

  setMediaBox = (width, height, options={}) => {
    if (this.page.pageIndex !== undefined) {
      throw new Error('Cannot set media box on modified page!');
    }
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
    const y = this.page.mediaBox ? this.page.mediaBox.height - 10 : 0;
    const textAction = {
      color: '#000000',
      fontSize: 12,
      position: { x: 5, y, },
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

  addImage = (imagePath, imageType, options={}) => {
    // TODO: Add logic using ReactNative.Image to automatically preserve image
    // dimensions!
    if (imageType !== 'jpg') {
      throw new Error('Only JPG images are currently supported!');
    }
    const imageAction = {
      x: 0,
      y: 0,
      ...options,
      type: 'image',
      imagePath,
      imageType,
    };
    this.page.actions.push(imageAction);
    return this;
  }
}

export default NativeModules.PDFLib;
