package io.iotex.walletconnect_sample.data.session

import org.walletconnect.Session

interface SessionManager {
    var session: Session?
    val address: String?
    val chainId: Long?
    fun createSession(callback: Session.Callback)
    fun removeSession()
    fun loadSession(callback: Session.Callback)
    val isSessionStored: Boolean
}