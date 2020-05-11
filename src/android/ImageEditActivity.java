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
import android.view.animation.Animation;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ImageView;
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
import android.graphics.drawable.Drawable;
import android.graphics.ColorMatrixColorFilter;
import android.graphics.Matrix;

import android.widget.SeekBar;

import org.apache.cordova.LOG;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.res.Resources;

import android.renderscript.Allocation;
import android.renderscript.Element;
import android.renderscript.RenderScript;
import android.renderscript.ScriptIntrinsicConvolve3x3;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Arrays;
import java.util.concurrent.atomic.AtomicInteger;

public class ImageEditActivity extends Activity {

    public static final String DRAWING_RESULT_ERROR = "drawing_error";
    public static final int RESULT_TOUCHDRAW_ERROR = Activity.RESULT_FIRST_USER;

    private Paint mPaint;
    private int mScale = 100;
    private int a, r, g, b; //Decoded ARGB color values for the background and erasing

    private Bitmap mBitmap;
    private Bitmap mBitmapOriginal;
    private Integer EDIT_STEPS = 0;
    private TouchDrawView mTdView;

    private Integer rotateDegrees = 0;
    private Boolean filterApplied = false;
    private Boolean filterSWApplied = false;
    private Boolean filterGSApplied = false;
    private Boolean filterSPApplied = false;
    private Boolean filterSHApplied = false;
    private Boolean croppingStarted = false;
    private Boolean croppingDrawed = false;

    private String imageDataSource = "";
    private String imageDataType = "";

    public Context mainContext;

    private SeekBar seekBar;

    private String buttonBackgroundColor = "#f5f6f6";
    private String buttonTextColor = "#007aff";
    private String buttonTextDangerColor = "#FA2000";
    private String buttonTextWarningColor = "#c8f629";
    private String buttonTextSuccessColor = "#5bc43e";

    float fromLeft;
    float fromTop;
    float fromLeftPlusWidth;
    float fromTopPlusHeight;

    float mX, mY;
    boolean touched = false;
    private static final float TOUCH_TOLERANCE = 4;


    private Button cancelButton;
    private Button doneButton;
    private Button somethingActiveButton;

    private Button filterButton;
    private Button filterResetButton;
    private Button filterBlackWhiteButton;
    private Button filterGreyscaleButton;
    private Button filterSepiaButton;
    private Button filterSharpnessButton;
    private Button filterAbortButton;

    private Button cropButton;
    private Button cropSaveButton;
    private Button cropAbortButton;

    private Button rotateButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        LOG.e("ImageEditActivity", "onCreate()");

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

        mainContext = this;
    }

    public LinearLayout createButtonBar() {
        LinearLayout buttonBar = new LinearLayout(this);

        Resources activityRes = this.getResources();

        cancelButton = new Button(this);
        cancelButton.setText("Abbrechen");
        cancelButton.setTypeface(Typeface.SANS_SERIF);
        cancelButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        int cancelButtonImgDrawable = activityRes.getIdentifier("ic_action_cancel", "drawable", this.getApplicationContext().getPackageName());
        Drawable cancelButtonImg = activityRes.getDrawable(cancelButtonImgDrawable);
        cancelButton.setCompoundDrawablesWithIntrinsicBounds( null, null, cancelButtonImg, null);

        cancelButton.setTextColor(Color.parseColor(buttonTextDangerColor));

        LinearLayout.LayoutParams cancelButtonLayoutParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30);
        cancelButtonLayoutParams.width = (int) (getScreenWidth(this) * 0.5);
        cancelButton.setLayoutParams(cancelButtonLayoutParams);

        cancelButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                onBackPressed();
            }
        });


        doneButton = new Button(this);
        doneButton.setText("Speichern");
        doneButton.setTypeface(Typeface.SANS_SERIF);
        doneButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        int doneButtonImgDrawable = activityRes.getIdentifier("ic_action_save", "drawable", this.getApplicationContext().getPackageName());
        Drawable doneButtonImg = activityRes.getDrawable(doneButtonImgDrawable);
        doneButton.setCompoundDrawablesWithIntrinsicBounds( doneButtonImg, null, null, null);

        doneButton.setTextColor(Color.parseColor(buttonTextSuccessColor));

        LinearLayout.LayoutParams doneButtonLayoutParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30);
        doneButtonLayoutParams.width = (int) (getScreenWidth(this) * 0.5);
        doneButton.setLayoutParams(doneButtonLayoutParams);

        doneButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                saveChanges();
            }
        });


        somethingActiveButton = new Button(this);
        somethingActiveButton.setText("xxx");
        somethingActiveButton.setTypeface(Typeface.SANS_SERIF);
        somethingActiveButton.setVisibility(View.GONE);
        somethingActiveButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        somethingActiveButton.setTextColor(Color.parseColor(buttonTextColor));

        LinearLayout.LayoutParams somethingActiveButtonLayoutParams = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30);
        //somethingActiveButtonLayoutParams.width = (int) (getScreenWidth(this) * 0.5);
        somethingActiveButton.setLayoutParams(somethingActiveButtonLayoutParams);

        buttonBar.addView(cancelButton);
        buttonBar.addView(doneButton);
        buttonBar.addView(somethingActiveButton);

        return buttonBar;
    }

    public LinearLayout createToolBar() {
        LinearLayout toolBar = new LinearLayout(this);

        Resources activityRes = this.getResources();

        /*
        Button originalButton = new Button(this);
        originalButton.setText("ORG");
        originalButton.setTypeface(Typeface.SANS_SERIF);
        originalButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        originalButton.setTextColor(Color.parseColor(buttonTextColor));
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
        greyscaleButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        greyscaleButton.setTextColor(Color.parseColor(buttonTextColor));
        greyscaleButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        greyscaleButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setGreyscaleFilter();
                setBlackWhiteFilter();
                setSepiaFilter();
            }
        });

        Button blackWhiteButton = new Button(this);
        blackWhiteButton.setText("S/W");
        blackWhiteButton.setTypeface(Typeface.SANS_SERIF);
        blackWhiteButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        blackWhiteButton.setTextColor(Color.parseColor(buttonTextColor));
        blackWhiteButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        blackWhiteButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setBlackWhiteFilter();
                setSepiaFilter();
            }
        });

        Button sepiaButton = new Button(this);
        sepiaButton.setText("Sepia");
        sepiaButton.setTypeface(Typeface.SANS_SERIF);
        sepiaButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        sepiaButton.setTextColor(Color.parseColor(buttonTextColor));
        sepiaButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        sepiaButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setSepiaFilter();
            }
        });

        Button rotateButton = new Button(this);
        Button rotateAbortButton = new Button(this);

        rotateAbortButton.setText("Fertig ");
        rotateAbortButton.setVisibility(View.GONE);
        rotateAbortButton.setTypeface(Typeface.SANS_SERIF);
        rotateAbortButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        rotateAbortButton.setTextColor(Color.parseColor(buttonTextColor));
        rotateAbortButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        rotateAbortButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                seekBar.setVisibility(View.GONE);
                rotateAbortButton.setVisibility(View.GONE);

                //originalButton.setVisibility(View.GONE);
                greyscaleButton.setVisibility(View.VISIBLE);
                blackWhiteButton.setVisibility(View.VISIBLE);
                sepiaButton.setVisibility(View.VISIBLE);
                rotateButton.setVisibility(View.VISIBLE);
            }
        });

        rotateButton.setText("Rotate");
        rotateButton.setTypeface(Typeface.SANS_SERIF);
        rotateButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        rotateButton.setTextColor(Color.parseColor(buttonTextColor));
        rotateButton.setLayoutParams(new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        rotateButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                seekBar.setVisibility(View.VISIBLE);
                rotateAbortButton.setVisibility(View.VISIBLE);

                //originalButton.setVisibility(View.GONE);
                greyscaleButton.setVisibility(View.GONE);
                blackWhiteButton.setVisibility(View.GONE);
                sepiaButton.setVisibility(View.GONE);
                rotateButton.setVisibility(View.GONE);
            }
        });

        toolBar.addView(originalButton);
        toolBar.addView(greyscaleButton);
        toolBar.addView(blackWhiteButton);
        toolBar.addView(sepiaButton);
        toolBar.addView(rotateButton);
        toolBar.addView(rotateSpinner());
        toolBar.addView(rotateAbortButton);
        */

        filterButton = new Button(this);

        filterResetButton = new Button(this);
        filterBlackWhiteButton = new Button(this);
        filterGreyscaleButton = new Button(this);
        filterSepiaButton = new Button(this);
        filterSharpnessButton = new Button(this);
        filterAbortButton = new Button(this);

        cropButton = new Button(this);

        cropSaveButton = new Button(this);
        cropAbortButton = new Button(this);

        rotateButton = new Button(this);

        /* Filter Button */
        filterButton.setText("Filter");
        filterButton.setTypeface(Typeface.SANS_SERIF);
        filterButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        filterButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_filter", "drawable", this.getApplicationContext().getPackageName())), null, null);

        filterButton.setTextColor(Color.parseColor(buttonTextColor));
        filterButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                filterButton.setVisibility(View.GONE);
                cropButton.setVisibility(View.GONE);
                rotateButton.setVisibility(View.GONE);

                cancelButton.setVisibility(View.GONE);
                doneButton.setVisibility(View.GONE);
                somethingActiveButton.setVisibility(View.VISIBLE);
                somethingActiveButton.setText("Filter auswählen");

                filterBlackWhiteButton.setVisibility(View.VISIBLE);
                filterGreyscaleButton.setVisibility(View.VISIBLE);
                filterSepiaButton.setVisibility(View.VISIBLE);
                filterSharpnessButton.setVisibility(View.VISIBLE);
                filterAbortButton.setVisibility(View.VISIBLE);

            }
        });

        /* Filter Reset Button */
        filterResetButton.setText("Reset");
        filterResetButton.setTypeface(Typeface.SANS_SERIF);
        filterResetButton.setVisibility(View.GONE);

        filterResetButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        filterResetButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_trash", "drawable", this.getApplicationContext().getPackageName())), null, null);

        filterResetButton.setTextColor(Color.parseColor(buttonTextDangerColor));
        filterResetButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterResetButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                resetToOriginal();
                setFilterApplied(false);
                filterResetButton.setVisibility(View.GONE);

                filterBlackWhiteButton.setTextColor(Color.parseColor(buttonTextColor));
                filterGreyscaleButton.setTextColor(Color.parseColor(buttonTextColor));
                filterSharpnessButton.setTextColor(Color.parseColor(buttonTextColor));
                filterSepiaButton.setTextColor(Color.parseColor(buttonTextColor));
            }
        });

        /* Filter Black White Button */
        filterBlackWhiteButton.setText("S/W");
        filterBlackWhiteButton.setVisibility(View.GONE);
        filterBlackWhiteButton.setTypeface(Typeface.SANS_SERIF);

        filterBlackWhiteButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        filterBlackWhiteButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_sw", "drawable", this.getApplicationContext().getPackageName())), null, null);

        filterBlackWhiteButton.setTextColor(Color.parseColor(buttonTextColor));
        filterBlackWhiteButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterBlackWhiteButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setBlackWhiteFilter();
                setFilterApplied(true);
                filterResetButton.setVisibility(View.VISIBLE);

                filterBlackWhiteButton.setTextColor(Color.parseColor(buttonTextSuccessColor));
            }
        });

        /* Filter Greyscale Button */
        filterGreyscaleButton.setText("Grau");
        filterGreyscaleButton.setVisibility(View.GONE);
        filterGreyscaleButton.setTypeface(Typeface.SANS_SERIF);

        filterGreyscaleButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        filterGreyscaleButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_greyscale", "drawable", this.getApplicationContext().getPackageName())), null, null);

        filterGreyscaleButton.setTextColor(Color.parseColor(buttonTextColor));
        filterGreyscaleButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterGreyscaleButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setGreyscaleFilter();
                setFilterApplied(true);
                filterResetButton.setVisibility(View.VISIBLE);

                filterGreyscaleButton.setTextColor(Color.parseColor(buttonTextSuccessColor));
            }
        });

        /* Filter Sepia Button */
        filterSepiaButton.setText("Sepia");
        filterSepiaButton.setVisibility(View.GONE);
        filterSepiaButton.setTypeface(Typeface.SANS_SERIF);
        filterSepiaButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));
        filterSepiaButton.setTextColor(Color.parseColor(buttonTextColor));
        filterSepiaButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterSepiaButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setSepiaFilter();
                setFilterApplied(true);
                filterResetButton.setVisibility(View.VISIBLE);

                filterSepiaButton.setTextColor(Color.parseColor(buttonTextSuccessColor));
            }
        });

        /* Filter Sharpness Button */
        filterSharpnessButton.setText("Schärfe");
        filterSharpnessButton.setVisibility(View.GONE);
        filterSharpnessButton.setTypeface(Typeface.SANS_SERIF);

        filterSharpnessButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        filterSharpnessButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_sharp", "drawable", this.getApplicationContext().getPackageName())), null, null);

        filterSharpnessButton.setTextColor(Color.parseColor(buttonTextColor));
        filterSharpnessButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterSharpnessButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                setSharpnessFilter();
                setFilterApplied(true);
                filterResetButton.setVisibility(View.VISIBLE);

                filterSharpnessButton.setTextColor(Color.parseColor(buttonTextSuccessColor));
            }
        });

        /* Filter Abort Button */
        filterAbortButton.setText("OK");
        filterAbortButton.setVisibility(View.GONE);
        filterAbortButton.setTypeface(Typeface.SANS_SERIF);
        filterAbortButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        filterAbortButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_tick", "drawable", this.getApplicationContext().getPackageName())), null, null);

        filterAbortButton.setTextColor(Color.parseColor(buttonTextSuccessColor));
        filterAbortButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        filterAbortButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                filterResetButton.setVisibility(View.GONE);
                filterBlackWhiteButton.setVisibility(View.GONE);
                filterGreyscaleButton.setVisibility(View.GONE);
                filterSepiaButton.setVisibility(View.GONE);
                filterSharpnessButton.setVisibility(View.GONE);
                filterAbortButton.setVisibility(View.GONE);

                cancelButton.setVisibility(View.VISIBLE);
                doneButton.setVisibility(View.VISIBLE);
                somethingActiveButton.setVisibility(View.GONE);

                filterButton.setVisibility(View.VISIBLE);
                cropButton.setVisibility(View.VISIBLE);
                rotateButton.setVisibility(View.VISIBLE);

            }
        });

        /* Zuschnitt Button */
        cropButton.setText("Zuschnitt");
        cropButton.setTypeface(Typeface.SANS_SERIF);
        cropButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        cropButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_crop", "drawable", this.getApplicationContext().getPackageName())), null, null);

        cropButton.setTextColor(Color.parseColor(buttonTextColor));

        cropButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        cropButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                filterButton.setVisibility(View.GONE);
                cropButton.setVisibility(View.GONE);
                rotateButton.setVisibility(View.GONE);

                //cropSaveButton.setVisibility(View.VISIBLE);
                cropAbortButton.setVisibility(View.VISIBLE);

                cancelButton.setVisibility(View.GONE);
                doneButton.setVisibility(View.GONE);
                somethingActiveButton.setVisibility(View.VISIBLE);
                somethingActiveButton.setText("Zuschneiden");

                croppingStarted = true;

            }
        });

        /* Zuschnitt Übernehmen Button */
        cropSaveButton.setText("übernehmen");
        cropSaveButton.setVisibility(View.GONE);
        cropSaveButton.setTypeface(Typeface.SANS_SERIF);
        cropSaveButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        cropSaveButton.setCompoundDrawablesWithIntrinsicBounds( activityRes.getDrawable(activityRes.getIdentifier("ic_action_save", "drawable", this.getApplicationContext().getPackageName())), null, null, null);

        cropSaveButton.setTextColor(Color.parseColor(buttonTextSuccessColor));

        cropSaveButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        cropSaveButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                filterButton.setVisibility(View.VISIBLE);
                cropButton.setVisibility(View.VISIBLE);
                rotateButton.setVisibility(View.VISIBLE);

                cropSaveButton.setVisibility(View.GONE);
                cropAbortButton.setVisibility(View.GONE);

                cancelButton.setVisibility(View.VISIBLE);
                doneButton.setVisibility(View.VISIBLE);
                somethingActiveButton.setVisibility(View.GONE);

                croppingStarted = false;
                croppingDrawed = false;

                executeCropping();
            }
        });

        /* Zuschnitt Abort Button */
        cropAbortButton.setText("abbrechen");
        cropAbortButton.setVisibility(View.GONE);
        cropAbortButton.setTypeface(Typeface.SANS_SERIF);
        cropAbortButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        cropAbortButton.setTextColor(Color.parseColor(buttonTextDangerColor));
        cropAbortButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        cropAbortButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                filterButton.setVisibility(View.VISIBLE);
                cropButton.setVisibility(View.VISIBLE);
                rotateButton.setVisibility(View.VISIBLE);

                cropSaveButton.setVisibility(View.GONE);
                cropAbortButton.setVisibility(View.GONE);

                cancelButton.setVisibility(View.VISIBLE);
                doneButton.setVisibility(View.VISIBLE);
                somethingActiveButton.setVisibility(View.GONE);

                croppingStarted = false;
                croppingDrawed = false;
            }
        });

        /* Drehen Button */
        rotateButton.setText("Drehen");
        rotateButton.setTypeface(Typeface.SANS_SERIF);
        rotateButton.setBackgroundColor(Color.parseColor(buttonBackgroundColor));

        rotateButton.setCompoundDrawablesWithIntrinsicBounds( null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_rotate", "drawable", this.getApplicationContext().getPackageName())), null, null);

        rotateButton.setTextColor(Color.parseColor(buttonTextColor));
        rotateButton.setLayoutParams(new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, (float) 0.30));
        rotateButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);

                if(rotateDegrees == 0) {
                    rotateDegrees = 90;
                } else if(rotateDegrees == 90) {
                    rotateDegrees = 180;
                } else if(rotateDegrees == 180) {
                    rotateDegrees = 270;
                } else if(rotateDegrees == 270) {
                    rotateDegrees = 0;
                }

                if(rotateDegrees > 0) {
                    rotateButton.setTextColor(Color.parseColor(buttonTextSuccessColor));
                    rotateButton.setText("Drehen " + rotateDegrees + "°");
                } else {
                    rotateButton.setTextColor(Color.parseColor(buttonTextColor));
                    rotateButton.setText("Drehen");
                }
                setRotateFilter(90);

            }
        });

        toolBar.addView(filterButton);
        toolBar.addView(cropButton);
        toolBar.addView(rotateButton);

        toolBar.addView(filterResetButton);
        toolBar.addView(filterBlackWhiteButton);
        toolBar.addView(filterGreyscaleButton);
        //toolBar.addView(filterSepiaButton);
        toolBar.addView(filterSharpnessButton);
        toolBar.addView(filterAbortButton);

        toolBar.addView(cropAbortButton);
        toolBar.addView(cropSaveButton);

        return toolBar;
    }

    public SeekBar rotateSpinner() {
        seekBar = new SeekBar(this);
        final String strokeColourLabelPrefix = "RT";

        LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        layoutParams.width = (int) (getScreenWidth(this) * 0.6);
        layoutParams.height = 160;
        seekBar.setLayoutParams(layoutParams);

        seekBar.setVisibility(View.GONE);
        seekBar.setMin(1);
        seekBar.setMax(360);
        seekBar.setMinimumHeight(160);

        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            int pval = 0;
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                pval = progress;
                LOG.e("seekBar", "Progress: " + pval);
            }
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                LOG.e("seekBar", "Start touch");
            }
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                LOG.e("seekBar", pval + "/" + seekBar.getMax());
                setRotateFilter(pval);
            }
        });

        return seekBar;
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
                    LOG.e("TouchDrawView","ImageEditActivity imageDataType file == " + imageDataType);
                    mBitmap = loadMutableBitmapFromFileURI(new URI(imageDataSource));

                    if (mBitmap == null) {
                        throw new IOException("Failed to read file: " + imageDataSource);
                    }

                    if(EDIT_STEPS == 0) {
                        mBitmapOriginal = mBitmap;
                    }

                    EDIT_STEPS++;
                } else if (imageDataType.equals("base64")) {
                    LOG.e("TouchDrawView","ImageEditActivity imageDataType base64 == " + imageDataType);
                    mBitmap = loadMutableBitmapFromBase64DataUrl(imageDataSource);

                    if(EDIT_STEPS == 0) {
                        mBitmapOriginal = mBitmap;
                    }

                    EDIT_STEPS++;
                    //mBitmap = loadMutableBitmapFromFileURI(new URI(imageDataSource));
                } else {
                    LOG.e("TouchDrawView","ImageEditActivity sourceType file OR base64");
                    return;
                }
            } catch (URISyntaxException e) {
                LOG.e("TouchDrawView","ImageEditActivity imageDataSource ERR" + e.getMessage());
                e.printStackTrace();
                return;
            } catch (IOException e) {
                LOG.e("TouchDrawView","ImageEditActivity imageDataSource ERR" + e.getMessage());
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

            if (touched && croppingStarted) {
                Paint paint = new Paint();
                paint.setColor(Color.TRANSPARENT);
                paint.setStyle(Paint.Style.FILL);
                // FILL
                canvas.drawRect(fromLeft, fromTop, fromLeftPlusWidth, fromTopPlusHeight, paint);

                paint.setStrokeWidth(10);
                paint.setColor(Color.BLACK);
                paint.setStyle(Paint.Style.STROKE);
                // BORDER
                canvas.drawRect(fromLeft, fromTop, fromLeftPlusWidth, fromTopPlusHeight, paint);
            }
        }

        private void touch_start(float x, float y) {
            LOG.i("Move", "TouchSTART");
            fromTop = y;
            fromLeft = x;

            mX = x;
            mY = y;

            touched = true;
            croppingDrawed = true;

            cropSaveButton.setVisibility(View.VISIBLE);

            Resources activityRes = this.getResources();
            cropAbortButton.setCompoundDrawablesWithIntrinsicBounds( null, null, activityRes.getDrawable(activityRes.getIdentifier("ic_action_cancel", "drawable", mainContext.getApplicationContext().getPackageName())), null);
        }

        private void touch_move(float x, float y) {
            LOG.i("Move", "Y: " + mY);
            LOG.i("Move", "X: " + mX);
            float dx = Math.abs(x - mX);
            float dy = Math.abs(y - mY);
            if (dx >= TOUCH_TOLERANCE || dy >= TOUCH_TOLERANCE) {
                mX = x;
                mY = y;

                fromLeftPlusWidth = x;
                fromTopPlusHeight = y;

                if(fromLeftPlusWidth < (fromLeft+50)) {
                    LOG.e("ALERT", "Over the top plus 50");
                    fromLeftPlusWidth = (fromLeft+50);
                }

                if(fromTopPlusHeight < (fromTop+50)) {
                    LOG.e("ALERT", "Over the top plus 50");
                    fromTopPlusHeight = (fromTop+50);
                }

                if(mY > mBitmap.getHeight()) {
                    LOG.e("ALERT", "Too Deep");
                    fromTopPlusHeight = mCanvas.getHeight();
                }
            }
        }

        private void touch_up() {
            LOG.i("Move", "TouchEND");
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            if(!croppingStarted) {
                return false;
            }

            int eventaction = event.getAction();
            LOG.i("onTouchEvent", "" + eventaction);

            float x = event.getX();
            float y = event.getY();

            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    touch_start(x, y);
                    invalidate();
                    break;
                case MotionEvent.ACTION_MOVE:
                    touch_move(x, y);
                    invalidate();
                    break;
                case MotionEvent.ACTION_UP:
                    touch_up();
                    invalidate();
                    break;
            }
            return true;
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
        scaleBitmap(mBitmap).compress(Bitmap.CompressFormat.JPEG, 75, drawing);

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

        filterSWApplied = false;
        filterSHApplied = false;
        filterGSApplied = false;
        filterSPApplied = false;
    }

    public void setFilterApplied(Boolean isApplied) {
        LOG.e("ACTION", "setFilterApplied");

        filterApplied = isApplied;
    }

    public void startCropping() {
        LOG.e("ACTION", "startCropping");

    }

    public void setRotateFilter(Integer rotateDegrees) {
        LOG.e("ACTION", "setRotateFilter => " + rotateDegrees);

        Matrix matrix = new Matrix();

        matrix.postRotate(rotateDegrees);

        Bitmap rotatedBitmap = Bitmap.createBitmap(mBitmap, 0, 0, mBitmap.getWidth(), mBitmap.getHeight(), matrix, true);

        //mBitmap = Bitmap.createScaledBitmap(rotatedBitmap, mTdView.mCanvas.getWidth(), mTdView.mCanvas.getHeight(), false);
        mBitmap = rotatedBitmap;
        mBitmapOriginal = rotatedBitmap;
        mTdView.mCanvas = new Canvas(rotatedBitmap);

        mTdView.invalidate();
    }

    public void setGreyscaleFilter() {
        LOG.e("ACTION", "setGreyscale");

        Bitmap bmGrayScale = getGrayscaleFilter(mBitmap);

        mBitmap = Bitmap.createScaledBitmap(bmGrayScale, mTdView.mCanvas.getWidth(), mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);

        mTdView.invalidate();

        filterGSApplied = true;
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

        mBitmap = Bitmap.createScaledBitmap(bmBWScale, mTdView.mCanvas.getWidth(), mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();

        filterSWApplied = true;
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

    public void executeCropping() {
        LOG.e("ACTION", "executeCropping");

        Integer width = (Math.round(fromLeftPlusWidth)-Math.round(fromLeft));
        Integer height = (Math.round(fromTopPlusHeight)-Math.round(fromTop));
        mBitmap = Bitmap.createBitmap(mBitmap, Math.round(fromLeft), Math.round(fromTop), width, height);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();

    }

    public void setSepiaFilter() {
        LOG.e("ACTION", "setSepia");

        //Bitmap bmGrayScale = getGrayscaleFilter(mBitmap);
        Bitmap bmSePScale = getSepiaFilter(mBitmap);

        mBitmap = Bitmap.createScaledBitmap(bmSePScale, mTdView.mCanvas.getWidth(), mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();

        filterSPApplied = true;
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

    public void setSharpnessFilter() {
        LOG.e("ACTION", "setSharpnessFilter");

        // low
        float[] sharp = { -0.60f, -0.60f, -0.60f, -0.60f, 5.81f, -0.60f, -0.60f, -0.60f, -0.60f };
        // medium
        //float[] sharp = { 0.0f, -1.0f, 0.0f, -1.0f, 5.0f, -1.0f, 0.0f, -1.0f, 0.0f };
        // high
        //float[] sharp = { -0.15f, -0.15f, -0.15f, -0.15f, 2.2f, -0.15f, -0.15f, -0.15f, -0.15f };

        //Bitmap bmSharpScale = getSharpnessFilter(mBitmap);
        Bitmap bmSharpScale = doSharpen(this, mBitmap, sharp);

        mBitmap = Bitmap.createScaledBitmap(bmSharpScale, mTdView.mCanvas.getWidth(), mTdView.mCanvas.getHeight(), false);
        mTdView.mCanvas = new Canvas(mBitmap);
        mTdView.invalidate();

        filterSPApplied = true;
    }

    public static Bitmap doSharpen(Context context, Bitmap original, float[] radius) {
        Bitmap bitmap = Bitmap.createBitmap(
                original.getWidth(), original.getHeight(),
                Bitmap.Config.ARGB_8888);

        RenderScript rs = RenderScript.create(context);

        Allocation allocIn = Allocation.createFromBitmap(rs, original);
        Allocation allocOut = Allocation.createFromBitmap(rs, bitmap);

        ScriptIntrinsicConvolve3x3 convolution
                = ScriptIntrinsicConvolve3x3.create(rs, Element.U8_4(rs));
        convolution.setInput(allocIn);
        convolution.setCoefficients(radius);
        convolution.forEach(allocOut);

        allocOut.copyTo(bitmap);
        rs.destroy();

        return bitmap;

    }

    public static Bitmap getSharpnessFilter(Bitmap src) {
        //Custom color matrix to convert to GrayScale
        float[] matrix = new float[]{ -0.60f, -0.60f, -0.60f, -0.60f, 5.81f, -0.60f,
                -0.60f, -0.60f, -0.60f };

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
