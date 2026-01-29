# DelamainStorage Roadmap

This document outlines planned features and improvements for DelamainStorage.

## ✅ v1.0.0 (In Progress)

### Core Features
- [x] Storage protocol with async/await API
- [x] Type-safe storage keys (StorageKey<T>)
- [x] Full Sendable/actor isolation
- [x] StorageError with LocalizedError conformance
- [x] CI/CD pipeline (build, test, lint)

### Storage Backends
- [x] **InMemoryStorage** — Fast temporary storage for testing/caching
- [x] **UserDefaultsStorage** — Standard preferences storage with suite support
- [ ] **FileStorage** — File-based persistence *(up next)*
- [ ] **KeychainStorage** — Secure credential storage

### Quality
- [x] Comprehensive test coverage (45 tests)
- [x] Documentation and examples
- [x] SwiftLint integration

---

## v1.1.0 (Next)

### Enhancements
- [ ] **Storage migration** — Version your stored data and migrate
- [ ] **Expiration** — TTL support for cached values
- [ ] **Observation** — Combine/AsyncSequence publishers for changes
- [ ] **Batch operations** — Set/get multiple values efficiently

### New Backends
- [ ] **CoreDataStorage** — Managed object wrapper
- [ ] **SQLiteStorage** — Direct SQLite with type safety

## v1.2.0 (Future)

### Advanced Features
- [ ] **Encryption** — At-rest encryption for file storage
- [ ] **Compression** — Reduce storage size for large objects
- [ ] **Sync** — CloudKit integration for cross-device sync
- [ ] **DelamainLogger integration** — Storage operation logging

### Developer Experience
- [ ] **Property wrappers** — @Stored, @SecureStored, @Cached
- [ ] **SwiftUI integration** — @AppStorage-like wrappers

---

## Contributing

Want to help? Check our [issues](https://github.com/delamain-labs/DelamainStorage/issues) or open a discussion for new feature ideas.

## Related Packages

- [DelamainCore](https://github.com/delamain-labs/DelamainCore) — Shared utilities and extensions
- [DelamainNetworking](https://github.com/delamain-labs/DelamainNetworking) — Async networking with retries
- [DelamainLogger](https://github.com/delamain-labs/DelamainLogger) — Logging framework

---

*Last updated: 2026-01-29*
