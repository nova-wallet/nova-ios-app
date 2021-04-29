import RobinHood
import IrohaCrypto

final class StakingBalanceInteractor {
    weak var presenter: StakingBalanceInteractorOutputProtocol!

    let chain: Chain
    let accountAddress: AccountAddress
    let accountRepository: AnyDataProviderRepository<AccountItem>
    let runtimeCodingService: RuntimeCodingServiceProtocol
    let chainStorage: AnyDataProviderRepository<ChainStorageItem>
    let localStorageRequestFactory: LocalStorageRequestFactoryProtocol
    let operationManager: OperationManagerProtocol
    let priceProvider: AnySingleValueProvider<PriceData>
    let providerFactory: SingleValueProviderFactoryProtocol
    let substrateProviderFactory: SubstrateDataProviderFactoryProtocol

    var activeEraProvider: AnyDataProvider<DecodedActiveEra>?
    var electionStatusProvider: AnyDataProvider<DecodedElectionStatus>?
    var stashControllerProvider: StreamableProvider<StashItem>?
    var ledgerProvider: AnyDataProvider<DecodedLedgerInfo>?

    init(
        chain: Chain,
        accountAddress: AccountAddress,
        accountRepository: AnyDataProviderRepository<AccountItem>,
        runtimeCodingService: RuntimeCodingServiceProtocol,
        chainStorage: AnyDataProviderRepository<ChainStorageItem>,
        localStorageRequestFactory: LocalStorageRequestFactoryProtocol,
        priceProvider: AnySingleValueProvider<PriceData>,
        providerFactory: SingleValueProviderFactoryProtocol,
        substrateProviderFactory: SubstrateDataProviderFactoryProtocol,
        operationManager: OperationManagerProtocol
    ) {
        self.chain = chain
        self.accountAddress = accountAddress
        self.accountRepository = accountRepository
        self.runtimeCodingService = runtimeCodingService
        self.chainStorage = chainStorage
        self.localStorageRequestFactory = localStorageRequestFactory
        self.priceProvider = priceProvider
        self.providerFactory = providerFactory
        self.substrateProviderFactory = substrateProviderFactory
        self.operationManager = operationManager
    }

    func fetchController(for address: AccountAddress) {
        let operation = accountRepository.fetchOperation(by: address, options: RepositoryFetchOptions())

        operation.completionBlock = {
            DispatchQueue.main.async {
                do {
                    let accountItem = try operation.extractNoCancellableResultData()
                    self.presenter.didReceive(fetchControllerResult: .success((accountItem, address)))
                } catch {
                    self.presenter.didReceive(fetchControllerResult: .failure(error))
                }
            }
        }

        operationManager.enqueue(operations: [operation], in: .transient)
    }
}

extension StakingBalanceInteractor: StakingBalanceInteractorInputProtocol {
    func setup() {
        subscribeToPriceChanges()
        subscribeToElectionStatus()
        subsribeToActiveEra()
        subscribeToStashControllerProvider()
    }
}