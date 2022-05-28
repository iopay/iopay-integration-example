package io.iotex.walletconnect_sample.http

import com.blankj.utilcode.util.AppUtils
import com.google.gson.Gson
import io.reactivex.Observer
import io.reactivex.disposables.Disposable
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.adapter.rxjava2.RxJava2CallAdapterFactory
import retrofit2.converter.gson.GsonConverterFactory
import java.lang.Exception
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

const val BASE_URL = "https://ethereum-api.xyz"

object HttpManager {

    private val okClient by lazy {
        val loggingInterceptor = HttpLoggingInterceptor()
        loggingInterceptor.level =
            if (AppUtils.isAppDebug())
                HttpLoggingInterceptor.Level.BODY
            else
                HttpLoggingInterceptor.Level.NONE

        OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .callTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .addInterceptor(loggingInterceptor)
            .build()
    }

    val httpService by lazy {
        Retrofit.Builder().baseUrl(BASE_URL)
            .client(okClient)
            .addCallAdapterFactory(RxJava2CallAdapterFactory.create())
            .addConverterFactory(GsonConverterFactory.create(Gson()))
            .build().create(HttpService::class.java)
    }

    suspend fun getAccountAssets(address: String, chainId: Long): AssetsEntity? {
        return withContext(Dispatchers.IO) {
            suspendCoroutine { continuation ->
                httpService.getAccountAssets(address, chainId)
                    .subscribe(object : Observer<BaseResp<List<AssetsEntity>>>{
                        override fun onSubscribe(d: Disposable) {
                        }

                        override fun onNext(t: BaseResp<List<AssetsEntity>>) {
                            if (t.success && !t.result.isNullOrEmpty()) {
                                continuation.resumeWith(Result.success(t.result[0]))
                            } else {
                                continuation.resumeWithException(Exception(t.message))
                            }
                        }

                        override fun onError(e: Throwable) {
                            continuation.resumeWithException(e)
                        }

                        override fun onComplete() {
                        }
                    })
            }
        }
    }

    suspend fun getAccountNonce(address: String, chainId: Long): Long? {
        return withContext(Dispatchers.IO) {
            suspendCoroutine { continuation ->
                httpService.getAccountNonce(address, chainId)
                    .subscribe(object : Observer<BaseResp<Long>>{
                        override fun onSubscribe(d: Disposable) {
                        }

                        override fun onNext(t: BaseResp<Long>) {
                            if (t.success) {
                                continuation.resumeWith(Result.success(t.result))
                            } else {
                                continuation.resumeWithException(Exception(t.message))
                            }
                        }

                        override fun onError(e: Throwable) {
                            continuation.resumeWithException(e)
                        }

                        override fun onComplete() {
                        }
                    })
            }
        }
    }

    suspend fun getGasPrices(): GasPriceEntity? {
        return withContext(Dispatchers.IO) {
            suspendCoroutine { continuation ->
                httpService.getGasPrices()
                    .subscribe(object : Observer<BaseResp<GasPriceEntity>>{
                        override fun onSubscribe(d: Disposable) {
                        }

                        override fun onNext(t: BaseResp<GasPriceEntity>) {
                            if (t.success) {
                                continuation.resumeWith(Result.success(t.result))
                            } else {
                                continuation.resumeWithException(Exception(t.message))
                            }
                        }

                        override fun onError(e: Throwable) {
                            continuation.resumeWithException(e)
                        }

                        override fun onComplete() {
                        }
                    })
            }
        }
    }


}