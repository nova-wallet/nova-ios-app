import SoraFoundation
import CommonWallet

protocol RichAmountDisplayViewModelProtocol: WalletFormViewBindingProtocol,
    AssetBalanceViewModelProtocol {
    var title: String { get }
    var amount: String { get }
}

struct RichAmountDisplayViewModel: RichAmountDisplayViewModelProtocol {
    let title: String
    let amount: String
    let symbol: String
    let balance: String?
    let price: String?
    let iconViewModel: ImageViewModelProtocol?

    func accept(definition: WalletFormDefining) -> WalletFormItemView? {
        if let definition = definition as? WalletFearlessFormDefining {
            return definition.defineViewForAmountDisplay(self)
        } else {
            return nil
        }
    }
}
