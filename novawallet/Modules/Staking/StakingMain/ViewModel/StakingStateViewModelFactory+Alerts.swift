import Foundation
import SoraFoundation

extension StakingStateViewModelFactory {
    func stakingAlertsForNominatorState(_ state: NominatorState) -> [StakingAlert] {
        [
            findInactiveAlert(state: state),
            findRedeemUnbondedAlert(commonData: state.commonData, ledgerInfo: state.ledgerInfo),
            findWaitingNextEraAlert(nominationStatus: state.status)
        ].compactMap { $0 }
    }

    func stakingAlertsForValidatorState(_ state: ValidatorState) -> [StakingAlert] {
        [
            findRedeemUnbondedAlert(commonData: state.commonData, ledgerInfo: state.ledgerInfo)
        ].compactMap { $0 }
    }

    func stakingAlertsForBondedState(_ state: BondedState) -> [StakingAlert] {
        [
            findMinNominatorBondAlert(state: state),
            .bondedSetValidators,
            findRedeemUnbondedAlert(commonData: state.commonData, ledgerInfo: state.ledgerInfo)
        ].compactMap { $0 }
    }

    func stakingAlertsNoStashState(_: NoStashState) -> [StakingAlert] {
        []
    }

    private func findRedeemUnbondedAlert(
        commonData: StakingStateCommonData,
        ledgerInfo: StakingLedger
    ) -> StakingAlert? {
        guard
            let era = commonData.eraStakersInfo?.activeEra,
            let precision = commonData.chainAsset?.assetDisplayInfo.assetPrecision,
            let redeemable = Decimal.fromSubstrateAmount(
                ledgerInfo.redeemable(inEra: era),
                precision: precision
            ),
            redeemable > 0,
            let redeemableAmount = balanceViewModelFactory?.amountFromValue(redeemable)
        else { return nil }

        let localizedString = LocalizableResource<String> { locale in
            redeemableAmount.value(for: locale)
        }
        return .redeemUnbonded(localizedString)
    }

    private func findMinNominatorBondAlert(state: BondedState) -> StakingAlert? {
        let commonData = state.commonData
        let ledgerInfo = state.ledgerInfo

        guard let minStake = commonData.minStake else {
            return nil
        }

        guard ledgerInfo.active < minStake else {
            return nil
        }

        guard
            let chainAsset = commonData.chainAsset,
            let minActiveDecimal = Decimal.fromSubstrateAmount(
                minStake,
                precision: chainAsset.assetDisplayInfo.assetPrecision
            ),
            let minActiveAmount = balanceViewModelFactory?.amountFromValue(minActiveDecimal)
        else {
            return nil
        }

        let localizedString = LocalizableResource<String> { locale in
            R.string.localizable.stakingInactiveCurrentMinimalStake(
                minActiveAmount.value(for: locale),
                preferredLanguages: locale.rLanguages
            )
        }

        return .nominatorLowStake(localizedString)
    }

    private func findInactiveAlert(state: NominatorState) -> StakingAlert? {
        guard case .inactive = state.status else { return nil }

        let commonData = state.commonData
        let ledgerInfo = state.ledgerInfo

        guard let minStake = commonData.minStake else {
            return nil
        }

        if ledgerInfo.active < minStake {
            guard
                let chainAsset = commonData.chainAsset,
                let minActiveDecimal = Decimal.fromSubstrateAmount(
                    minStake,
                    precision: chainAsset.assetDisplayInfo.assetPrecision
                ),
                let minActiveAmount = balanceViewModelFactory?.amountFromValue(minActiveDecimal)
            else {
                return nil
            }

            let localizedString = LocalizableResource<String> { locale in
                R.string.localizable.stakingInactiveCurrentMinimalStake(
                    minActiveAmount.value(for: locale),
                    preferredLanguages: locale.rLanguages
                )
            }
            return .nominatorLowStake(localizedString)
        } else if state.allValidatorsWithoutReward {
            return .nominatorAllOversubscribed
        } else {
            return .nominatorChangeValidators
        }
    }

    private func findWaitingNextEraAlert(nominationStatus: NominationViewStatus) -> StakingAlert? {
        if case NominationViewStatus.waiting = nominationStatus {
            return .waitingNextEra
        }
        return nil
    }
}
