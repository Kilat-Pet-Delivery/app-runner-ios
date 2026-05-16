import Foundation
import Security

protocol TokenStore {
    func saveAccessToken(_ token: String) throws
    func accessToken() -> String?
    func saveRefreshToken(_ token: String) throws
    func refreshToken() -> String?
    func clear()
}

final class KeychainStore: TokenStore {
    private enum TokenKey: String {
        case accessToken
        case refreshToken
    }

    private let serviceIdentifier: String

    init(serviceIdentifier: String = Bundle.main.bundleIdentifier ?? "my.kilat.KilatRunner") {
        self.serviceIdentifier = serviceIdentifier
    }

    func saveAccessToken(_ token: String) throws {
        try save(token, for: .accessToken)
    }

    func accessToken() -> String? {
        read(.accessToken)
    }

    func saveRefreshToken(_ token: String) throws {
        try save(token, for: .refreshToken)
    }

    func refreshToken() -> String? {
        read(.refreshToken)
    }

    func clear() {
        delete(.accessToken)
        delete(.refreshToken)
    }

    private func save(_ token: String, for key: TokenKey) throws {
        guard let data = token.data(using: .utf8) else {
            throw NetworkError.encodingFailed("Token was not valid UTF-8.")
        }

        delete(key)

        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NetworkError.unknown("Could not save credentials.")
        }
    }

    private func read(_ key: TokenKey) -> String? {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func delete(_ key: TokenKey) {
        SecItemDelete(baseQuery(for: key) as CFDictionary)
    }

    private func baseQuery(for key: TokenKey) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: key.rawValue
        ]
    }
}
