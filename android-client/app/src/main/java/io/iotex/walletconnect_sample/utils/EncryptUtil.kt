package io.iotex.walletconnect_sample.utils

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.web3j.crypto.ECDSASignature
import org.web3j.crypto.Hash
import org.web3j.crypto.Keys
import org.web3j.crypto.Sign
import org.web3j.crypto.Sign.SignatureData
import org.web3j.utils.Numeric
import java.math.BigInteger
import java.util.*

const val PERSONAL_MESSAGE_PREFIX ="\u0019Ethereum Signed Message:\n"

object EncryptUtil {

    suspend fun validateSignature(signature: String, message: String, address: String, addPrefix: Boolean = true)
    = withContext(Dispatchers.IO) {
        val msgHash = if (addPrefix) {
            val prefix = PERSONAL_MESSAGE_PREFIX + message.length
            Hash.sha3((prefix + message).toByteArray())
        } else {
            message.toHexByteArray()
        }
        val signatureBytes = Numeric.hexStringToByteArray(signature)
        var v = signatureBytes[64]
        if (v < 27) {
            v = v.plus(27).toByte()
        }

        val sd = SignatureData(
            v,
            Arrays.copyOfRange(signatureBytes, 0, 32),
            Arrays.copyOfRange(signatureBytes, 32, 64)
        )

        var addressRecovered = ""
        var match = false

        for (i in 0..3) {
            val publicKey = Sign.recoverFromSignature(
                i,
                ECDSASignature(BigInteger(1, sd.r), BigInteger(1, sd.s)),
                msgHash
            )

            if (publicKey != null) {
                addressRecovered = "0x" + Keys.getAddress(publicKey)

                if (addressRecovered == address) {
                    match = true
                    break
                }
            }
        }

        match
    }




}