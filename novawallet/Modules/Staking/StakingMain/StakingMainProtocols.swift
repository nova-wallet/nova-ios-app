import Foundation
import SoraFoundation
import CommonWallet
import BigInt

protocol StakingMainViewProtocol: ControllerBackedProtocol, Localizable {
    func didReceive(viewModel: StakingMainViewModel)
    func didRecieveNetworkStakingInfo(viewModel: LocalizableResource<NetworkStakingInfoViewModel>?)
    func didReceiveStakingState(viewModel: StakingViewState)
    func expandNetworkInfoView(_ isExpanded: Bool)
}

protocol StakingMainPresenterProtocol: AnyObject {
    func setup()
    func performAssetSelection()
    func performMainAction()
    func performAccountAction()
    func performRewardInfoAction()
    func performChangeValidatorsAction()
    func performSetupValidatorsForBondedAction()
    func performStakeMoreAction()
    func performRedeemAction()
    func performRebondAction()
    func performAnalyticsAction()
    func networkInfoViewDidChangeExpansion(isExpanded: Bool)
    func performManageAction(_ action: StakingManageOption)
}

protocol StakingMainInteractorInputProtocol: AnyObject {
    func setup()
    func saveNetworkInfoViewExpansion(isExpanded: Bool)
    func save(chainAsset: ChainAsset)
}

protocol StakingMainInteractorOutputProtocol: AnyObject {
    func didReceive(selectedAddress: String)
    func didReceive(price: PriceData?)
    func didReceive(priceError: Error)
    func didReceive(totalReward: TotalRewardItem)
    func didReceive(totalRewardError: Error)
    func didReceive(accountInfo: AccountInfo?)
    func didReceive(balanceError: Error)
    func didReceive(calculator: RewardCalculatorEngineProtocol)
    func didReceive(calculatorError: Error)
    func didReceive(stashItem: StashItem?)
    func didReceive(stashItemError: Error)
    func didReceive(ledgerInfo: StakingLedger?)
    func didReceive(ledgerInfoError: Error)
    func didReceive(nomination: Nomination?)
    func didReceive(nominationError: Error)
    func didReceive(validatorPrefs: ValidatorPrefs?)
    func didReceive(validatorError: Error)
    func didReceive(eraStakersInfo: EraStakersInfo)
    func didReceive(eraStakersInfoError: Error)
    func didReceive(networkStakingInfo: NetworkStakingInfo)
    func didReceive(networkStakingInfoError: Error)
    func didReceive(payee: RewardDestinationArg?)
    func didReceive(payeeError: Error)
    func didReceive(newChainAsset: ChainAsset)
    func didReceieve(subqueryRewards: Result<[SubqueryRewardItemData]?, Error>, period: AnalyticsPeriod)
    func didReceiveMinNominatorBond(result: Result<BigUInt?, Error>)
    func didReceiveCounterForNominators(result: Result<UInt32?, Error>)
    func didReceiveMaxNominatorsCount(result: Result<UInt32?, Error>)
    func didReceive(eraCountdownResult: Result<EraCountdown, Error>)

    func didReceiveMaxNominatorsPerValidator(result: Result<UInt32, Error>)

    func didReceiveAccount(_ account: MetaChainAccountResponse?, for accountId: AccountId)
    func networkInfoViewExpansion(isExpanded: Bool)
}

protocol StakingMainWireframeProtocol: AlertPresentable, ErrorPresentable, StakingErrorPresentable {
    func showSetupAmount(from view: StakingMainViewProtocol?)

    func proceedToSelectValidatorsStart(
        from view: StakingMainViewProtocol?,
        existingBonding: ExistingBonding
    )

    func showRewardDetails(from view: ControllerBackedProtocol?, maxReward: Decimal, avgReward: Decimal)

    func showRewardPayoutsForNominator(from view: ControllerBackedProtocol?, stashAddress: AccountAddress)
    func showRewardPayoutsForValidator(from view: ControllerBackedProtocol?, stashAddress: AccountAddress)
    func showNominatorValidators(from view: ControllerBackedProtocol?)
    func showRewardDestination(from view: ControllerBackedProtocol?)
    func showControllerAccount(from view: ControllerBackedProtocol?)

    func showAccountsSelection(from view: StakingMainViewProtocol?)
    func showBondMore(from view: ControllerBackedProtocol?)
    func showUnbond(from view: ControllerBackedProtocol?)
    func showRedeem(from view: ControllerBackedProtocol?)
    func showRebond(from view: ControllerBackedProtocol?, option: StakingRebondOption)
    func showAnalytics(from view: ControllerBackedProtocol?, mode: AnalyticsContainerViewMode)

    func showYourValidatorInfo(_ stashAddress: AccountAddress, from view: ControllerBackedProtocol?)

    func showChainAssetSelection(
        from view: StakingMainViewProtocol?,
        selectedChainAssetId: ChainAssetId?,
        delegate: AssetSelectionDelegate
    )
}

protocol StakingMainViewFactoryProtocol: AnyObject {
    static func createView() -> StakingMainViewProtocol?
}
