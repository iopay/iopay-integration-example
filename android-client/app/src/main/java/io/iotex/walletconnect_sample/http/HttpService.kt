package io.iotex.walletconnect_sample.http

import io.reactivex.Observable
import retrofit2.http.GET
import retrofit2.http.Query

interface HttpService {

    @GET("/account-assets")
    fun getAccountAssets(
        @Query("address") address: String,
        @Query("chainId") chainId: Long
    ): Observable<BaseResp<List<AssetsEntity>>>

    @GET("/account-nonce")
    fun getAccountNonce(
        @Query("address") address: String,
        @Query("chainId") chainId: Long
    ): Observable<BaseResp<Long>>

    @GET("/gas-prices")
    fun getGasPrices(): Observable<BaseResp<GasPriceEntity>>

}