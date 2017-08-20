jest.mock('react-native', () => ({
  NativeModules: {
    PDFLib: 'mock value for PDFLib',
  },
}));
