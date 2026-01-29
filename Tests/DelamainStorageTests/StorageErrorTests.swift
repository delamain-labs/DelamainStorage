import Testing
@testable import DelamainStorage

@Suite("StorageError Tests")
struct StorageErrorTests {

    @Test("Encoding failed error has description")
    func encodingFailedHasDescription() {
        let error = StorageError.encodingFailed("Invalid data")
        #expect(error.errorDescription?.contains("Encoding failed") == true)
        #expect(error.errorDescription?.contains("Invalid data") == true)
    }

    @Test("Decoding failed error has description")
    func decodingFailedHasDescription() {
        let error = StorageError.decodingFailed("Corrupt data")
        #expect(error.errorDescription?.contains("Decoding failed") == true)
        #expect(error.errorDescription?.contains("Corrupt data") == true)
    }

    @Test("File operation failed error has description")
    func fileOperationFailedHasDescription() {
        let error = StorageError.fileOperationFailed("Permission denied")
        #expect(error.errorDescription?.contains("File operation failed") == true)
        #expect(error.errorDescription?.contains("Permission denied") == true)
    }

    @Test("Keychain error has description")
    func keychainErrorHasDescription() {
        let error = StorageError.keychainError(-25293)
        #expect(error.errorDescription?.contains("Keychain error") == true)
        #expect(error.errorDescription?.contains("-25293") == true)
    }

    @Test("Storage unavailable error has description")
    func storageUnavailableHasDescription() {
        let error = StorageError.storageUnavailable("No access")
        #expect(error.errorDescription?.contains("Storage unavailable") == true)
    }

    @Test("Unknown error has description")
    func unknownErrorHasDescription() {
        let error = StorageError.unknown("Something went wrong")
        #expect(error.errorDescription?.contains("Unknown error") == true)
    }

    @Test("Errors are equatable")
    func errorsAreEquatable() {
        let error1 = StorageError.encodingFailed("test")
        let error2 = StorageError.encodingFailed("test")
        let error3 = StorageError.decodingFailed("test")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}
