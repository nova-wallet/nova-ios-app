import Foundation
import BigInt

final class StakingBondMoreConfirmationPresenter {
    weak var view: StakingBondMoreConfirmationViewProtocol?
    let wireframe: StakingBondMoreConfirmationWireframeProtocol
    let interactor: StakingBondMoreConfirmationInteractorInputProtocol

    let inputAmount: Decimal
    let confirmViewModelFactory: StakingBondMoreConfirmViewModelFactoryProtocol
    let balanceViewModelFactory: BalanceViewModelFactoryProtocol
    let dataValidatingFactory: StakingDataValidatingFactoryProtocol
    let assetInfo: AssetBalanceDisplayInfo
    let explorers: [ChainModel.Explorer]?
    let logger: LoggerProtocol?

    private var balance: Decimal?
    private var priceData: PriceData?
    private var fee: Decimal?
    private var stashAccount: MetaChainAccountResponse?
    private var stashItem: StashItem?

    init(
        interactor: StakingBondMoreConfirmationInteractorInputProtocol,
        wireframe: StakingBondMoreConfirmationWireframeProtocol,
        inputAmount: Decimal,
        confirmViewModelFactory: StakingBondMoreConfirmViewModelFactoryProtocol,
        balanceViewModelFactory: BalanceViewModelFactoryProtocol,
        dataValidatingFactory: StakingDataValidatingFactoryProtocol,
        assetInfo: AssetBalanceDisplayInfo,
        explorers: [ChainModel.Explorer]?,
        logger: LoggerProtocol? = nil
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.inputAmount = inputAmount
        self.confirmViewModelFactory = confirmViewModelFactory
        self.balanceViewModelFactory = balanceViewModelFactory
        self.dataValidatingFactory = dataValidatingFactory
        self.assetInfo = assetInfo
        self.explorers = explorers
        self.logger = logger
    }

    private func provideFeeViewModel() {
        if let fee = fee {
            let feeViewModel = balanceViewModelFactory.balanceFromPrice(fee, priceData: priceData)
            view?.didReceiveFee(viewModel: feeViewModel)
        } else {
            view?.didReceiveFee(viewModel: nil)
        }
    }

    private func provideAssetViewModel() {
        let viewModel = balanceViewModelFactory.lockingAmountFromPrice(inputAmount, priceData: priceData)

        view?.didReceiveAmount(viewModel: viewModel)
    }

    private func provideConfirmationViewModel() {
        guard let stashAccount = stashAccount else {
            return
        }

        do {
            let viewModel = try confirmViewModelFactory.createViewModel(stash: stashAccount)

            view?.didReceiveConfirmation(viewModel: viewModel)
        } catch {
            logger?.error("Did receive view model factory error: \(error)")
        }
    }

    func refreshFeeIfNeeded() {
        guard fee == nil else {
            return
        }

        interactor.estimateFee(for: inputAmount)
    }
}

extension StakingBondMoreConfirmationPresenter: StakingBondMoreConfirmationPresenterProtocol {
    func setup() {
        provideConfirmationViewModel()
        provideAssetViewModel()
        provideFeeViewModel()

        interactor.setup()
    }

    func confirm() {
        let locale = view?.localizationManager?.selectedLocale ?? Locale.current
        DataValidationRunner(validators: [
            dataValidatingFactory.has(fee: fee, locale: locale, onError: { [weak self] in
                self?.refreshFeeIfNeeded()
            }),

            dataValidatingFactory.canPayFeeAndAmount(
                balance: balance,
                fee: fee,
                spendingAmount: inputAmount,
                locale: locale
            ),

            dataValidatingFactory.has(
                stash: stashAccount?.chainAccount,
                for: stashItem?.stash ?? "",
                locale: locale
            )
        ]).runValidation { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.view?.didStartLoading()

            strongSelf.interactor.submit(for: strongSelf.inputAmount)
        }
    }

    func selectAccount() {
        guard let view = view, let address = stashItem?.controller else { return }

        let locale = view.localizationManager?.selectedLocale ?? Locale.current

        wireframe.presentAccountOptions(
            from: view,
            address: address,
            explorers: explorers,
            locale: locale
        )
    }
}

extension StakingBondMoreConfirmationPresenter: StakingBondMoreConfirmationOutputProtocol {
    func didReceiveAccountInfo(result: Result<AccountInfo?, Error>) {
        switch result {
        case let .success(accountInfo):
            if let accountInfo = accountInfo {
                balance = Decimal.fromSubstrateAmount(
                    accountInfo.data.available,
                    precision: assetInfo.assetPrecision
                )
            } else {
                balance = nil
            }

            provideAssetViewModel()
            provideConfirmationViewModel()
        case let .failure(error):
            logger?.error("Did receive account info error: \(error)")
        }
    }

    func didReceivePriceData(result: Result<PriceData?, Error>) {
        switch result {
        case let .success(priceData):
            self.priceData = priceData

            provideAssetViewModel()
            provideFeeViewModel()
            provideConfirmationViewModel()
        case let .failure(error):
            logger?.error("Did receive price data error: \(error)")
        }
    }

    func didReceiveFee(result: Result<RuntimeDispatchInfo, Error>) {
        switch result {
        case let .success(dispatchInfo):
            if let feeValue = BigUInt(dispatchInfo.fee) {
                fee = Decimal.fromSubstrateAmount(feeValue, precision: assetInfo.assetPrecision)
            } else {
                fee = nil
            }

            provideFeeViewModel()
        case let .failure(error):
            logger?.error("Did receive fee error: \(error)")
        }
    }

    func didReceiveStash(result: Result<MetaChainAccountResponse?, Error>) {
        switch result {
        case let .success(stashAccount):
            self.stashAccount = stashAccount

            provideConfirmationViewModel()

            refreshFeeIfNeeded()
        case let .failure(error):
            logger?.error("Did receive stash account error: \(error)")
        }
    }

    func didReceiveStashItem(result: Result<StashItem?, Error>) {
        switch result {
        case let .success(stashItem):
            self.stashItem = stashItem
        case let .failure(error):
            logger?.error("Did receive stash item error: \(error)")
        }
    }

    func didSubmitBonding(result: Result<String, Error>) {
        view?.didStopLoading()

        guard let view = view else {
            return
        }

        switch result {
        case .success:
            wireframe.complete(from: view)
        case .failure:
            wireframe.presentExtrinsicFailed(from: view, locale: view.localizationManager?.selectedLocale)
        }
    }
}
