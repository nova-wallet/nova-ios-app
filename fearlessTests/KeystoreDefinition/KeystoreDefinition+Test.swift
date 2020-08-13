import Foundation
import FearlessUtils

extension KeystoreDefinition {
    static var validURL: URL {
        Bundle(for: RootTests.self).url(forResource: "validKeystore", withExtension: "json")!
    }

    static var invalidURL: URL {
        Bundle(for: RootTests.self).url(forResource: "invalidKeystore", withExtension: "json")!
    }

    static func loadValidDefinition() throws -> KeystoreDefinition {
        let data = try Data(contentsOf: validURL)
        let keystoreDefinition = try JSONDecoder().decode(KeystoreDefinition.self, from: data)
        return keystoreDefinition
    }
}
