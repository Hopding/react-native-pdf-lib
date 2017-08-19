
package com.hopding.pdflib;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.support.v4.content.FileProvider;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.NoSuchKeyException;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableMap;
import com.hopding.pdflib.utils.PDFDocument;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDDocumentCatalog;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission;
import com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy;
import com.tom_roush.pdfbox.pdmodel.font.PDFont;
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font;
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory;
import com.tom_roush.pdfbox.pdmodel.graphics.image.LosslessFactory;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDAcroForm;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDCheckbox;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDComboBox;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDField;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDListBox;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDRadioButton;
import com.tom_roush.pdfbox.pdmodel.interactive.form.PDTextField;
import com.tom_roush.pdfbox.rendering.PDFRenderer;
import com.tom_roush.pdfbox.text.PDFTextStripper;
import com.tom_roush.pdfbox.util.PDFBoxResourceLoader;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.util.HashMap;

import static android.R.attr.key;
import static android.R.attr.progressBarStyleInverse;

public class PDFLibModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public PDFLibModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;

    PDFBoxResourceLoader.init(reactContext);
  }

  @Override
  public String getName() {
    return "PDFLib";
  }

  @ReactMethod
  public void createPDF(ReadableMap documentActions, Promise promise) {
    try {
      promise.resolve(PDFDocument.generate(documentActions));
    } catch (NoSuchKeyException e) {
      e.printStackTrace();
      promise.reject(e);
    } catch (IOException e) {
      e.printStackTrace();
      promise.reject(e);
    }
  }

  @ReactMethod
  public void test(String text, Promise promise) {
    File dir = new File(reactContext.getFilesDir().getPath() + "/pdfs");
    dir.mkdirs();

    String pdfPath = dir + "/test.pdf";

    PDDocument document = new PDDocument();
    PDPage page1 = new PDPage();
    PDPage page2 = new PDPage();
    document.addPage(page2);
    document.addPage(page1);

    PDPageContentStream contentStream1;
    PDPageContentStream contentStream2;
    try {
      contentStream1 = new PDPageContentStream(document, page1);
      contentStream1.addRect(5, 500, 100, 100);
      contentStream1.setNonStrokingColor(0, 255, 125);
      contentStream1.fill();
      contentStream1.close();

      PDFont font = PDType1Font.HELVETICA;
      contentStream2 = new PDPageContentStream(document, page2);
      contentStream2.beginText();
      contentStream2.setNonStrokingColor(15, 38, 192);
      contentStream2.setFont(font, 12);
      contentStream2.newLineAtOffset(100, 700);
      contentStream2.showText(text);
      contentStream2.endText();
      contentStream2.close();

      document.save(pdfPath);
      document.close();

      promise.resolve(pdfPath);
    } catch (IOException e) {
      e.printStackTrace();
      promise.reject(e);
    }
  }

  @ReactMethod
  public void launchPDFViewer(String pdfFile, Promise promise) {
    Uri fileUri = FileProvider.getUriForFile(
            reactContext,
            reactContext.getPackageName() + ".fileprovider",
            new File(pdfFile)
    );

    Log.i("PDFLibModule", "Opening: " + fileUri);

    Intent intent = new Intent(Intent.ACTION_VIEW);
    intent.setDataAndType(fileUri, "application/pdf");
    intent.setFlags(
            Intent.FLAG_ACTIVITY_NO_HISTORY |
                    Intent.FLAG_GRANT_READ_URI_PERMISSION |
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION |
                    Intent.FLAG_ACTIVITY_NEW_TASK
    );
    try {
      reactContext.startActivity(intent);
      promise.resolve(null);
    } catch (ActivityNotFoundException e) {
      promise.reject("No application available to view PDF!");
    }
  }

  @ReactMethod
  public void getPDFsDir(Promise promise) {
    File dir = new File(reactContext.getFilesDir().getPath() + "/pdfs");
    dir.mkdirs();
    promise.resolve(dir.toString());
  }
}