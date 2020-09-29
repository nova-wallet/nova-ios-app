import Foundation

enum RPCMethod {
    static let chain = "system_chain"
    static let getStorage = "state_getStorage"
    static let getBlockHash = "chain_getBlockHash"
    static let submitExtrinsic = "author_submitExtrinsic"
    static let paymentInfo = "payment_queryInfo"
    static let getRuntimeVersion = "chain_getRuntimeVersion"
}