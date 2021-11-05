import Foundation
import CommonWallet
import SoraFoundation

final class AssetDetailsViewModelFactory: AccountListViewModelFactoryProtocol {
    let metaAccount: MetaAccountModel
    let chains: [ChainModel.Id: ChainModel]
    let purchaseProvider: PurchaseProviderProtocol
    let amountFormatterFactory: NumberFormatterFactoryProtocol
    let priceAsset: WalletAsset

    init(
        metaAccount: MetaAccountModel,
        chains: [ChainModel.Id: ChainModel],
        purchaseProvider: PurchaseProviderProtocol,
        amountFormatterFactory: NumberFormatterFactoryProtocol,
        priceAsset: WalletAsset
    ) {
        self.metaAccount = metaAccount
        self.chains = chains
        self.purchaseProvider = purchaseProvider
        self.amountFormatterFactory = amountFormatterFactory
        self.priceAsset = priceAsset
    }

    private func createFormattedAmount(from decimalValue: Decimal, with amountFormatter: TokenFormatter) -> String {
        guard let amountString = amountFormatter.stringFromDecimal(decimalValue) else {
            return decimalValue.stringWithPointSeparator
        }

        return amountString
    }

    private func createBalanceViewModel(
        from amount: Decimal,
        price: Decimal,
        with amountFormatter: TokenFormatter,
        priceFormatter: TokenFormatter
    ) -> BalanceViewModel {
        let amountString = createFormattedAmount(from: amount, with: amountFormatter)
        let priceString = priceFormatter.stringFromDecimal(amount * price)

        return BalanceViewModel(amount: amountString, price: priceString)
    }

    func createAssetViewModel(
        for asset: WalletAsset,
        balance: BalanceData,
        commandFactory: WalletCommandFactoryProtocol,
        locale: Locale
    ) -> WalletViewModelProtocol? {
        let amountFormatter = amountFormatterFactory.createTokenFormatter(for: asset)
            .value(for: locale)

        let localizablePriceFormatter = amountFormatterFactory.createTokenFormatter(for: priceAsset)
        let priceFormatter = localizablePriceFormatter.value(for: locale)

        let balanceContext = BalanceContext(context: balance.context ?? [:])

        let title = asset.symbol

        let imageViewModel: WalletImageViewModelProtocol?
        if
            let chainAssetId = ChainAssetId(walletId: asset.identifier),
            let chain = chains[chainAssetId.chainId],
            let asset = chain.assets.first(where: { $0.assetId == chainAssetId.assetId }) {
            let iconUrl = asset.icon ?? chain.icon
            imageViewModel = WalletRemoteImageViewModel(
                url: iconUrl,
                size: CGSize(width: 32, height: 32)
            )
        } else {
            imageViewModel = nil
        }

        let priceString = priceFormatter.stringFromDecimal(balanceContext.price) ?? ""

        let priceChangeString = NumberFormatter.signedPercent
            .localizableResource()
            .value(for: locale)
            .string(from: balanceContext.priceChange as NSNumber) ?? ""

        let priceChangeViewModel = balanceContext.priceChange >= 0.0 ?
            WalletPriceChangeViewModel.goingUp(displayValue: priceChangeString) :
            WalletPriceChangeViewModel.goingDown(displayValue: priceChangeString)

        let numberFormatter = amountFormatterFactory.createDisplayFormatter(for: asset)

        let balancesTitle = R.string.localizable.walletBalancesWidgetTitle(preferredLanguages: locale.rLanguages)
        let totalTitle = R.string.localizable.walletTransferTotalTitle(preferredLanguages: locale.rLanguages)
        let transferableTitle = R.string.localizable.walletBalanceAvailable(preferredLanguages: locale.rLanguages)
        let lockedTitle = R.string.localizable.walletBalanceLocked(preferredLanguages: locale.rLanguages)

        let totalBalance = createBalanceViewModel(
            from: balance.balance.decimalValue,
            price: balanceContext.price,
            with: amountFormatter,
            priceFormatter: priceFormatter
        )

        let transferableBalance = createBalanceViewModel(
            from: balanceContext.available,
            price: balanceContext.price,
            with: amountFormatter,
            priceFormatter: priceFormatter
        )

        let lockedBalance = createBalanceViewModel(
            from: balanceContext.locked,
            price: balanceContext.price,
            with: amountFormatter,
            priceFormatter: priceFormatter
        )

        let infoDetailsCommand = WalletAccountInfoCommand(
            balanceContext: balanceContext,
            amountFormatter: numberFormatter,
            priceFormatter: localizablePriceFormatter,
            commandFactory: commandFactory,
            precision: asset.precision
        )

        return AssetDetailsViewModel(
            title: title,
            imageViewModel: imageViewModel,
            price: priceString,
            priceChangeViewModel: priceChangeViewModel,
            balancesTitle: balancesTitle,
            totalTitle: totalTitle,
            totalBalance: totalBalance,
            transferableTitle: transferableTitle,
            transferableBalance: transferableBalance,
            lockedTitle: lockedTitle,
            lockedBalance: lockedBalance,
            infoDetailsCommand: infoDetailsCommand
        )
    }

    func createActionsViewModel(
        for assetId: String?,
        commandFactory: WalletCommandFactoryProtocol,
        locale: Locale
    ) -> WalletViewModelProtocol? {
        guard
            let assetId = assetId,
            let chainAssetId = ChainAssetId(walletId: assetId),
            let chain = chains[chainAssetId.chainId],
            let address = metaAccount.fetch(for: chain.accountRequest())?.toAddress() else {
            return nil
        }

        let sendCommand: WalletCommandProtocol = commandFactory.prepareSendCommand(for: assetId)
        let sendTitle = R.string.localizable
            .walletSendTitle(preferredLanguages: locale.rLanguages)
        let sendViewModel = WalletActionViewModel(
            title: sendTitle,
            command: sendCommand
        )

        let receiveCommand: WalletCommandProtocol = commandFactory.prepareReceiveCommand(for: assetId)

        let receiveTitle = R.string.localizable
            .walletAssetReceive(preferredLanguages: locale.rLanguages)
        let receiveViewModel = WalletActionViewModel(
            title: receiveTitle,
            command: receiveCommand
        )

        // TODO: fix purchase
        let buyCommand: WalletCommandProtocol?
        if
            let walletAssetId = WalletAssetId(chainId: chainAssetId.chainId),
            let walletChain = walletAssetId.chain {
            let actions = purchaseProvider.buildPurchaseActions(
                for: walletChain,
                assetId: walletAssetId,
                address: address
            )

            buyCommand = actions.isEmpty ? nil :
                WalletSelectPurchaseProviderCommand(
                    actions: actions,
                    commandFactory: commandFactory
                )
        } else {
            buyCommand = nil
        }

        let buyTitle = R.string.localizable.walletAssetBuy(preferredLanguages: locale.rLanguages)
        let buyViewModel = WalletDisablingAction(title: buyTitle, command: buyCommand)

        return WalletActionsViewModel(
            send: sendViewModel,
            receive: receiveViewModel,
            buy: buyViewModel
        )
    }
}
