import Testing
import Foundation
import Security
@testable import DelamainStorage

/// Keychain tests require system keychain access, which may not be available in all environments.
/// These tests are designed to gracefully handle restricted environments.
@Suite("KeychainStorage Tests", .serialized)
struct KeychainStorageTests {

    // Check if keychain is accessible in this environment
    private static func isKeychainAccessible() -> Bool {
        let testKey = "com.delamain.storage.keychain.test.\(UUID().uuidString)"
        let testData = Data("test".utf8)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.delamain.storage.test",
            kSecAttrAccount as String: testKey,
            kSecValueData as String: testData
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

        if addStatus == errSecSuccess || addStatus == errSecDuplicateItem {
            // Clean up
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.delamain.storage.test",
                kSecAttrAccount as String: testKey
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            return true
        }

        return false
    }

    // Each test uses a unique service to avoid conflicts
    private func makeStorage() -> (KeychainStorage, String) {
        let service = "com.delamain.storage.tests.\(UUID().uuidString)"
        return (KeychainStorage(service: service), service)
    }

    // MARK: - Basic Operations

    @Test("Sets and gets a string value")
    func setsAndGetsString() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        try await storage.set("secret", forKey: "password")
        let value: String? = try await storage.get("password")
        #expect(value == "secret")
    }

    @Test("Sets and gets an integer value")
    func setsAndGetsInteger() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        try await storage.set(12345, forKey: "pin")
        let value: Int? = try await storage.get("pin")
        #expect(value == 12345)
    }

    @Test("Gets nil for missing key")
    func getsNilForMissingKey() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        let value: String? = try await storage.get("nonexistent")
        #expect(value == nil)
    }

    @Test("Overwrites existing value")
    func overwritesExistingValue() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        try await storage.set("first", forKey: "key")
        try await storage.set("second", forKey: "key")
        let value: String? = try await storage.get("key")
        #expect(value == "second")
    }

    // MARK: - Remove

    @Test("Removes a value")
    func removesValue() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        try await storage.set("value", forKey: "key")
        try await storage.remove("key")
        let value: String? = try await storage.get("key")
        #expect(value == nil)
    }

    @Test("Remove does not throw for missing key")
    func removeDoesNotThrowForMissingKey() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        try await storage.remove("nonexistent")
        // Should not throw
    }

    // MARK: - Contains

    @Test("Contains returns true for existing key")
    func containsReturnsTrueForExistingKey() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        try await storage.set("value", forKey: "key")
        let exists = try await storage.contains("key")
        #expect(exists == true)
    }

    @Test("Contains returns false for missing key")
    func containsReturnsFalseForMissingKey() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        let exists = try await storage.contains("nonexistent")
        #expect(exists == false)
    }

    // MARK: - Clear

    @Test("Clear removes all values")
    func clearRemovesAllValues() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()

        try await storage.set("one", forKey: "key1")
        try await storage.set("two", forKey: "key2")
        try await storage.set("three", forKey: "key3")

        try await storage.clear()

        let value1: String? = try await storage.get("key1")
        let value2: String? = try await storage.get("key2")
        let value3: String? = try await storage.get("key3")

        #expect(value1 == nil)
        #expect(value2 == nil)
        #expect(value3 == nil)
    }

    // MARK: - Complex Types

    @Test("Stores and retrieves a codable struct")
    func storesAndRetrievesCodableStruct() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        struct Credentials: Codable, Sendable, Equatable {
            let username: String
            let token: String
        }

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        let creds = Credentials(username: "john", token: "abc123")
        try await storage.set(creds, forKey: "credentials")

        let retrieved: Credentials? = try await storage.get("credentials")
        #expect(retrieved == creds)
    }

    @Test("Stores and retrieves an array")
    func storesAndRetrievesArray() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        let tokens = ["token1", "token2", "token3"]
        try await storage.set(tokens, forKey: "tokens")

        let retrieved: [String]? = try await storage.get("tokens")
        #expect(retrieved == tokens)
    }

    // MARK: - Type-Safe Keys

    @Test("Works with type-safe keys")
    func worksWithTypeSafeKeys() async throws {
        try #require(Self.isKeychainAccessible(), "Keychain not accessible in this environment")

        let authTokenKey = StorageKey<String>("authToken")

        let (storage, _) = makeStorage()
        defer { Task { try? await storage.clear() } }

        try await storage.set("bearer_xyz", for: authTokenKey)

        let token = try await storage.get(authTokenKey)
        #expect(token == "bearer_xyz")
    }

    // MARK: - Initialization

    @Test("Initializes with default service")
    func initializesWithDefaultService() async throws {
        // Just verify it can be created
        let storage = KeychainStorage()
        _ = storage
    }

    @Test("Initializes with custom service")
    func initializesWithCustomService() async throws {
        let storage = KeychainStorage(service: "com.example.test")
        _ = storage
    }

    @Test("Initializes with access group")
    func initializesWithAccessGroup() async throws {
        // Note: Access groups require entitlements, so we just verify initialization works
        let storage = KeychainStorage(service: "test", accessGroup: "com.example.shared")
        _ = storage
    }
}
