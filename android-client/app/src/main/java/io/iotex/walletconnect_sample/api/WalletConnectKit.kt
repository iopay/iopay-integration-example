package io.iotex.walletconnect_sample.api

import io.iotex.walletconnect_sample.common.WalletConnectKitModule
import io.iotex.walletconnect_sample.data.session.SessionManager
import io.iotex.walletconnect_sample.data.wallet.WalletManager

class WalletConnectKit private constructor(
    sessionManager: SessionManager,
    walletManager: WalletManager,
) : SessionManager by sessionManager, WalletManager by walletManager {

    class Builder(config: WalletConnectKitConfig) {

        private val walletConnectKitModule = WalletConnectKitModule(config.context, config)

        fun build() = WalletConnectKit(
            walletConnectKitModule.sessionRepository, walletConnectKitModule.walletRepository
        )
    }
}