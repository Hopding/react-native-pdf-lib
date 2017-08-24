/* @flow */

export default class PDFPage {
  page = {
    actions: [],
  };

  static create = () => {
    const newPage = new PDFPage();
    newPage.page.mediaBox = { x: 0, y: 0, width: 250, height: 500 };
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

  drawText = (value, options={}) => {
    const textAction = {
      x: 0,
      y: 0,
      color: '#000000',
      fontSize: 12,
      ...options,
      type: 'text',
      value,
    };
    this.page.actions.push(textAction);
    return this;
  }

  drawRectangle = (options={}) => {
    const rectAction = {
      x: 0,
      y: 0,
      width: 50,
      height: 50,
      color: '#000000',
      ...options,
      type: 'rectangle',
    };
    this.page.actions.push(rectAction);
    return this;
  }

  drawImage = (imagePath, imageType, options={}) => {
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
