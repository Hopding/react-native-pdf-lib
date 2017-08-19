package com.hopding.pdflib.utils;

import android.support.annotation.RequiresPermission;
import android.util.Log;

import com.facebook.react.bridge.NoSuchKeyException;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.tom_roush.pdfbox.pdmodel.PDDocument;
import com.tom_roush.pdfbox.pdmodel.PDPage;
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream;
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle;
import com.tom_roush.pdfbox.pdmodel.font.PDFont;
import com.tom_roush.pdfbox.pdmodel.font.PDType1CFont;
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font;
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDColor;

import java.io.File;
import java.io.IOException;

public class PDFDocument {

    public static String generate(ReadableMap documentActions) throws NoSuchKeyException, IOException {
        String path = documentActions.getString("path");
        Log.i("PDFLibModule", "Generating PDF at path: " + path);

        PDDocument document = new PDDocument();

        ReadableArray pages = documentActions.getArray("pages");
        for(int i = 0; i < pages.size(); i++) {
            addPage(document, pages.getMap(i));
        }

        document.save(path);
        document.close();
        return path;
    }

    private static PDRectangle createPDRectangle(ReadableMap rectangleActions) {
        int x = rectangleActions.getInt("x");
        int y = rectangleActions.getInt("y");
        int width = rectangleActions.getInt("width");
        int height = rectangleActions.getInt("height");
        return new PDRectangle(x, y, width, height);
    }

    private static void addPage(PDDocument document, ReadableMap pageActions) throws NoSuchKeyException, IOException {
        PDPage page = new PDPage();
        document.addPage(page);

        PDRectangle mediaBox = createPDRectangle(pageActions.getMap("mediaBox"));
        page.setMediaBox(mediaBox);

        PDPageContentStream stream = new PDPageContentStream(document, page);
        ReadableArray actions = pageActions.getArray("actions");

        // Apply actions to the page
        for(int i = 0; i < actions.size(); i++) {
            ReadableMap action = actions.getMap(i);
            if (action.getString("type").equals("text")) {
                addText(stream, action);
            }
        }

        stream.close();
    }

    private static void addText(PDPageContentStream stream, ReadableMap textActions) throws NoSuchKeyException, IOException {
        String value = textActions.getString("value");
        int fontSize = textActions.getInt("fontSize");

        int xCoord = textActions.getMap("position").getInt("x");
        int yCoord = textActions.getMap("position").getInt("y");

        // We get a color as a hex string, e.g. "#F0F0F0" - so parse into RGB vals
        String colorStr = textActions.getString("color");
        int colorR = Integer.valueOf( colorStr.substring( 1, 3 ), 16 );
        int colorG = Integer.valueOf( colorStr.substring( 3, 5 ), 16 );
        int colorB = Integer.valueOf( colorStr.substring( 5, 7 ), 16 );

        stream.beginText();
        stream.setNonStrokingColor(colorR, colorG, colorB);
        stream.setFont(PDType1Font.TIMES_ROMAN, fontSize);
        stream.newLineAtOffset(xCoord, yCoord);
        stream.showText(value);
        stream.endText();
    }

}
