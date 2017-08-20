
# react-native-pdf-lib

## Getting started

`$ npm install react-native-pdf-lib --save`

### Mostly automatic installation

1. `$ react-native link react-native-pdf-lib`
2. For Android, add the following to your app's `build.gradle` file:
    ```
    android {
      ...
      dexOptions {
          jumboMode = true
      }
      ...
    }
    ```

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-pdf-lib` and add `RNPdfLib.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNPdfLib.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.PdfLibPackage;` to the imports at the top of the file
  - Add `new PdfLibPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-pdf-lib'
  	project(':react-native-pdf-lib').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-pdf-lib/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-pdf-lib')
  	```
4. For Android, add the following to your app's `build.gradle` file:
    ```
    android {
      ...
      // Add this section:
      dexOptions {
          jumboMode = true
      }
      ...
    }
    ```

## Usage
### Warning:
The API is currently in development, and all aspects of it are subject to breaking changes in future releases.

```javascript
// Import from 'react-native-pdf-lib'
import PDFLib, { PDFDocument, PDFPage } from 'react-native-pdf-lib';

// Create a PDF page with text and rectangles
const page1 = PDFPage
  .create()
  .setMediaBox(200, 200)
  .addText('You can add text and rectangles to the PDF!', {
    color: '#007386',
    position: { x: 5, y: 235 },
  })
  .addRectangle(25, 25, 150, 150, { color: '#FF99CC' })
  .addRectangle(50, 50, 100, 100, { color: '#33CCFF' })
  .addRectangle(75, 75, 50, 50, { color: '#99FFCC' });

// Create a PDF page with text and an image
const jpgPath = // Path to a JPG image on the file system...
const page2 = PDFPage
  .create()
  .setMediaBox(250, 250)
  .addText('You can add JPG images too!')
  .addImage(jpgPath, 'jpg', {
     x: 5,
     y: 125,
     width: 200,
     height: 100,
  });

// Create a new PDF in your app's private Documents directory
const docsDir = await PDFLib.getDocumentsDir();
const pdfPath = `${docsDir}/sample.pdf`;
PDFDocument
  .create(path)
  .addPages(page1, page2)
  .write() // Returns a promise that resolves with the PDF's path
  .then(path => {
    console.log('PDF created at: ' + path);
    // Do stuff with your shiny new PDF!
  });
```
