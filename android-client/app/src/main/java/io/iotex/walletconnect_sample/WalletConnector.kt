package io.iotex.walletconnect_sample

import com.blankj.utilcode.util.Utils
import io.iotex.walletconnect_sample.api.WalletConnectKit
import io.iotex.walletconnect_sample.api.WalletConnectKitConfig
import io.iotex.walletconnect_sample.utils.i
import io.iotex.walletconnect_sample.utils.safeLet
import org.walletconnect.Session

object WalletConnector : Session.Callback {

    private val config by lazy {
        WalletConnectKitConfig(
            context = Utils.getApp(),
            bridgeUrl = "https://bridge.walletconnect.org",
            appUrl = "https://github.com/iotexproject/wallect-connect-example",
            appName = "WalletConnect Sample",
            appDescription = ""
        )
    }
    private val walletConnectKit by lazy { WalletConnectKit.Builder(config).build() }

    private lateinit var onConnected: (address: String, chainId: Long) -> Unit
    private var onDisconnected: (() -> Unit)? = null

    fun init(
        onConnected: (address: String, chainId: Long) -> Unit,
        onDisconnected: (() -> Unit)?
    ) {
        this.onConnected = onConnected
        this.onDisconnected = onDisconnected
        loadSessionIfStored()
    }

    fun connect() {
        if (walletConnectKit.isSessionStored) {
            walletConnectKit.removeSession()
        }
        walletConnectKit.createSession(this)
    }

    fun disconnect() {
        walletConnectKit.removeSession()
    }

    override fun onStatus(status: Session.Status) {
        "WalletConnector : ${status}".i()
        when (status) {
            is Session.Status.Approved -> onSessionApproved()
            is Session.Status.Connected -> onSessionConnected()
            is Session.Status.Closed -> onSessionDisconnected()
            else -> {}
        }
    }

    override fun onMethodCall(call: Session.MethodCall) {
    }

    private fun onSessionApproved() {
        safeLet(walletConnectKit.address, walletConnectKit.chainId, onConnected)
    }

    private fun onSessionConnected() {
        walletConnectKit.address ?: walletConnectKit.requestHandshake()
    }

    private fun onSessionDisconnected() {
        if (walletConnectKit.isSessionStored) {
            walletConnectKit.removeSession()
        }
        onDisconnected?.invoke()
    }

    private fun loadSessionIfStored() {
        if (walletConnectKit.isSessionStored) {
            walletConnectKit.loadSession(this)
            safeLet(walletConnectKit.address, walletConnectKit.chainId, onConnected)
        }
    }

    suspend fun sendTransaction(
        address: String,
        value: String,
        data: String?,
        nonce: String? = null,
        gasPrice: String? = null,
        gasLimit: String? = null
    ): Session.MethodCall.Response {
        return walletConnectKit.performTransaction(address, value, data, nonce, gasPrice, gasLimit)
    }

    suspend fun signMessage(address: String, message: String): Session.MethodCall.Response {
        return walletConnectKit.performSignMessage(address, message)
    }

    suspend fun signTransaction(params: List<*>): Session.MethodCall.Response {
        return walletConnectKit.performCustomMethod("eth_signTransaction", params)
    }

    suspend fun signTypeData(params: List<*>): Session.MethodCall.Response {
        return walletConnectKit.performCustomMethod("eth_signTypedData", params)
    }

    suspend fun personalSign(params: List<*>): Session.MethodCall.Response {
        return walletConnectKit.performCustomMethod("personal_sign", params)
    }

}