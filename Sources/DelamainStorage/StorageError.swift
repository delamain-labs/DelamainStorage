import Foundation

// MARK: - Storage Error

/// Errors that can occur during storage operations.
public enum StorageError: Error, Sendable, Equatable {
    /// The data could not be encoded for storage.
    case encodingFailed(String)

    /// The stored data could not be decoded.
    case decodingFailed(String)

    /// A file system operation failed.
    case fileOperationFailed(String)

    /// A keychain operation failed with the given status.
    case keychainError(Int32)

    /// The storage is not available (e.g., no app group access).
    case storageUnavailable(String)

    /// An unknown error occurred.
    case unknown(String)
}

// MARK: - LocalizedError

extension StorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "Encoding failed: \(message)"
        case .decodingFailed(let message):
            return "Decoding failed: \(message)"
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .storageUnavailable(let message):
            return "Storage unavailable: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
