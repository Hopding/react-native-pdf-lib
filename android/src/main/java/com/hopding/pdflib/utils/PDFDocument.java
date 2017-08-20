package com.hopding.pdflib.utils;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
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
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory;
import com.tom_roush.pdfbox.pdmodel.graphics.image.LosslessFactory;
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject;

import java.io.File;
import java.io.IOException;

public class PDFDocument {

    public static String generate(ReadableMap documentActions) throws NoSuchKeyException, IOException {
        String path = documentActions.getString("path");
        PDDocument document = new PDDocument();

        ReadableArray pages = documentActions.getArray("pages");
        for(int i = 0; i < pages.size(); i++) {
            addPage(document, pages.getMap(i));
        }

        document.save(path);
        document.close();
        return path;
    }

    public static String modify(ReadableMap documentActions) throws NoSuchKeyException, IOException {
        String path = documentActions.getString("path");
        PDDocument document = PDDocument.load(new File(path));

        ReadableArray modifyPages = documentActions.getArray("modifyPages");
        for(int i = 0; i < modifyPages.size(); i++) {
            modifyPage(document, modifyPages.getMap(i));
        }

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

    private static void modifyPage(PDDocument document, ReadableMap pageActions) throws NoSuchKeyException, IOException {
        int pageIndex = pageActions.getInt("pageIndex");
        PDPage page = document.getPage(pageIndex);

        if (pageActions.hasKey("mediaBox")) {
            PDRectangle mediaBox = createPDRectangle(pageActions.getMap("mediaBox"));
            page.setMediaBox(mediaBox);
        }

        PDPageContentStream stream = new PDPageContentStream(document, page, true, true, true);
        ReadableArray actions = pageActions.getArray("actions");

        // Apply actions to the page
        for(int i = 0; i < actions.size(); i++) {
            ReadableMap action = actions.getMap(i);
            String type = action.getString("type");
            if (type.equals("text")) {
                addText(stream, action);
            }
            else if (type.equals("rectangle")) {
                addRectangle(stream, action);
            }
            else if (type.equals("image")) {
                addImage(document, stream, action);
            }
        }

        stream.close();
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
            String type = action.getString("type");
            if (type.equals("text")) {
                addText(stream, action);
            }
            else if (type.equals("rectangle")) {
                addRectangle(stream, action);
            }
            else if (type.equals("image")) {
                addImage(document, stream, action);
            }
        }

        stream.close();
    }

    private static void addText(PDPageContentStream stream, ReadableMap textActions) throws NoSuchKeyException, IOException {
        String value = textActions.getString("value");
        int fontSize = textActions.getInt("fontSize");

        int xCoord = textActions.getMap("position").getInt("x");
        int yCoord = textActions.getMap("position").getInt("y");

        int[] rgbColor = hexStringToRGB(textActions.getString("color"));

        stream.beginText();
        stream.setNonStrokingColor(rgbColor[0], rgbColor[1], rgbColor[2]);
        stream.setFont(PDType1Font.TIMES_ROMAN, fontSize);
        stream.newLineAtOffset(xCoord, yCoord);
        stream.showText(value);
        stream.endText();
    }

    private static void addRectangle(PDPageContentStream stream, ReadableMap rectActions) throws NoSuchKeyException, IOException {
        int x = rectActions.getInt("x");
        int y = rectActions.getInt("y");
        int width = rectActions.getInt("width");
        int height = rectActions.getInt("height");

        int[] rgbColor = hexStringToRGB(rectActions.getString("color"));

        stream.addRect(x, y, width, height);
        stream.setNonStrokingColor(rgbColor[0], rgbColor[1], rgbColor[2]);
        stream.fill();
    }

    private static void addImage(PDDocument document, PDPageContentStream stream, ReadableMap imageActions) throws NoSuchKeyException, IOException {
        /*
            // Draw the falcon base image
			PDImageXObject ximage = JPEGFactory.createFromStream(document, in);
			contentStream.drawImage(ximage, 20, 20);

			// Draw the red overlay image
			Bitmap alphaImage = BitmapFactory.decodeStream(alpha);
			PDImageXObject alphaXimage = LosslessFactory.createFromImage(document, alphaImage);
			contentStream.drawImage(alphaXimage, 20, 20 );
         */
        String imageType = imageActions.getString("imageType");
        String imagePath = imageActions.getString("imagePath");
        int x = imageActions.getInt("x");
        int y = imageActions.getInt("y");
        Integer width = null;
        Integer height = null;
        if (imageActions.hasKey("width") && imageActions.hasKey("height")) {
            width = imageActions.getInt("width");
            height = imageActions.getInt("height");
        }

        if (imageType.equals("jpg")) {
            Bitmap bmpImage = BitmapFactory.decodeFile(imagePath);
            PDImageXObject image = JPEGFactory.createFromImage(document, bmpImage);
            if (width != null && height != null)
                stream.drawImage(image, x, y, width, height);
            else
                stream.drawImage(image, x, y);
        }
    }

    // We get a color as a hex string, e.g. "#F0F0F0" - so parse into RGB vals
    private static int[] hexStringToRGB(String hexString) {
        int colorR = Integer.valueOf( hexString.substring( 1, 3 ), 16 );
        int colorG = Integer.valueOf( hexString.substring( 3, 5 ), 16 );
        int colorB = Integer.valueOf( hexString.substring( 5, 7 ), 16 );
        return new int[] { colorR, colorG, colorB };
    }

}
