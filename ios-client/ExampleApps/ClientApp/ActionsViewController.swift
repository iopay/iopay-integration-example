//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

/// For testing we recommend to use Rainbow Wallet
/// MetaMask does not support `eth_gasPrice` and `eth_getTransactionCount` at the moment of testing 01.09.2021
class ActionsViewController: UIViewController {
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var personalSignButton: UIButton!
    @IBOutlet weak var ethSignButton: UIButton!
    @IBOutlet weak var ethSignTypedDataButton: UIButton!
    @IBOutlet weak var ethSendTransactionButton: UIButton!
    @IBOutlet weak var ethSignTransactionButton: UIButton!
    @IBOutlet weak var ethSendRawTransactionButton: UIButton!
    @IBOutlet weak var ethCustomRequestButton: UIButton!

    var client: Client!
    var session: Session!

    static func create(walletConnect: WalletConnect) -> ActionsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "ActionsViewController") as! ActionsViewController
        controller.client = walletConnect.client
        controller.session = walletConnect.session
        return controller
    }

    var walletAccount: String {
        return session.walletInfo!.accounts[0]
    }

    @IBAction func disconnect(_ sender: Any) {
        guard let session = session else { return }
        try? client.disconnect(from: session)
    }

    // personal_sign should send a human readable message
    @IBAction func personal_sign(_ sender: Any) {
        try? client.personal_sign(url: session.url, message: "Hi there!", account: session.walletInfo!.accounts[0]) {
            [weak self] response in
            self?.handleReponse(response, expecting: "Signature")
        }
    }

    // eth_sign should send a properly formed hash: keccak256("\x19Ethereum Signed Message:\n" + len(message) + message))
    @IBAction func eth_sign(_ sender: Any) {
        try? client.eth_sign(url: session.url, account: session.walletInfo!.accounts[0], message: "0x0123") {
            [weak self] response in
            self?.handleReponse(response, expecting: "Signature")
        }
    }

    @IBAction func eth_signTypedData(_ sender: Any) {
        try? client.eth_signTypedData(url: session.url,
                                      account: session.walletInfo!.accounts[0],
                                      message: Stub.typedData) {
            [weak self] response in
            self?.handleReponse(response, expecting: "Signature") }
    }

    @IBAction func eth_sendTransaction(_ sender: Any) {
        
        //the nonce will be requested in iopay
        let transaction = Stub.transaction(from: self.walletAccount, nonce: "0")
        try? self.client.eth_sendTransaction(url: session.url, transaction: transaction) { [weak self] response in
            self?.handleReponse(response, expecting: "Hash")
        }
        
        let deepLinkUrl = "io.iotex.iopay://xxx"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let url = URL(string: deepLinkUrl), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    @IBAction func eth_signTransaction(_ sender: Any) {
        let transaction = Stub.transaction(from: self.walletAccount, nonce: "0x0")
        try? self.client.eth_signTransaction(url: session.url, transaction: transaction) { [weak self] response in
            self?.handleReponse(response, expecting: "Signature")
        }
    }

    @IBAction func eth_sendRawTransaction(_ sender: Any) {
        try? client.eth_sendRawTransaction(url: session.url, data: Stub.data) { [weak self] response in
            self?.handleReponse(response, expecting: "Hash")
        }
    }

    @IBAction func customRequest(_ sender: Any) {
        // We recommend to use Rainbow Wallet to test this reques
        try? client.send(.eth_gasPrice(url: session.url)) { [weak self] response in
            self?.handleReponse(response, expecting: "Gas Price")
        }
    }

    @IBAction func customContractMethodCall(_ sender: Any) {
            
        let abi = Stub.customABI
        let contractAddress = "0xb3e556D64A769bD056d06b50D44748803c2F9855"
        let method = "approve"
        let wcMethod = "approve"
        let params = ["0x21d6ba1Da84257e53513FcC110eED2bA7b8B4c91", "1"]
        try? client.send(.customContract(url: session.url,
                                         wcMethod: wcMethod,
                                         requirement:[abi, method, contractAddress],
                                         params: params)) { [weak self] response in
            self?.handleReponse(response, expecting: "")
        }
        let deepLinkUrl = "io.iotex.iopay://xxx"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let url = URL(string: deepLinkUrl), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    
    @IBAction func close(_ sender: Any) {
        for session in client.openSessions() {
            try? client.disconnect(from: session)
        }
        dismiss(animated: true)
    }

    private func handleReponse(_ response: Response, expecting: String) {
        DispatchQueue.main.async {
            if let error = response.error {
                self.show(UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert))
                return
            }
            do {
                let result = try response.result(as: String.self)
                self.show(UIAlertController(title: expecting, message: result, preferredStyle: .alert))
            } catch {
                self.show(UIAlertController(title: "Error",
                                       message: "Unexpected response type error: \(error)",
                                       preferredStyle: .alert))
            }
        }
    }

    private func show(_ alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        self.present(alert, animated: true)
    }

    private func nonceRequest() -> Request {
        return .eth_getTransactionCount(url: session.url, account: session.walletInfo!.accounts[0])
    }

    private func nonce(from response: Response) -> String? {
        return try? response.result(as: String.self)
    }
}

extension Request {
    static func eth_getTransactionCount(url: WCURL, account: String) -> Request {
        return try! Request(url: url, method: "eth_getTransactionCount", params: [account, "latest"])
    }

    static func eth_gasPrice(url: WCURL) -> Request {
        return Request(url: url, method: "eth_gasPrice")
    }
    
    static func customContract(url: WCURL, wcMethod: String, requirement: [String], params: [String]) -> Request {
        return try! Request(url: url, method: wcMethod, params: [requirement, params])
    }
}

fileprivate enum Stub {
    /// https://docs.walletconnect.org/json-rpc-api-methods/ethereum#example-parameters
    static let typedData = """
{
    "types": {
        "EIP712Domain": [
            {
                "name": "name",
                "type": "string"
            },
            {
                "name": "version",
                "type": "string"
            },
            {
                "name": "chainId",
                "type": "uint256"
            },
            {
                "name": "verifyingContract",
                "type": "address"
            }
        ],
        "Person": [
            {
                "name": "name",
                "type": "string"
            },
            {
                "name": "wallet",
                "type": "address"
            }
        ],
        "Mail": [
            {
                "name": "from",
                "type": "Person"
            },
            {
                "name": "to",
                "type": "Person"
            },
            {
                "name": "contents",
                "type": "string"
            }
        ]
    },
    "primaryType": "Mail",
    "domain": {
        "name": "Ether Mail",
        "version": "1",
        "chainId": 1,
        "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
    },
    "message": {
        "from": {
            "name": "Cow",
            "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
        },
        "to": {
            "name": "Bob",
            "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
        },
        "contents": "Hello, Bob!"
    }
}
"""

    /// https://docs.walletconnect.org/json-rpc-api-methods/ethereum#example-parameters-1
    static func transaction(from address: String, nonce: String) -> Client.Transaction {
        return Client.Transaction(from: address,
                                  to: "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
                                  data: "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
                                  gas: "0x76c0", // 30400
                                  gasPrice: "0x9184e72a000", // 10000000000000
                                  value: "0x16345785d8a0000", // 2441406250
                                  nonce: nonce,
                                  type: nil,
                                  accessList: nil,
                                  chainId: nil,
                                  maxPriorityFeePerGas: nil,
                                  maxFeePerGas: nil)
    }

    /// https://docs.walletconnect.org/json-rpc-api-methods/ethereum#example-5
    static let data = "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f07244567"
    
    
    public static var customABI = """
  [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "chainId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_notary",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "name": "Approval",
    "type": "event",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "approved",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "name": "ApprovalForAll",
    "type": "event",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "operator",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "approved",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
      }
    ],
    "anonymous": false
  },
  {
    "name": "OwnershipTransferred",
    "type": "event",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "name": "TokenConsumed",
    "type": "event",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "consumer",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "owner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "name": "Transfer",
    "type": "event",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "name": "AUTHENTICATION_TYPEHASH",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "DOMAIN_SEPARATOR",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "EIP712DOMAIN_TYPEHASH",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "approve",
    "type": "function",
    "inputs": [
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "balanceOf",
    "type": "function",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "baseURI",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "consume",
    "type": "function",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "consumed",
    "type": "function",
    "inputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "cost",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "digest",
    "type": "function",
    "inputs": [
      {
        "name": "wallet",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "ticket",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "deadline",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "getApproved",
    "type": "function",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "isApprovedForAll",
    "type": "function",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "operator",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "maxTokens",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "mint",
    "type": "function",
    "inputs": [],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "name": "name",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "nextTokenId",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "notary",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "owner",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "ownerOf",
    "type": "function",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "purchase",
    "type": "function",
    "inputs": [
      {
        "name": "_ticket",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "_deadline",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_v",
        "type": "uint8",
        "internalType": "uint8"
      },
      {
        "name": "_r",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "_s",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "name": "purchased",
    "type": "function",
    "inputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "renounceOwnership",
    "type": "function",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "safeTransferFrom",
    "type": "function",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "safeTransferFrom",
    "type": "function",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "_data",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "setApprovalForAll",
    "type": "function",
    "inputs": [
      {
        "name": "operator",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "approved",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "setCost",
    "type": "function",
    "inputs": [
      {
        "name": "_val",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "setMaxTokens",
    "type": "function",
    "inputs": [
      {
        "name": "_val",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "setNotary",
    "type": "function",
    "inputs": [
      {
        "name": "_notary",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "supportsInterface",
    "type": "function",
    "inputs": [
      {
        "name": "interfaceId",
        "type": "bytes4",
        "internalType": "bytes4"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "symbol",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "tokenByIndex",
    "type": "function",
    "inputs": [
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "tokenOfOwnerByIndex",
    "type": "function",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "tokenURI",
    "type": "function",
    "inputs": [
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "string",
        "internalType": "string"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "totalSupply",
    "type": "function",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "name": "transferFrom",
    "type": "function",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "name": "transferOwnership",
    "type": "function",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  }
]
"""

}
