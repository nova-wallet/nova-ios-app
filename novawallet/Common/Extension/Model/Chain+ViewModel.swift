import UIKit

extension Chain {
    func titleForLocale(_: Locale) -> String {
        switch self {
        case .polkadot:
            return "Polkadot"
        case .kusama:
            return "Kusama"
        case .westend:
            return "Westend"
        case .rococo:
            return "Rococo"
        }
    }

    var icon: UIImage? {
        switch self {
        case .polkadot:
            return R.image.iconPolkadotSmallBg()
        case .kusama:
            return R.image.iconKsmSmallBg()
        case .westend:
            return R.image.iconWestendSmallBg()
        case .rococo:
            return R.image.iconKsmSmallBg()
        }
    }
}
