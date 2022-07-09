type TextAction = {
  type: "text";
  x: number;
  y: number;
  color: string;
  fontSize: number;
  value: string;
};

type RectangleAction = {
  type: "rectangle";
  x: number;
  y: number;
  width: number;
  height: number;
  color: string;
};

type ImageAction = {
  type: "image";
  imagePath: string;
  imageType: string;
  imageSource: string;
  x: number;
  y: number;
  width?: number;
  height?: number;
};

type PageActions = TextAction | RectangleAction | ImageAction;

type PageAction = {
  pageIndex?: number;
  mediaBox?: {
      x: number;
      y: number;
      width: number;
      height: number;
  };
  actions: PageActions[];
};

export class PDFPage {
  static create: () => PDFPage;
  static modify: (pageIndex: any) => PDFPage;
  page: PageAction;
  setMediaBox: (width: number, height: number, options?: {
      x?: number;
      y?: number;
  }) => PDFPage;
  drawText: (value: string, options?: {
      x?: number;
      y?: number;
      color?: string;
      fontSize?: number;
      fieldSize?: number;
      textAlign?: 'left' | 'right' | 'center';
      fontName?: string;
  }) => PDFPage;
  drawRectangle: (options?: {
      x?: number;
      y?: number;
      width?: number;
      height?: number;
      color?: string;
  }) => PDFPage;
  drawImage: (imagePath: string, imageType: string, options?: {
      x?: number;
      y?: number;
      width?: number;
      height?: number;
      imageSource?: string;
  }) => PDFPage;
}

export default {};