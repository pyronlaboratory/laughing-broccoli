package io.sensable.client.component;
import android.content.Context;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.widget.TextView;

/**
 * Extends the standard Android TextView class to automatically adjust font size based
 * on the available width.
 */
public class FontFitTextView extends TextView {

    public FontFitTextView(Context context) {
        super(context);
        initialise();
    }

    public FontFitTextView(Context context, AttributeSet attrs) {
        super(context, attrs);
        initialise();
    }

    /**
     * Creates a new instance of the `Paint` class, assigns it to the `mTestPaint` variable,
     * and sets its properties to match the current paint settings.
     */
    private void initialise() {
        mTestPaint = new Paint();
        mTestPaint.set(this.getPaint());
    }

    /**
     * Adjusts the text size within a given width constraint, iteratively narrowing down
     * the range of possible sizes until the text fits within the target width, then sets
     * the text size to the smallest suitable value.
     *
     * @param text text to be measured and resized to fit within a specified width.
     *
     * @param textWidth available width for the text, subtracting the padding on both sides.
     */
    private void refitText(String text, int textWidth)
    {
        if (textWidth <= 0)
            return;
        int targetWidth = textWidth - this.getPaddingLeft() - this.getPaddingRight();
        float hi = 100;
        float lo = 2;
        final float threshold = 0.5f; // How close we have to be

        mTestPaint.set(this.getPaint());

        while((hi - lo) > threshold) {
            float size = (hi+lo)/2;
            mTestPaint.setTextSize(size);
            if(mTestPaint.measureText(text) >= targetWidth)
                hi = size; // too big
            else
                lo = size; // too small
        }
        this.setTextSize(TypedValue.COMPLEX_UNIT_PX, lo);
    }

    /**
     * Measures and sets the dimensions of a view based on its parent's width and the
     * view's own text content. It calls the parent's `onMeasure` function, retrieves the
     * parent's width, measures the view's height, refits the text to the parent's width,
     * and sets the view's measured dimensions.
     *
     * @param widthMeasureSpec measurements constraints imposed by the parent layout,
     * specifying the width and any additional flags that may affect the measurement process.
     *
     * @param heightMeasureSpec measurements constraints for the height of the view, which
     * can be used to determine the actual height of the view.
     */
    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec)
    {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int parentWidth = MeasureSpec.getSize(widthMeasureSpec);
        int height = getMeasuredHeight();
        refitText(this.getText().toString(), parentWidth);
        this.setMeasuredDimension(parentWidth, height);
    }

    /**
     * Is overridden to handle changes to the text.
     * It calls the `refitText` function to adjust the text layout based on the new text
     * and the current widget width.
     *
     * @param text text that has been changed.
     *
     * @param start starting position of the changed text within the CharSequence.
     *
     * @param before length of the text before the change was made.
     *
     * @param after number of characters that were inserted into the text.
     */
    @Override
    protected void onTextChanged(final CharSequence text, final int start, final int before, final int after) {
        refitText(text.toString(), this.getWidth());
    }


    /**
     * Is overridden to handle changes in the view's width, and it calls the `refitText`
     * function to adjust the text when the width changes.
     *
     * @param w new width of the view.
     *
     * @param h new height of the view.
     *
     * @param oldw previous width of the view before the size change occurred.
     *
     * @param oldh old height of the view before the size change.
     */
    @Override
    protected void onSizeChanged (int w, int h, int oldw, int oldh) {
        if (w != oldw) {
            refitText(this.getText().toString(), w);
        }
    }

    //Attributes
    private Paint mTestPaint;
}
