
package com.hopding.pdflib;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class PDFLibModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;

  public PDFLibModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "PDFLib";
  }

  @ReactMethod
  public void testGetStrProm(Promise promise) {
    promise.resolve("This is a string from Java!");
  }
}