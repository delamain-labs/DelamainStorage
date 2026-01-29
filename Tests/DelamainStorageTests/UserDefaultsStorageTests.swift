import Testing
import Foundation
@testable import DelamainStorage

@Suite("UserDefaultsStorage Tests", .serialized)
struct UserDefaultsStorageTests {

    // Each test gets its own unique suite to avoid conflicts
    private func makeStorage() -> (UserDefaultsStorage, String) {
        let suiteName = "com.delamain.storage.tests.\(UUID().uuidString)"
        return (UserDefaultsStorage(suiteName: suiteName), suiteName)
    }

    private func cleanup(suiteName: String) {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Basic Operations

    @Test("Sets and gets a string value")
    func setsAndGetsString() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set("hello", forKey: "greeting")
        let value: String? = try await storage.get("greeting")
        #expect(value == "hello")
    }

    @Test("Sets and gets an integer value")
    func setsAndGetsInteger() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set(42, forKey: "number")
        let value: Int? = try await storage.get("number")
        #expect(value == 42)
    }

    @Test("Sets and gets a boolean value")
    func setsAndGetsBoolean() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set(true, forKey: "flag")
        let value: Bool? = try await storage.get("flag")
        #expect(value == true)
    }

    @Test("Sets and gets a double value")
    func setsAndGetsDouble() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set(3.14159, forKey: "pi")
        let value: Double? = try await storage.get("pi")
        #expect(value == 3.14159)
    }

    @Test("Gets nil for missing key")
    func getsNilForMissingKey() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        let value: String? = try await storage.get("nonexistent")
        #expect(value == nil)
    }

    @Test("Overwrites existing value")
    func overwritesExistingValue() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set("first", forKey: "key")
        try await storage.set("second", forKey: "key")
        let value: String? = try await storage.get("key")
        #expect(value == "second")
    }

    // MARK: - Remove

    @Test("Removes a value")
    func removesValue() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set("value", forKey: "key")
        try await storage.remove("key")
        let value: String? = try await storage.get("key")
        #expect(value == nil)
    }

    @Test("Remove does not throw for missing key")
    func removeDoesNotThrowForMissingKey() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.remove("nonexistent")
        // Should not throw
    }

    // MARK: - Contains

    @Test("Contains returns true for existing key")
    func containsReturnsTrueForExistingKey() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set("value", forKey: "key")
        let exists = try await storage.contains("key")
        #expect(exists == true)
    }

    @Test("Contains returns false for missing key")
    func containsReturnsFalseForMissingKey() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        let exists = try await storage.contains("nonexistent")
        #expect(exists == false)
    }

    // MARK: - Clear

    @Test("Clear removes all values")
    func clearRemovesAllValues() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

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
        struct User: Codable, Sendable, Equatable {
            let id: Int
            let name: String
        }

        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        let user = User(id: 1, name: "John")
        try await storage.set(user, forKey: "user")

        let retrieved: User? = try await storage.get("user")
        #expect(retrieved == user)
    }

    @Test("Stores and retrieves an array")
    func storesAndRetrievesArray() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        let numbers = [1, 2, 3, 4, 5]
        try await storage.set(numbers, forKey: "numbers")

        let retrieved: [Int]? = try await storage.get("numbers")
        #expect(retrieved == numbers)
    }

    @Test("Stores and retrieves a dictionary")
    func storesAndRetrievesDictionary() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        let data = ["a": 1, "b": 2, "c": 3]
        try await storage.set(data, forKey: "dict")

        let retrieved: [String: Int]? = try await storage.get("dict")
        #expect(retrieved == data)
    }

    @Test("Stores and retrieves a date")
    func storesAndRetrievesDate() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        let date = Date(timeIntervalSince1970: 1000000)
        try await storage.set(date, forKey: "date")

        let retrieved: Date? = try await storage.get("date")
        #expect(retrieved == date)
    }

    // MARK: - Type-Safe Keys

    @Test("Works with type-safe keys")
    func worksWithTypeSafeKeys() async throws {
        let usernameKey = StorageKey<String>("username")

        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        try await storage.set("john_doe", for: usernameKey)

        let username = try await storage.get(usernameKey)
        #expect(username == "john_doe")
    }

    // MARK: - Standard UserDefaults

    @Test("Uses standard defaults when no suite specified")
    func usesStandardDefaultsWhenNoSuiteSpecified() async throws {
        let storage = UserDefaultsStorage()
        let testKey = "test_standard_\(UUID().uuidString)"
        defer { Task { try? await storage.remove(testKey) } }

        try await storage.set("standard", forKey: testKey)
        let value: String? = try await storage.get(testKey)
        #expect(value == "standard")
    }

    // MARK: - Thread Safety

    @Test("Handles concurrent writes safely")
    func handlesConcurrentWritesSafely() async throws {
        let (storage, suiteName) = makeStorage()
        defer { cleanup(suiteName: suiteName) }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    try? await storage.set(i, forKey: "counter-\(i)")
                }
            }
        }

        // Verify all values were stored
        for i in 0..<50 {
            let value: Int? = try await storage.get("counter-\(i)")
            #expect(value == i)
        }
    }
}
