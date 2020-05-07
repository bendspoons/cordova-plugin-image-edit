package com.bendspoons.plugin.imageedit;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Base64;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.UUID;

import com.bendspoons.plugin.imageedit.ImageEditActivity;

/**
 * Created by jt on 29/03/16.
 */
public class ImageEdit extends CordovaPlugin {
    private static final String TAG = "ImageEdit";

    private String sourceData;
    private String sourceType;

    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        if (!action.equals("edit")) {
            callbackContext.sendPluginResult(
                    new PluginResult(Status.INVALID_ACTION, "Unsupported action: " + action));
            return false;
        }

        try {
            this.sourceData = args.getString(0);
            LOG.e(TAG, "this.sourceData = " + this.sourceData);

            this.sourceType = args.getString(1);
            LOG.e(TAG, "this.sourceType = " + this.sourceType);

            if (this.cordova != null) {
                LOG.e(TAG, "doEdit()");
                doEdit();
            }

            this.callbackContext = callbackContext;
            return true;
        } catch (JSONException e) {
            callbackContext.sendPluginResult(new PluginResult(Status.JSON_EXCEPTION, e.getMessage()));
            return false;
        }
    }

    private void doEdit() {
        this.cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                final Intent touchDrawIntent = new Intent(ImageEdit.this.cordova.getActivity(), ImageEditActivity.class);

                LOG.e(TAG, "ImageEdit.this.sourceData = " + ImageEdit.this.sourceData);
                LOG.e(TAG, "ImageEdit.this.sourceType = " + ImageEdit.this.sourceType);
                //touchDrawIntent.putExtra("dataSource", ImageEdit.this.sourceData);
                //touchDrawIntent.putExtra("dataType", ImageEdit.this.sourceType);

                if (ImageEdit.this.sourceType.equals("base64")) {
                    LOG.e("doEdit", "base64");
                    touchDrawIntent.putExtra("dataType", ImageEdit.this.sourceType);
                    touchDrawIntent.putExtra("dataSource", ImageEdit.this.sourceData);
                } else if (ImageEdit.this.sourceType.equals("file")) {
                    LOG.e("doEdit", "file");
                    Uri inputUri = Uri.parse(ImageEdit.this.sourceData);
                    String scheme = (inputUri != null && inputUri.getScheme() != null) ? inputUri.getScheme() : "";
                    LOG.e("doEdit", "scheme " + scheme);

                    if (scheme.equals(ContentResolver.SCHEME_CONTENT)) {
                        // Workaround for CB-9548 (https://issues.apache.org/jira/browse/CB-9548)
                        //  The Cordova camera plugin can sometimes return a content URI instead of a file URI
                        //  when the image is selected from the photo gallery.
                        //
                        //  However, the ImageEditActivity can only accept a file URI or a data URI for the
                        //  background image. So, we need to read the background image data and pass it in a
                        //  format which can be handled by the ImageEditActivity.

                        InputStream inStream = null;
                        try {
                            // Write background image to a temporary file and pass it as a file URL because
                            // there is no reliable way to get a file path from a content URI
                            // (http://stackoverflow.com/a/19985374)
                            ContentResolver contentResolver = ImageEdit.this.cordova.getActivity().getContentResolver();
                            inStream = contentResolver.openInputStream(inputUri);

                            if (inStream != null) {
                                File file = new File(ImageEdit.this.cordova.getActivity().getCacheDir(), UUID.randomUUID().toString());
                                FileOutputStream outStream = new FileOutputStream(file);
                                byte[] data = new byte[1024];
                                int bytesRead;

                                while ((bytesRead = inStream.read(data, 0, data.length)) != -1) {
                                    outStream.write(data, 0, bytesRead);
                                }
                                outStream.flush();
                                outStream.close();

                                touchDrawIntent.putExtra("dataType", "file");
                                touchDrawIntent.putExtra("dataSource", "file://" + file.getAbsolutePath());
                                LOG.e("doEdit", "dataSource SCHEME_CONTENT " + "file://" + file.getAbsolutePath());
                            }
                        } catch (IOException e) {
                            String message = "Failed to read image data from " + inputUri;
                            LOG.e(TAG, message);
                            e.printStackTrace();

                            ImageEdit.this.callbackContext.error(message + ": " + e.getLocalizedMessage());
                            return;
                        } finally {
                            if (inStream != null) {
                                try {
                                    inStream.close();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            }
                        }

                    } else if (scheme.equals(ContentResolver.SCHEME_FILE)) {
                        touchDrawIntent.putExtra("dataType", "file");
                        touchDrawIntent.putExtra("dataSource", ImageEdit.this.sourceData);
                        LOG.e("doEdit", "dataSource SCHEME_FILE " + ImageEdit.this.sourceData);
                    } else {
                        LOG.e("doEdit", "dataSource ELSE " + ImageEdit.this.sourceData);
                        String message = "invalid scheme for inputData: " + ImageEdit.this.sourceData ;
                        File file = new File(ImageEdit.this.sourceData);

                        LOG.d(TAG, message);
                        if (file.exists() && !file.isDirectory()) {
                            touchDrawIntent.putExtra("dataType", "file");
                            touchDrawIntent.putExtra("dataSource else", "file://" + file.getAbsolutePath());
                        } else {
                            ImageEdit.this.callbackContext.error(message);
                            return;
                        }
                    }
                }






                ImageEdit.this.cordova.getActivity().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        LOG.e(TAG, "run()");
                        ImageEdit.this.cordova.startActivityForResult(ImageEdit.this, touchDrawIntent, 900);
                    }
                });
            }
        });
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, final Intent intent) {
        LOG.e("ActivityResult", ""+resultCode);

        if (resultCode == Activity.RESULT_CANCELED) {
            this.callbackContext.success("");
            return;
        }

        if (resultCode == Activity.RESULT_OK && this.cordova != null) {
            this.cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    saveDrawing(intent);
                }
            });
            return;
        }

        if (resultCode == ImageEditActivity.RESULT_TOUCHDRAW_ERROR) {
            Bundle extras = intent.getExtras();
            String errorMessage = "Failed to generate ImageEdit.";

            if (extras != null) {
                errorMessage += " " + extras.getString(ImageEditActivity.DRAWING_RESULT_ERROR);
            }

            this.callbackContext.error(errorMessage);
        }
    }

    private void saveDrawing(Intent intent) {
        Bundle extras = intent.getExtras();
        byte[] drawingData = null;
        String output = null;

        if (extras != null &&
                extras.containsKey("drawing_result")) {
            drawingData = extras.getByteArray("drawing_result");
        }

        if (drawingData == null || drawingData.length == 0) {
            LOG.e(TAG, "Failed to read sketch result from activity");
            this.callbackContext.error("Failed to read sketch result from activity");
            return;
        }

        try {
            String ext = "";

            ext = "jpeg";
            //ext = "png";


            String fileName = String.format("sketch-%s.%s", UUID.randomUUID(), ext);
            File filePath = new File(this.cordova.getActivity().getCacheDir(), fileName);

            FileOutputStream fos = new FileOutputStream(filePath);
            fos.write(drawingData);
            fos.close();

            // Add the drawing to photo gallery
            String appName = getApplicationLabelOrPackageName(this.cordova.getActivity());
            String mediaStoreUrl = MediaStore.Images.Media.insertImage(this.cordova.getActivity().getContentResolver(),
                    filePath.getAbsolutePath(), fileName,
                    (appName != null && !appName.isEmpty()) ? "Generated by " + appName : "");

            LOG.d(TAG, (mediaStoreUrl != null) ?
                    "Drawing saved to media store: " + mediaStoreUrl :
                    "Failed to save drawing to media store");

            // We need to return the file saved to the cache dir instead of the
            // file in the photo gallery because the Cordova file plugin cannot open content URIs
            output = "file://" + filePath.getAbsolutePath();
            LOG.d(TAG, "Drawing saved to: " + output);
        } catch(Exception e) {
            LOG.e(TAG, "Error generating output from drawing: " + e.getMessage());

            this.callbackContext.error("Failed to generate output from drawing: "
                    + e.getMessage());
            return;
        }

        this.callbackContext.success(output);
    }

    // Based on http://stackoverflow.com/a/16444178
    private String getApplicationLabelOrPackageName(Context context) {
        PackageManager pm = context.getPackageManager();
        ApplicationInfo appInfo = context.getApplicationInfo();

        if (pm == null || appInfo == null) {
            return "";
        }

        try {
            String label = (String) pm.getApplicationLabel(pm.getApplicationInfo(appInfo.packageName, 0));
            if (label != null && !label.isEmpty()) {
                return label;
            }
        } catch (PackageManager.NameNotFoundException e) {
            LOG.w(TAG, "Failed to determine app label");
        }

        return appInfo.packageName;
    }
}
