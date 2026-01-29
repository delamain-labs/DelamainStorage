import Testing
import Foundation
@testable import DelamainStorage

@Suite("FileStorage Tests", .serialized)
struct FileStorageTests {

    // Each test gets its own unique directory
    private func makeStorage() throws -> (FileStorage, URL) {
        let testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DelamainStorageTests")
            .appendingPathComponent(UUID().uuidString)
        let storage = try FileStorage(directory: testDir)
        return (storage, testDir)
    }

    private func cleanup(directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Basic Operations

    @Test("Sets and gets a string value")
    func setsAndGetsString() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.set("hello", forKey: "greeting")
        let value: String? = try await storage.get("greeting")
        #expect(value == "hello")
    }

    @Test("Sets and gets an integer value")
    func setsAndGetsInteger() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.set(42, forKey: "number")
        let value: Int? = try await storage.get("number")
        #expect(value == 42)
    }

    @Test("Gets nil for missing key")
    func getsNilForMissingKey() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        let value: String? = try await storage.get("nonexistent")
        #expect(value == nil)
    }

    @Test("Overwrites existing value")
    func overwritesExistingValue() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.set("first", forKey: "key")
        try await storage.set("second", forKey: "key")
        let value: String? = try await storage.get("key")
        #expect(value == "second")
    }

    // MARK: - Remove

    @Test("Removes a value")
    func removesValue() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.set("value", forKey: "key")
        try await storage.remove("key")
        let value: String? = try await storage.get("key")
        #expect(value == nil)
    }

    @Test("Remove does not throw for missing key")
    func removeDoesNotThrowForMissingKey() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.remove("nonexistent")
        // Should not throw
    }

    // MARK: - Contains

    @Test("Contains returns true for existing key")
    func containsReturnsTrueForExistingKey() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.set("value", forKey: "key")
        let exists = try await storage.contains("key")
        #expect(exists == true)
    }

    @Test("Contains returns false for missing key")
    func containsReturnsFalseForMissingKey() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        let exists = try await storage.contains("nonexistent")
        #expect(exists == false)
    }

    // MARK: - Clear

    @Test("Clear removes all values")
    func clearRemovesAllValues() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

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

        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        let user = User(id: 1, name: "John")
        try await storage.set(user, forKey: "user")

        let retrieved: User? = try await storage.get("user")
        #expect(retrieved == user)
    }

    @Test("Stores and retrieves an array")
    func storesAndRetrievesArray() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        let numbers = [1, 2, 3, 4, 5]
        try await storage.set(numbers, forKey: "numbers")

        let retrieved: [Int]? = try await storage.get("numbers")
        #expect(retrieved == numbers)
    }

    @Test("Stores and retrieves large data")
    func storesAndRetrievesLargeData() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        // Create a large array (1MB+)
        let largeArray = Array(repeating: "x", count: 100_000)
        try await storage.set(largeArray, forKey: "large")

        let retrieved: [String]? = try await storage.get("large")
        #expect(retrieved?.count == 100_000)
    }

    // MARK: - Type-Safe Keys

    @Test("Works with type-safe keys")
    func worksWithTypeSafeKeys() async throws {
        let usernameKey = StorageKey<String>("username")

        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        try await storage.set("john_doe", for: usernameKey)

        let username = try await storage.get(usernameKey)
        #expect(username == "john_doe")
    }

    // MARK: - Directory Locations

    @Test("Creates directory using SearchPathDirectory")
    func createsDirectoryUsingSearchPath() async throws {
        let storage = try FileStorage(
            searchPath: .cachesDirectory,
            subdirectory: "DelamainStorageTests/\(UUID().uuidString)"
        )
        let testKey = "test_\(UUID().uuidString)"
        defer { Task { try? await storage.clear() } }

        try await storage.set("cached", forKey: testKey)
        let value: String? = try await storage.get(testKey)
        #expect(value == "cached")
    }

    // MARK: - File Extension

    @Test("Uses custom file extension")
    func usesCustomFileExtension() async throws {
        let testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DelamainStorageTests")
            .appendingPathComponent(UUID().uuidString)
        defer { cleanup(directory: testDir) }

        let storage = try FileStorage(directory: testDir, fileExtension: "json")
        try await storage.set("test", forKey: "myfile")

        // Verify file was created with correct extension
        let filePath = testDir.appendingPathComponent("myfile.json")
        #expect(FileManager.default.fileExists(atPath: filePath.path))
    }

    // MARK: - Thread Safety

    @Test("Handles concurrent writes safely")
    func handlesConcurrentWritesSafely() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

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

    // MARK: - Key Sanitization

    @Test("Handles keys with special characters")
    func handlesKeysWithSpecialCharacters() async throws {
        let (storage, dir) = try makeStorage()
        defer { cleanup(directory: dir) }

        // Keys that might be problematic for file systems
        let specialKeys = [
            "key/with/slashes",
            "key:with:colons",
            "key with spaces",
            "key.with.dots"
        ]

        for (index, key) in specialKeys.enumerated() {
            try await storage.set(index, forKey: key)
            let value: Int? = try await storage.get(key)
            #expect(value == index, "Failed for key: \(key)")
        }
    }
}
