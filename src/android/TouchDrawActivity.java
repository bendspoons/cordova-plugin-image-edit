package com.bendspoons.plugin.imageedit;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Point;
import android.graphics.Typeface;
import android.os.Build;
import android.os.Bundle;
import android.view.Display;
import android.view.HapticFeedbackConstants;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.util.Base64;
import android.widget.RelativeLayout;
import android.widget.Spinner;
import android.widget.TextView;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.util.DisplayMetrics;
import android.graphics.drawable.GradientDrawable;
import android.graphics.ColorMatrixColorFilter;

import org.apache.cordova.LOG;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.concurrent.atomic.AtomicInteger;

public class TouchDrawActivity extends Activity {

    public static final String DRAWING_RESULT_ERROR = "drawing_error";
    public static final int RESULT_TOUCHDRAW_ERROR = Activity.RESULT_FIRST_USER;

    private Paint mPaint;
    private int mScale = 75;
    private int a, r, g, b; //Decoded ARGB color values for the background and erasing

    private Bitmap mBitmap;
    private Bitmap mBitmapOriginal;
    private Integer EDIT_STEPS = 0;
    private TouchDrawView mTdView;
    private String imageDataSource = "";
    private String imageDataType = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        LOG.e("TouchDrawActivity", "onCreate()");

        super.onCreate(savedInstanceState);
        Bundle intentExtras = getIntent().getExtras();

        if (intentExtras != null) {
            LOG.e("intentExtras", intentExtras.toString());
            imageDataSource = intentExtras.getString("dataSource", imageDataSource);
            LOG.e("imageDataSource", imageDataSource);
            imageDataType = intentExtras.getString("dataType", imageDataType);
            LOG.e("imageDataType", imageDataType);
        }

        RelativeLayout tDLayout = new RelativeLayout(this);
        tDLayout.setHapticFeedbackEnabled(true);
        tDLayout.setLayoutParams(new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT));

        LinearLayout buttonBar = createButtonBar();
        buttonBar.setId(getNextViewId());
        RelativeLayout.LayoutParams buttonBarLayoutParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        buttonBarLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        buttonBar.setLayoutParams(buttonBarLayoutParams);
        tDLayout.addView(buttonBar);

        LinearLayout toolBar = createToolBar();
        toolBar.setId(getNextViewId());
        RelativeLayout.LayoutParams toolBarLayoutParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
        toolBarLayoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        toolBar.setLayoutParams(toolBarLayoutParams);
        tDLayout.addView(toolBar);

        FrameLayout tDContainer = new FrameLayout(this);
        RelativeLayout.LayoutParams tDViewLayoutParams = new RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
        tDViewLayoutParams.addRule(RelativeLayout.BELOW, buttonBar.getId());
        tDViewLayoutParams.addRule(RelativeLayout.ABOVE, toolBar.getId());
        tDContainer.setLayoutParams(tDViewLayoutParams);
        mTdView = new TouchDrawView(this);
        tDContainer.addView(mTdView);
        tDLayout.addView(tDContainer);

        this.requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(tDLayout);

        mPaint = new Paint();
        mPaint.setAntiAlias(true);
        mPaint.setDither(true);
    }

    public LinearLayout createButtonBar() {
        LinearLayout buttonBar = new LinearLayout(this);

        Button cancelButton = new Button(this);
        cancelButton.setText("Abbrechen");
        cancelButton.setTypeface(Typeface.SANS_SERIF);
        cancelButton.setBackgroundColor(Color.parseColor("#FA2000"));
        cancelButton.setTextColor(Color.parseColor("#FFFFFF"));
        cancelButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        cancelButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
                v.setPressed(true);

                onBackPressed();
            }
        });

        Button doneButton = new Button(this);
        doneButton.setText("Speichern");
        doneButton.setTypeface(Typeface.SANS_SERIF);
        doneButton.setBackgroundColor(Color.parseColor("#FA2000"));
        doneButton.setTextColor(Color.parseColor("#FFFFFF"));
        doneButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        doneButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                saveChanges();
            }
        });

        buttonBar.addView(cancelButton);
        buttonBar.addView(doneButton);

        return buttonBar;
    }

    public LinearLayout createToolBar() {
        LinearLayout toolBar = new LinearLayout(this);

        Button originalButton = new Button(this);
        originalButton.setText("ORG");
        originalButton.setTypeface(Typeface.SANS_SERIF);
        originalButton.setBackgroundColor(Color.parseColor("#FA2000"));
        originalButton.setTextColor(Color.parseColor("#FFFFFF"));
        originalButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        originalButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                resetToOriginal();
            }
        });

        Button greyscaleButton = new Button(this);
        greyscaleButton.setText("GREY");
        greyscaleButton.setTypeface(Typeface.SANS_SERIF);
        greyscaleButton.setBackgroundColor(Color.parseColor("#FA2000"));
        greyscaleButton.setTextColor(Color.parseColor("#FFFFFF"));
        greyscaleButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        greyscaleButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setGreyscaleFilter();
            }
        });

        Button blackWhiteButton = new Button(this);
        blackWhiteButton.setText("S/W");
        blackWhiteButton.setTypeface(Typeface.SANS_SERIF);
        blackWhiteButton.setBackgroundColor(Color.parseColor("#FA2000"));
        blackWhiteButton.setTextColor(Color.parseColor("#FFFFFF"));
        blackWhiteButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        blackWhiteButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setBlackWhiteFilter();
            }
        });

        Button sepiaButton = new Button(this);
        sepiaButton.setText("Sepia");
        sepiaButton.setTypeface(Typeface.SANS_SERIF);
        sepiaButton.setBackgroundColor(Color.parseColor("#FA2000"));
        sepiaButton.setTextColor(Color.parseColor("#FFFFFF"));
        sepiaButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        sepiaButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setSepiaFilter();
            }
        });

        toolBar.addView(originalButton);
        toolBar.addView(greyscaleButton);
        toolBar.addView(blackWhiteButton);
        toolBar.addView(sepiaButton);

        return toolBar;
    }

    public class TouchDrawView extends View {
        public Canvas mCanvas;
        private Path mPath;
        private Paint mBitmapPaint;

        @SuppressWarnings("deprecation")
        public TouchDrawView(Context context) {
            super(context);
            Display display = getWindowManager().getDefaultDisplay();
            int canvasWidth;
            int canvasHeight;

            LOG.e("TouchDrawView","RUNNING for imageDataType = " + imageDataType);

            try {
                LOG.e("TouchDrawView","IN TRY");
                LOG.e("TouchDrawView","EDIT_STEPS : " + EDIT_STEPS);
                if (imageDataType.equals("file")) {
                    LOG.e("TouchDrawView","TouchDrawActivity imageDataType file == " + imageDataType);
                    mBitmap = loadMutableBitmapFromFileURI(new URI(imageDataSource));

                    if (mBitmap == null) {
                        throw new IOException("Failed to read file: " + imageDataSource);
                    }

                    if(EDIT_STEPS == 0) {
                        mBitmapOriginal = mBitmap;
                    }

                    EDIT_STEPS++;
                } else if (imageDataType.equals("base64")) {
                    LOG.e("TouchDrawView","TouchDrawActivity imageDataType base64 == " + imageDataType);
                    mBitmap = loadMutableBitmapFromBase64DataUrl(imageDataSource);

                    if(EDIT_STEPS == 0) {
                        mBitmapOriginal = mBitmap;
                    }

                    EDIT_STEPS++;
                    //mBitmap = loadMutableBitmapFromFileURI(new URI(imageDataSource));
                } else {
                    LOG.e("TouchDrawView","TouchDrawActivity sourceType file OR base64");
                    return;
                }
            } catch (URISyntaxException e) {
                LOG.e("TouchDrawView","TouchDrawActivity imageDataSource ERR" + e.getMessage());
                e.printStackTrace();
                return;
            } catch (IOException e) {
                LOG.e("TouchDrawView","TouchDrawActivity imageDataSource ERR" + e.getMessage());
                e.printStackTrace();
                return;
            }

            mCanvas = new Canvas(mBitmap);
            mPath = new Path();
            mBitmapPaint = new Paint(Paint.DITHER_FLAG);
        }

        @Override
        protected void onSizeChanged(int w, int h, int oldw, int oldh) {
            super.onSizeChanged(w, h, oldw, oldh);

            float newWidth = w;
            float newHeight = h;

            float bitmapWidth = mBitmap.getWidth();
            float bitmapHeight = mBitmap.getHeight();

            if (w != bitmapWidth || h != bitmapHeight) {
                float xRatio = w / bitmapWidth;
                float yRatio = h / bitmapHeight;

                float dominatingRatio = Math.min(xRatio, yRatio);

                newWidth = dominatingRatio * bitmapWidth;
                newHeight = dominatingRatio * bitmapHeight;

            }

            mBitmap = Bitmap.createScaledBitmap(mBitmap, Math.round(newWidth),
                    Math.round(newHeight), false);

            mCanvas.setBitmap(mBitmap);
        }

        @Override
        protected void onDraw(Canvas canvas) {
            canvas.drawColor(Color.argb(a, r, g, b));
            canvas.drawBitmap(mBitmap, 0, 0, mBitmapPaint);
            canvas.drawPath(mPath, mPaint);
        }
    }

    public Bitmap scaleBitmap(Bitmap bitmap) {
        int origWidth = bitmap.getWidth();
        int origHeight = bitmap.getHeight();
        int newWidth, newHeight;

        if (mScale < 100) {
            newWidth = (int) (origWidth * (mScale / 100.0));
            newHeight = (int)(origHeight * (mScale / 100.0));
        } else {
            return bitmap;
        }

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true);
    }

    public void saveChanges() {
        ByteArrayOutputStream drawing = new ByteArrayOutputStream();
        scaleBitmap(mBitmap).compress(Bitmap.CompressFormat.PNG, 100, drawing);

        Intent drawingResult = new Intent();
        drawingResult.putExtra("drawing_result", drawing.toByteArray());
        setResult(Activity.RESULT_OK, drawingResult);
        finish();
    }

    @Override
    public void finish() {
        if (mBitmap != null) {
            mBitmap.recycle();
            mBitmap = null;
            System.gc();
        }

        super.finish();
    }

    private Bitmap loadMutableBitmapFromBase64DataUrl(String base64DataUrl) throws URISyntaxException {
        if (base64DataUrl == null || base64DataUrl.isEmpty() ||
                !base64DataUrl.matches("data:.*;base64,.*")) {
            throw new URISyntaxException(base64DataUrl, "invalid data url");
        }

        String base64 = base64DataUrl.split("base64,")[1];
        byte[] imgData = Base64.decode(base64, Base64.DEFAULT);

        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inMutable = true;
        opts.inPreferredConfig = Bitmap.Config.ARGB_8888;
        return BitmapFactory.decodeByteArray(imgData, 0, imgData.length, opts);
    }

    private Bitmap loadMutableBitmapFromFileURI(URI uri) throws FileNotFoundException, URISyntaxException {
        if (!uri.getScheme().equals("file")) {
            throw new URISyntaxException("uri", "invalid scheme");
        }

        if (uri.getQuery() != null) {
            // Ignore query parameters in the uri
            uri = new URI(uri.toString().split("\\?")[0]);
        }
        File file = new File(uri);

        if (!file.exists()) {
            throw new FileNotFoundException("File not found: " + file.getAbsolutePath());
        } else {
            LOG.e("Wurstebrot", "file exists - " + uri.toString());
        }

        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inMutable = true;
        opts.inPreferredConfig = Bitmap.Config.ARGB_8888;
        return BitmapFactory.decodeFile(file.getAbsolutePath(), opts);
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
    }

    public void resetToOriginal() {
        LOG.e("ACTION", "resetToOriginal");

        mBitmap = Bitmap.createScaledBitmap(mBitmapOriginal, mTdView.mCanvas.getWidth(),
                mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();
    }

    public void setGreyscaleFilter() {
        LOG.e("ACTION", "setGreyscale");

        Bitmap bmGrayScale = getGrayscaleFilter(mBitmap);

        mBitmap = Bitmap.createScaledBitmap(bmGrayScale, mTdView.mCanvas.getWidth(),
                mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);

        mTdView.invalidate();
    }

    private Bitmap getGrayscaleFilter(Bitmap src){

        //Custom color matrix to convert to GrayScale
        /*

        float[] matrix = new float[]{
                0.3f, 0.59f, 0.11f, 0, 0,
                0.3f, 0.59f, 0.11f, 0, 0,
                0.3f, 0.59f, 0.11f, 0, 0,
                0, 0, 0, 1, 0,};
        */

        float[] matrix = new float[]{
                0.33f, 0.33f, 0.33f, 0, 0,
                0.33f, 0.33f, 0.33f, 0, 0,
                0.33f, 0.33f, 0.33f, 0, 0,
                0, 0, 0, 1, 0};

        Bitmap dest = Bitmap.createBitmap(
                src.getWidth(),
                src.getHeight(),
                src.getConfig());

        Canvas canvas = new Canvas(dest);
        Paint paint = new Paint();
        ColorMatrixColorFilter filter = new ColorMatrixColorFilter(matrix);
        paint.setColorFilter(filter);
        canvas.drawBitmap(src, 0, 0, paint);

        return dest;
    }

    public void setBlackWhiteFilter() {
        LOG.e("ACTION", "setBlackWhite");

        Bitmap bmGrayScale = getGrayscaleFilter(mBitmap);
        Bitmap bmBWScale = getBlackWhiteFilter(bmGrayScale);

        mBitmap = Bitmap.createScaledBitmap(bmBWScale, mTdView.mCanvas.getWidth(),
                mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();
    }

    private Bitmap getBlackWhiteFilter(Bitmap src){

        //Custom color matrix to convert to GrayScale
        /*
        float[] matrix = new float[]{
                -1f, 0f, 0f, 0f, 255f,  // red
                0f, -1f, 0f, 0f, 255f,  // green
                0f, 0f, -1f, 0f, 255f,  // blue
                0f, 0f, 0f, 1f, 0f     // alpha
        };
        */

        float[] matrix = new float[]{
        85, 85, 85, 0, -128*255,
                85, 85, 85, 0, -128*255,
                85, 85, 85, 0, -128*255,
                0, 0, 0, 1, 0};

        Bitmap dest = Bitmap.createBitmap(
                src.getWidth(),
                src.getHeight(),
                src.getConfig());

        Canvas canvas = new Canvas(dest);
        Paint paint = new Paint();
        ColorMatrixColorFilter filter = new ColorMatrixColorFilter(matrix);
        paint.setColorFilter(filter);
        canvas.drawBitmap(src, 0, 0, paint);

        return dest;
    }

    public void setSepiaFilter() {
        LOG.e("ACTION", "setSepia");

        //Bitmap bmGrayScale = getGrayscaleFilter(mBitmap);
        Bitmap bmSePScale = getSepiaFilter(mBitmap);

        mBitmap = Bitmap.createScaledBitmap(bmSePScale, mTdView.mCanvas.getWidth(),
                mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();
    }

    private Bitmap getSepiaFilter(Bitmap src){

        //Custom color matrix to convert to GrayScale
        float[] matrix = new float[]{
                1f, 0f, 0f, 0f, 0f,  // red
                0f, 1f, 0f, 0f, 0f,  // green
                0f, 0f, 0.85f, 0f, 0f,  // blue
                0f, 0f, 0f, 1f, 0f     // alpha
        };

        Bitmap dest = Bitmap.createBitmap(
                src.getWidth(),
                src.getHeight(),
                src.getConfig());

        Canvas canvas = new Canvas(dest);
        Paint paint = new Paint();
        ColorMatrixColorFilter filter = new ColorMatrixColorFilter(matrix);
        paint.setColorFilter(filter);
        canvas.drawBitmap(src, 0, 0, paint);

        return dest;
    }

    private int getNextViewId() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            return View.generateViewId(); // Added in API level 17
        }

        // Re-implement View.generateViewId()for API levels < 17
        // http://stackoverflow.com/a/15442898
        for (;;) {
            final int result = sNextGeneratedId.get();
            // aapt-generated IDs have the high byte nonzero; clamp to the range under that.
            int newValue = result + 1;
            if (newValue > 0x00FFFFFF) newValue = 1; // Roll over to 1, not 0.
            if (sNextGeneratedId.compareAndSet(result, newValue)) {
                return result;
            }
        }
    }
    private static final AtomicInteger sNextGeneratedId = new AtomicInteger(1);

    public static int getScreenWidth(Context context) {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        ((Activity)context).getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
        return displayMetrics.widthPixels;
    }
}
