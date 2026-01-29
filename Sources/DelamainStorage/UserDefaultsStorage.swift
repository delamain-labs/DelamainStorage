import Foundation

// MARK: - UserDefaultsStorage

/// An actor-isolated storage backend using UserDefaults.
///
/// `UserDefaultsStorage` wraps UserDefaults with type-safe async operations.
/// Data persists across app launches and is suitable for:
/// - User preferences and settings
/// - Small configuration data
/// - Feature flags
///
/// For sensitive data, use `KeychainStorage` instead.
///
/// Example:
/// ```swift
/// // Use standard defaults
/// let storage = UserDefaultsStorage()
///
/// // Use app group defaults
/// let storage = UserDefaultsStorage(suiteName: "group.com.example.app")
///
/// try await storage.set("John", forKey: "username")
/// let name: String? = try await storage.get("username")
/// ```
public actor UserDefaultsStorage: Storage {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let suiteName: String?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    /// Creates a storage using standard UserDefaults.
    public init() {
        self.defaults = .standard
        self.suiteName = nil
    }

    /// Creates a storage using a UserDefaults suite.
    ///
    /// - Parameter suiteName: The suite name (e.g., app group identifier).
    ///   If nil or the suite cannot be created, falls back to standard defaults.
    public init(suiteName: String?) {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            self.defaults = suite
            self.suiteName = suiteName
        } else {
            self.defaults = .standard
            self.suiteName = nil
        }
    }

    // MARK: - Storage Protocol

    public func set<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }

    public func get<T: Codable & Sendable>(_ key: String) async throws -> T? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }

    public func remove(_ key: String) async throws {
        defaults.removeObject(forKey: key)
    }

    public func contains(_ key: String) async throws -> Bool {
        defaults.object(forKey: key) != nil
    }

    public func clear() async throws {
        if let suiteName {
            // Remove all keys from the suite
            defaults.removePersistentDomain(forName: suiteName)
        } else {
            // For standard defaults, remove keys registered by this app
            let domain = Bundle.main.bundleIdentifier ?? "unknown"
            defaults.removePersistentDomain(forName: domain)
        }
        defaults.synchronize()
    }

    // MARK: - Additional Methods

    /// Synchronizes any pending changes to disk.
    ///
    /// UserDefaults automatically synchronizes periodically, but you can
    /// call this method to force an immediate write.
    public func synchronize() {
        defaults.synchronize()
    }
}
