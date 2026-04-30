import XCTest
@testable import MacTextEditor

final class KeychainHelperTests: XCTestCase {
    let account = "test_api_key_\(UUID().uuidString)"

    override func tearDown() {
        super.tearDown()
        KeychainHelper.delete(account: account)
    }

    func test_save_and_load() {
        KeychainHelper.save("sk-test-123", account: account)
        XCTAssertEqual(KeychainHelper.load(account: account), "sk-test-123")
    }

    func test_load_missing_returns_nil() {
        XCTAssertNil(KeychainHelper.load(account: "nonexistent_\(UUID().uuidString)"))
    }

    func test_overwrite() {
        KeychainHelper.save("first", account: account)
        KeychainHelper.save("second", account: account)
        XCTAssertEqual(KeychainHelper.load(account: account), "second")
    }

    func test_delete() {
        KeychainHelper.save("value", account: account)
        KeychainHelper.delete(account: account)
        XCTAssertNil(KeychainHelper.load(account: account))
    }
}
