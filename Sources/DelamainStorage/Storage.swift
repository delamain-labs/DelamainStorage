// MARK: - Storage Protocol

/// A type-safe storage interface for persisting data.
///
/// All implementations are actor-isolated to ensure thread safety.
///
/// Example:
/// ```swift
/// let storage = UserDefaultsStorage()
/// try await storage.set("John", forKey: "username")
/// let name: String? = try await storage.get("username")
/// ```
public protocol Storage: Sendable {
    /// Stores a value for the given key.
    /// - Parameters:
    ///   - value: The value to store. Must be Codable and Sendable.
    ///   - key: The key to associate with the value.
    /// - Throws: `StorageError` if the operation fails.
    func set<T: Codable & Sendable>(_ value: T, forKey key: String) async throws

    /// Retrieves a value for the given key.
    /// - Parameter key: The key to look up.
    /// - Returns: The stored value, or nil if not found.
    /// - Throws: `StorageError` if the operation fails (other than not found).
    func get<T: Codable & Sendable>(_ key: String) async throws -> T?

    /// Removes the value for the given key.
    /// - Parameter key: The key to remove.
    /// - Throws: `StorageError` if the operation fails.
    func remove(_ key: String) async throws

    /// Checks if a value exists for the given key.
    /// - Parameter key: The key to check.
    /// - Returns: True if a value exists, false otherwise.
    func contains(_ key: String) async throws -> Bool

    /// Removes all stored values.
    /// - Throws: `StorageError` if the operation fails.
    func clear() async throws
}

// MARK: - Default Implementations

public extension Storage {
    /// Stores a value using a type-safe key.
    func set<T: Codable & Sendable>(_ value: T, for key: StorageKey<T>) async throws {
        try await set(value, forKey: key.rawValue)
    }

    /// Retrieves a value using a type-safe key.
    func get<T: Codable & Sendable>(_ key: StorageKey<T>) async throws -> T? {
        try await get(key.rawValue)
    }

    /// Removes the value for a type-safe key.
    func remove<T>(_ key: StorageKey<T>) async throws {
        try await remove(key.rawValue)
    }

    /// Checks if a value exists for a type-safe key.
    func contains<T>(_ key: StorageKey<T>) async throws -> Bool {
        try await contains(key.rawValue)
    }
}
