import Testing
@testable import DelamainStorage

@Suite("StorageKey Tests")
struct StorageKeyTests {

    @Test("Creates key with raw value")
    func createsKeyWithRawValue() {
        let key = StorageKey<String>("testKey")
        #expect(key.rawValue == "testKey")
    }

    @Test("Creates key from string literal")
    func createsKeyFromStringLiteral() {
        let key: StorageKey<String> = "literalKey"
        #expect(key.rawValue == "literalKey")
    }

    @Test("Keys with same value are equal")
    func keysWithSameValueAreEqual() {
        let key1 = StorageKey<String>("same")
        let key2 = StorageKey<String>("same")
        #expect(key1 == key2)
    }

    @Test("Keys with different values are not equal")
    func keysWithDifferentValuesAreNotEqual() {
        let key1 = StorageKey<String>("one")
        let key2 = StorageKey<String>("two")
        #expect(key1 != key2)
    }

    @Test("Key is hashable")
    func keyIsHashable() {
        let key = StorageKey<Int>("number")
        var set: Set<StorageKey<Int>> = []
        set.insert(key)
        #expect(set.contains(key))
    }
}
