package io.iotex.walletconnect_sample

import org.web3j.protocol.Web3j
import org.web3j.protocol.core.DefaultBlockParameter
import org.web3j.protocol.core.DefaultBlockParameterName
import org.web3j.protocol.core.methods.request.Transaction
import org.web3j.protocol.http.HttpService

object Web3Helper {

    private val web3j by lazy {
        val service = HttpService("https://kovan.infura.io/v3/543526cd4d3846acbc3826484e934564", true)
        Web3j.build(service)
    }

    fun executeContract(from: String, contract: String, data: String) {
        val transaction = Transaction.createEthCallTransaction(from, contract, data)
        val response = web3j.ethCall(transaction, DefaultBlockParameterName.LATEST).sendAsync().get()
    }


}