package io.iotex.walletconnect_sample

import android.app.Activity
import android.app.Dialog
import android.content.Context
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import com.blankj.utilcode.util.ScreenUtils
import io.iotex.walletconnect_sample.utils.dp2px

class ValidateDialog(val context: Context) {

    private val mDialog: Dialog = Dialog(context, R.style.CommonDialog)
    private val mContentView: View =
        LayoutInflater.from(context).inflate(R.layout.dialog_validate, null)

    private val mTvMethod by lazy {
        mContentView.findViewById<TextView>(R.id.mTvMethod)
    }
    private val mTvAddress by lazy {
        mContentView.findViewById<TextView>(R.id.mTvAddress)
    }
    private val mTvValid by lazy {
        mContentView.findViewById<TextView>(R.id.mTvValid)
    }
    private val mTvResult by lazy {
        mContentView.findViewById<TextView>(R.id.mTvResult)
    }
    private val mTvWaiting by lazy {
        mContentView.findViewById<TextView>(R.id.mTvWaiting)
    }
    private val mLlResponse by lazy {
        mContentView.findViewById<LinearLayout>(R.id.mLlResponse)
    }

    init {
        mDialog.setContentView(mContentView)

        val params = mDialog.window?.attributes
        params?.width = ScreenUtils.getScreenWidth() - (15 * 2).dp2px()
        params?.height = WindowManager.LayoutParams.WRAP_CONTENT
        params?.gravity = Gravity.CENTER
        mDialog.window?.attributes = params
    }

    fun setMethod(method: String) = apply {
        mTvMethod.text = method
    }

    fun setAddress(address: String) = apply {
        mTvAddress.text = address
    }

    fun setValid(valid: String) = apply {
        mTvValid.text = valid
    }

    fun setResult(result: String) = apply {
        mTvResult.text = result
    }

    fun renderConnect() = apply {
        mTvWaiting.visibility = View.GONE
        mLlResponse.visibility = View.VISIBLE
    }

    fun show() = apply {
        if (context is Activity && !context.isFinishing && !mDialog.isShowing) {
            mDialog.show()
        }
    }

    fun dismiss() {
        if (mDialog.isShowing){
            mDialog.dismiss()
        }
    }

}