import Foundation
import Security

// MARK: - KeychainStorage

/// An actor-isolated storage backend using the iOS/macOS Keychain.
///
/// `KeychainStorage` securely stores sensitive data using the system keychain.
/// Ideal for:
/// - Authentication tokens and API keys
/// - User credentials
/// - Encryption keys
/// - Any sensitive data that should persist securely
///
/// Data stored in the keychain persists across app reinstalls (unless explicitly deleted)
/// and is encrypted at the hardware level.
///
/// Example:
/// ```swift
/// let storage = KeychainStorage(service: "com.example.app")
///
/// // Store a token
/// try await storage.set("bearer_token_xyz", forKey: "authToken")
///
/// // Retrieve it later
/// let token: String? = try await storage.get("authToken")
/// ```
public actor KeychainStorage: Storage {

    // MARK: - Properties

    private let service: String
    private let accessGroup: String?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    /// Creates keychain storage with a service identifier.
    ///
    /// - Parameters:
    ///   - service: The service identifier (typically your bundle identifier).
    ///   - accessGroup: Optional access group for sharing between apps.
    public init(service: String? = nil, accessGroup: String? = nil) {
        self.service = service ?? Bundle.main.bundleIdentifier ?? "com.delamain.storage"
        self.accessGroup = accessGroup
    }

    // MARK: - Storage Protocol

    public func set<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        let data: Data
        do {
            data = try encoder.encode(value)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }

        // Build the query
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data

        // Try to add the item
        var status = SecItemAdd(query as CFDictionary, nil)

        // If it already exists, update it
        if status == errSecDuplicateItem {
            let updateQuery = baseQuery(for: key)
            let updateAttributes: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }

        guard status == errSecSuccess else {
            throw StorageError.keychainError(status)
        }
    }

    public func get<T: Codable & Sendable>(_ key: String) async throws -> T? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw StorageError.keychainError(status)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }

    public func remove(_ key: String) async throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        // It's okay if the item doesn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StorageError.keychainError(status)
        }
    }

    public func contains(_ key: String) async throws -> Bool {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = false

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func clear() async throws {
        // Delete all items matching the service
        // Note: SecItemDelete removes ALL matching items, no limit needed
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Keep deleting until no more items exist
        var status = SecItemDelete(query as CFDictionary)
        while status == errSecSuccess {
            status = SecItemDelete(query as CFDictionary)
        }

        // It's okay if no items exist
        guard status == errSecItemNotFound else {
            throw StorageError.keychainError(status)
        }
    }

    // MARK: - Helper Methods

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}
