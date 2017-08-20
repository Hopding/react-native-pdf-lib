/* @flow */
import * as index from '../../index';

jest.mock('react-native');

describe('index.js', () => {
  it('exports the right stuff', () => {
    const indexKeys = Object.keys(index);
    expect(indexKeys.length).toEqual(3);
    expect(indexKeys).toContain('default');
    expect(indexKeys).toContain('PDFPage');
    expect(indexKeys).toContain('PDFDocument');
    expect(index).toMatchSnapshot();
  });
});
