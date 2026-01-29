// MARK: - Storage Key

/// A type-safe key for storage operations.
///
/// Use static properties to define your keys:
/// ```swift
/// extension StorageKey {
///     static let username = StorageKey<String>("username")
///     static let settings = StorageKey<AppSettings>("settings")
/// }
///
/// // Usage
/// try await storage.set("John", for: .username)
/// let name = try await storage.get(.username)
/// ```
public struct StorageKey<Value: Codable & Sendable>: Sendable, Hashable {
    /// The raw string key used for storage.
    public let rawValue: String

    /// Creates a new storage key.
    /// - Parameter rawValue: The string key to use for storage.
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension StorageKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
