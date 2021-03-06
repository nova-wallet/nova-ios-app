final class ValidatorSearchWireframe: ValidatorSearchWireframeProtocol {
    let state: StakingSharedState

    init(state: StakingSharedState) {
        self.state = state
    }

    func present(
        _ validatorInfo: ValidatorInfoProtocol,
        from view: ControllerBackedProtocol?
    ) {
        guard let validatorInfoView = ValidatorInfoViewFactory.createView(
            with: validatorInfo,
            state: state
        ) else {
            return
        }

        view?.controller.navigationController?.pushViewController(
            validatorInfoView.controller,
            animated: true
        )
    }

    func close(_ view: ControllerBackedProtocol?) {
        view?.controller.navigationController?.popViewController(animated: true)
    }
}
