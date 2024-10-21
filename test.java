package io.sensable.client.component;
import android.content.Context;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.util.TypedValue;
import android.widget.TextView;

/**
 * Automatically adjusts font size of text to fit within a specified width, ensuring
 * optimal readability.
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
     * Creates a new instance of the `Paint` class and assigns it to the `mTestPaint`
     * variable, then copies the properties from the current `Paint` instance to `mTestPaint`.
     */
    private void initialise() {
        mTestPaint = new Paint();
        mTestPaint.set(this.getPaint());
    }

    /**
     * Determines the optimal text size to fit a specified text within a given width,
     * taking into account the padding of the text container. It iteratively adjusts the
     * text size until it finds a suitable fit.
     *
     * @param text text that is being measured and resized to fit the specified width.
     *
     * @param textWidth available width for the text after removing the left and right padding.
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
     * Resizes the view based on the parent's available width, adjusts its text to fit,
     * and then sets the view's measured dimensions accordingly.
     *
     * @param widthMeasureSpec measurements that the parent layout is willing to provide
     * to the view, including any constraints or requirements.
     *
     * @param heightMeasureSpec measurements that the parent layout imposes on the height
     * of the view.
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
     * Is overridden to handle text changes in a text field.
     * It calls the `refitText` function to adjust the text layout based on the updated
     * text and the current width of the text field.
     *
     * @param text current text sequence in the editable field.
     *
     * @param start starting offset in the CharSequence where the change occurred.
     *
     * @param before number of characters in the text before the changes made in the
     * current edit operation.
     *
     * @param after number of characters that were added to the text.
     */
    @Override
    protected void onTextChanged(final CharSequence text, final int start, final int before, final int after) {
        refitText(text.toString(), this.getWidth());
    }


    /**
     * Is overridden to respond to changes in the view's width,
     * adjusting the text layout if the width changes.
     *
     * @param w new width of the component.
     *
     * @param h new height of the view.
     *
     * @param oldw previous width of the view before the size change.
     *
     * @param oldh height of the view before its size changed.
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
