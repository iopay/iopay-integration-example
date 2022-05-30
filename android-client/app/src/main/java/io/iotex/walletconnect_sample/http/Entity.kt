package io.iotex.walletconnect_sample.http

data class BaseResp<T>(val success: Boolean, val result: T?, val error: String?, val message: String?)

data class AssetsEntity(
    val balance: String,
    val contractAddress: String,
    val decimals: String,
    val name: String,
    val symbol: String
)

data class GasPriceEntity(
    val average: Average,
    val fast: Fast,
    val slow: Slow,
    val timestamp: Long
)

data class Average(
    val price: Int,
    val time: Int
)

data class Fast(
    val price: Int,
    val time: Int
)

data class Slow(
    val price: Int,
    val time: Int
)