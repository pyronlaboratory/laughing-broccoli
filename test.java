package io.sensable.client.component;
import android.content.Context;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.widget.TextView;

/**
 * Extends the Android TextView class to dynamically adjust font size based on the
 * available width.
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
     * and copies the current paint settings to the new instance.
     */
    private void initialise() {
        mTestPaint = new Paint();
        mTestPaint.set(this.getPaint());
    }

    /**
     * Adjusts the font size of the text to fit within a specified width, taking into
     * account the padding on both sides. It iteratively refines the font size using a
     * binary search algorithm until the measured text width exceeds the target width.
     *
     * @param text text to be measured and formatted within a specified width.
     *
     * @param textWidth available width for the text after accounting for the left and
     * right padding.
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
     * Retrieves the parent's width, measures the view's height, refits the text to the
     * parent's width, and sets the measured dimension to the parent's width and the
     * view's height.
     *
     * @param widthMeasureSpec measure specification for the view's width, which is used
     * to determine the view's dimensions.
     *
     * @param heightMeasureSpec measurements that the parent layout is willing to provide
     * for the height of the view.
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
     * Is overridden to handle text changes in a text field. It calls the `refitText`
     * function to adjust the text based on the current width of the field.
     *
     * @param text changed text in the view.
     *
     * @param start starting offset of the text change within the CharSequence.
     *
     * @param before length of the text before the change occurred.
     *
     * @param after number of characters added to the text at the specified position.
     */
    @Override
    protected void onTextChanged(final CharSequence text, final int start, final int before, final int after) {
        refitText(text.toString(), this.getWidth());
    }


    /**
     * Adapts the text layout when the view's width changes. It checks if the new width
     * differs from the old width, and if so, it calls the `refitText` method to update
     * the text based on the new width.
     *
     * @param w new width of the view that has changed.
     *
     * @param h new height of the view.
     *
     * @param oldw previous width of the view, used for comparison with the current width
     * `w`.
     *
     * @param oldh previous height of the view before the size change occurred.
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
