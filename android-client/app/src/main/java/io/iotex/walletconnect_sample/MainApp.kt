package io.iotex.walletconnect_sample

import android.app.Application
import com.blankj.utilcode.util.AppUtils
import io.reactivex.plugins.RxJavaPlugins
import timber.log.Timber

class MainApp : Application() {

    override fun onCreate() {
        super.onCreate()

        RxJavaPlugins.setErrorHandler { t: Throwable? ->
            Timber.e(t)
        }

        if (AppUtils.isAppDebug()) {
            Timber.plant(Timber.DebugTree())
        }
    }
}