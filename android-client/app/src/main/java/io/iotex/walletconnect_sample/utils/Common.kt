package io.iotex.walletconnect_sample.utils

import com.blankj.utilcode.util.ConvertUtils
import org.web3j.utils.Numeric

fun <T1: Any, T2: Any, R: Any> safeLet(p1: T1?, p2: T2?, block: (T1, T2)->R?): R? {
    return if (p1 != null && p2 != null) block(p1, p2) else null
}

fun String.toHexByteArray(): ByteArray {
    return Numeric.hexStringToByteArray(this)
}

fun ByteArray.toHexString(): String {
    return Numeric.toHexString(this)
}

fun Float.dp2px(): Int {
    return ConvertUtils.dp2px(this)
}

fun Int.dp2px(): Int {
    return ConvertUtils.dp2px(this.toFloat())
}

fun Float.px2dp(): Int {
    return ConvertUtils.px2dp(this)
}

fun Int.px2dp(): Int {
    return ConvertUtils.px2dp(this.toFloat())
}