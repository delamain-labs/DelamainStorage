import Foundation

// MARK: - InMemoryStorage

/// An actor-isolated in-memory storage backend.
///
/// `InMemoryStorage` provides fast, temporary storage that does not persist
/// across app launches. Ideal for:
/// - Testing and mocking
/// - Caching frequently accessed data
/// - Storing session-scoped state
///
/// All data is lost when the storage instance is deallocated.
///
/// Example:
/// ```swift
/// let storage = InMemoryStorage()
/// try await storage.set("John", forKey: "username")
/// let name: String? = try await storage.get("username")
/// ```
public actor InMemoryStorage: Storage {

    // MARK: - Properties

    private var store: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    /// Creates a new in-memory storage instance.
    public init() {}

    // MARK: - Storage Protocol

    public func set<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        do {
            let data = try encoder.encode(value)
            store[key] = data
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }

    public func get<T: Codable & Sendable>(_ key: String) async throws -> T? {
        guard let data = store[key] else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }

    public func remove(_ key: String) async throws {
        store.removeValue(forKey: key)
    }

    public func contains(_ key: String) async throws -> Bool {
        store[key] != nil
    }

    public func clear() async throws {
        store.removeAll()
    }

    // MARK: - Additional Methods

    /// Returns the number of stored items.
    public var count: Int {
        store.count
    }

    /// Returns all keys in the storage.
    public var keys: [String] {
        Array(store.keys)
    }
}
