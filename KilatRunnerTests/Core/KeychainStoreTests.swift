import XCTest
@testable import KilatRunner

final class KeychainStoreTests: XCTestCase {
    private var store: KeychainStore!

    override func setUp() {
        super.setUp()
        store = KeychainStore(serviceIdentifier: "my.kilat.KilatRunner.tests.\(UUID().uuidString)")
        store.clear()
    }

    override func tearDown() {
        store.clear()
        store = nil
        super.tearDown()
    }

    func test_saveAndReadAccessToken_returnsSameValue() throws {
        try store.saveAccessToken("access-token")

        XCTAssertEqual(store.accessToken(), "access-token")
    }

    func test_saveAndReadRefreshToken_returnsSameValue() throws {
        try store.saveRefreshToken("refresh-token")

        XCTAssertEqual(store.refreshToken(), "refresh-token")
    }

    func test_overwriteToken_returnsNewValue() throws {
        try store.saveAccessToken("old-token")
        try store.saveAccessToken("new-token")

        XCTAssertEqual(store.accessToken(), "new-token")
    }

    func test_clear_removesBothTokens() throws {
        try store.saveAccessToken("access-token")
        try store.saveRefreshToken("refresh-token")

        store.clear()

        XCTAssertNil(store.accessToken())
        XCTAssertNil(store.refreshToken())
    }

    func test_readUnsetToken_returnsNil() {
        XCTAssertNil(store.accessToken())
        XCTAssertNil(store.refreshToken())
    }
}
