import Foundation

// MARK: - FileStorage

/// An actor-isolated file-based storage backend.
///
/// `FileStorage` persists data as individual files in a directory. Suitable for:
/// - Larger objects that don't fit well in UserDefaults
/// - Data that benefits from file-level access (backup, sharing)
/// - Caches that should persist across launches
///
/// Example:
/// ```swift
/// // Use documents directory
/// let storage = try FileStorage(searchPath: .documentDirectory, subdirectory: "MyApp")
///
/// // Use custom directory
/// let storage = try FileStorage(directory: customURL)
///
/// try await storage.set(largeObject, forKey: "data")
/// let data: LargeObject? = try await storage.get("data")
/// ```
public actor FileStorage: Storage {

    // MARK: - Properties

    private let directory: URL
    private let fileExtension: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default

    // MARK: - Initialization

    /// Creates file storage at a specific directory.
    ///
    /// - Parameters:
    ///   - directory: The directory URL to store files.
    ///   - fileExtension: The file extension for stored files (default: "data").
    /// - Throws: `StorageError` if the directory cannot be created.
    public init(directory: URL, fileExtension: String = "data") throws {
        self.directory = directory
        self.fileExtension = fileExtension

        // Create directory if needed
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw StorageError.fileOperationFailed("Failed to create directory: \(error.localizedDescription)")
            }
        }
    }

    /// Creates file storage using a system search path.
    ///
    /// - Parameters:
    ///   - searchPath: The system directory to use (e.g., .documentDirectory, .cachesDirectory).
    ///   - subdirectory: Optional subdirectory within the search path.
    ///   - fileExtension: The file extension for stored files (default: "data").
    /// - Throws: `StorageError` if the directory cannot be created.
    public init(
        searchPath: FileManager.SearchPathDirectory,
        subdirectory: String? = nil,
        fileExtension: String = "data"
    ) throws {
        guard let baseURL = FileManager.default.urls(for: searchPath, in: .userDomainMask).first else {
            throw StorageError.storageUnavailable("Could not access \(searchPath)")
        }

        var directory = baseURL
        if let subdirectory {
            directory = baseURL.appendingPathComponent(subdirectory)
        }

        try self.init(directory: directory, fileExtension: fileExtension)
    }

    // MARK: - Storage Protocol

    public func set<T: Codable & Sendable>(_ value: T, forKey key: String) async throws {
        let fileURL = fileURL(for: key)

        do {
            let data = try encoder.encode(value)
            try data.write(to: fileURL, options: .atomic)
        } catch let error as EncodingError {
            throw StorageError.encodingFailed(error.localizedDescription)
        } catch {
            throw StorageError.fileOperationFailed("Failed to write file: \(error.localizedDescription)")
        }
    }

    public func get<T: Codable & Sendable>(_ key: String) async throws -> T? {
        let fileURL = fileURL(for: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw StorageError.decodingFailed(error.localizedDescription)
        } catch {
            throw StorageError.fileOperationFailed("Failed to read file: \(error.localizedDescription)")
        }
    }

    public func remove(_ key: String) async throws {
        let fileURL = fileURL(for: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return // No-op if file doesn't exist
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw StorageError.fileOperationFailed("Failed to remove file: \(error.localizedDescription)")
        }
    }

    public func contains(_ key: String) async throws -> Bool {
        let fileURL = fileURL(for: key)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    public func clear() async throws {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )

            for fileURL in contents where fileURL.pathExtension == fileExtension {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            throw StorageError.fileOperationFailed("Failed to clear storage: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func fileURL(for key: String) -> URL {
        let sanitizedKey = sanitizeKey(key)
        return directory.appendingPathComponent("\(sanitizedKey).\(fileExtension)")
    }

    private func sanitizeKey(_ key: String) -> String {
        // Replace characters that are problematic for file systems
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return key
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
    }

    // MARK: - Additional Methods

    /// Returns all keys currently stored.
    public var keys: [String] {
        get throws {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )

            return contents
                .filter { $0.pathExtension == fileExtension }
                .map { $0.deletingPathExtension().lastPathComponent }
        }
    }

    /// Returns the total size of stored files in bytes.
    public var totalSize: Int {
        get throws {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.fileSizeKey]
            )

            return try contents
                .filter { $0.pathExtension == fileExtension }
                .reduce(0) { total, url in
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    return total + size
                }
        }
    }

    /// The directory URL where files are stored.
    public var storageDirectory: URL {
        directory
    }
}
