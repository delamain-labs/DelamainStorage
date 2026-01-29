import Testing
@testable import DelamainStorage

@Suite("InMemoryStorage Tests")
struct InMemoryStorageTests {

    // MARK: - Basic Operations

    @Test("Sets and gets a string value")
    func setsAndGetsString() async throws {
        let storage = InMemoryStorage()
        try await storage.set("hello", forKey: "greeting")
        let value: String? = try await storage.get("greeting")
        #expect(value == "hello")
    }

    @Test("Sets and gets an integer value")
    func setsAndGetsInteger() async throws {
        let storage = InMemoryStorage()
        try await storage.set(42, forKey: "number")
        let value: Int? = try await storage.get("number")
        #expect(value == 42)
    }

    @Test("Gets nil for missing key")
    func getsNilForMissingKey() async throws {
        let storage = InMemoryStorage()
        let value: String? = try await storage.get("nonexistent")
        #expect(value == nil)
    }

    @Test("Overwrites existing value")
    func overwritesExistingValue() async throws {
        let storage = InMemoryStorage()
        try await storage.set("first", forKey: "key")
        try await storage.set("second", forKey: "key")
        let value: String? = try await storage.get("key")
        #expect(value == "second")
    }

    // MARK: - Remove

    @Test("Removes a value")
    func removesValue() async throws {
        let storage = InMemoryStorage()
        try await storage.set("value", forKey: "key")
        try await storage.remove("key")
        let value: String? = try await storage.get("key")
        #expect(value == nil)
    }

    @Test("Remove does not throw for missing key")
    func removeDoesNotThrowForMissingKey() async throws {
        let storage = InMemoryStorage()
        try await storage.remove("nonexistent")
        // Should not throw
    }

    // MARK: - Contains

    @Test("Contains returns true for existing key")
    func containsReturnsTrueForExistingKey() async throws {
        let storage = InMemoryStorage()
        try await storage.set("value", forKey: "key")
        let exists = try await storage.contains("key")
        #expect(exists == true)
    }

    @Test("Contains returns false for missing key")
    func containsReturnsFalseForMissingKey() async throws {
        let storage = InMemoryStorage()
        let exists = try await storage.contains("nonexistent")
        #expect(exists == false)
    }

    // MARK: - Clear

    @Test("Clear removes all values")
    func clearRemovesAllValues() async throws {
        let storage = InMemoryStorage()
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

        let storage = InMemoryStorage()
        let user = User(id: 1, name: "John")
        try await storage.set(user, forKey: "user")

        let retrieved: User? = try await storage.get("user")
        #expect(retrieved == user)
    }

    @Test("Stores and retrieves an array")
    func storesAndRetrievesArray() async throws {
        let storage = InMemoryStorage()
        let numbers = [1, 2, 3, 4, 5]
        try await storage.set(numbers, forKey: "numbers")

        let retrieved: [Int]? = try await storage.get("numbers")
        #expect(retrieved == numbers)
    }

    @Test("Stores and retrieves a dictionary")
    func storesAndRetrievesDictionary() async throws {
        let storage = InMemoryStorage()
        let data = ["a": 1, "b": 2, "c": 3]
        try await storage.set(data, forKey: "dict")

        let retrieved: [String: Int]? = try await storage.get("dict")
        #expect(retrieved == data)
    }

    // MARK: - Type-Safe Keys

    @Test("Works with type-safe keys")
    func worksWithTypeSafeKeys() async throws {
        let usernameKey = StorageKey<String>("username")

        let storage = InMemoryStorage()
        try await storage.set("john_doe", for: usernameKey)

        let username = try await storage.get(usernameKey)
        #expect(username == "john_doe")
    }

    // MARK: - Thread Safety

    @Test("Handles concurrent writes safely")
    func handlesConcurrentWritesSafely() async throws {
        let storage = InMemoryStorage()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    try? await storage.set(i, forKey: "counter-\(i)")
                }
            }
        }

        // Verify all values were stored
        for i in 0..<100 {
            let value: Int? = try await storage.get("counter-\(i)")
            #expect(value == i)
        }
    }

    @Test("Handles concurrent reads and writes safely")
    func handlesConcurrentReadsAndWritesSafely() async throws {
        let storage = InMemoryStorage()
        try await storage.set(0, forKey: "shared")

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    try? await storage.set(i, forKey: "shared")
                }
                group.addTask {
                    let _: Int? = try? await storage.get("shared")
                }
            }
        }

        // Should complete without crashes
        let finalValue: Int? = try await storage.get("shared")
        #expect(finalValue != nil)
    }
}
