// DelamainStorage
// Type-safe local data persistence for Swift 6.

/// DelamainStorage provides a unified, type-safe interface for local data persistence.
///
/// ## Overview
///
/// DelamainStorage offers multiple storage backends with a consistent async/await API:
/// - `UserDefaultsStorage` - Standard preferences storage
/// - `FileStorage` - File-based persistence for larger objects
/// - `KeychainStorage` - Secure storage for sensitive data
/// - `InMemoryStorage` - Fast temporary storage for testing/caching
///
/// ## Quick Start
///
/// ```swift
/// import DelamainStorage
///
/// let storage = UserDefaultsStorage()
///
/// // Store a value
/// try await storage.set("John", forKey: "username")
///
/// // Retrieve a value
/// let name: String? = try await storage.get("username")
///
/// // Use type-safe keys
/// extension StorageKey {
///     static let username = StorageKey<String>("username")
/// }
/// try await storage.set("John", for: .username)
/// ```
///
/// ## Thread Safety
///
/// All storage backends are actor-isolated, making them safe to use from any context.
public enum DelamainStorage {
    /// The current version of DelamainStorage.
    public static let version = "1.0.0"
}
