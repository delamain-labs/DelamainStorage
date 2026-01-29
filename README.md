# DelamainStorage

Type-safe local data persistence for Swift 6.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20watchOS%2010%20|%20tvOS%2017%20|%20visionOS%201-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Async/await native** — Built for structured concurrency
- **Type-safe** — Compile-time guarantees for your data
- **Multiple backends** — UserDefaults, File, Keychain, In-Memory
- **Actor-isolated** — Thread-safe operations by default
- **Codable support** — Store any Encodable/Decodable type
- **Swift 6 ready** — Full Sendable compliance

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/delamain-labs/DelamainStorage.git", from: "1.0.0")
]
```

Or in Xcode: File → Add Packages → Enter the repository URL.

## Quick Start

```swift
import DelamainStorage

// Store a value
let storage = UserDefaultsStorage()
try await storage.set("John", forKey: "username")

// Retrieve a value
let username: String? = try await storage.get("username")

// Delete a value
try await storage.remove("username")
```

## Storage Backends

### UserDefaultsStorage

Standard UserDefaults wrapper with type safety.

```swift
let storage = UserDefaultsStorage()
let storage = UserDefaultsStorage(suiteName: "group.com.example.app")
```

### FileStorage

File-based storage for larger objects.

```swift
let storage = try FileStorage(directory: .documents)
let storage = try FileStorage(directory: .caches)
let storage = try FileStorage(url: customURL)
```

### KeychainStorage

Secure storage for sensitive data.

```swift
let storage = KeychainStorage()
let storage = KeychainStorage(service: "com.example.app")
```

### InMemoryStorage

Fast, temporary storage for testing or caching.

```swift
let storage = InMemoryStorage()
```

## Type-Safe Keys

Define strongly-typed keys for compile-time safety:

```swift
extension StorageKey {
    static let username = StorageKey<String>("username")
    static let authToken = StorageKey<String>("authToken")
    static let settings = StorageKey<AppSettings>("settings")
}

// Usage
try await storage.set("John", for: .username)
let name = try await storage.get(.username)
```

## Storing Complex Types

Any `Codable` type works automatically:

```swift
struct User: Codable, Sendable {
    let id: UUID
    let name: String
    let email: String
}

let user = User(id: UUID(), name: "John", email: "john@example.com")
try await storage.set(user, forKey: "currentUser")

let saved: User? = try await storage.get("currentUser")
```

## Thread Safety

All storage backends are actor-isolated:

```swift
// Safe from any context
await withTaskGroup(of: Void.self) { group in
    for i in 0..<100 {
        group.addTask {
            try? await storage.set(i, forKey: "counter-\(i)")
        }
    }
}
```

## Requirements

- Swift 6.0+
- iOS 17.0+ / macOS 14.0+ / watchOS 10.0+ / tvOS 17.0+ / visionOS 1.0+

## License

MIT License. See [LICENSE](LICENSE) for details.

## Part of Delamain Labs

This package is part of the Delamain Swift ecosystem:

- [DelamainCore](https://github.com/delamain-labs/DelamainCore) - Core utilities
- [DelamainNetworking](https://github.com/delamain-labs/DelamainNetworking) - Async networking
- [DelamainLogger](https://github.com/delamain-labs/DelamainLogger) - Logging framework
- **DelamainStorage** - Local data persistence ← You are here
