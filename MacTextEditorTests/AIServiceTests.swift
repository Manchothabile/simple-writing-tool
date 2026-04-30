import XCTest
@testable import MacTextEditor

final class AIServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        super.tearDown()
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.responseData = nil
        MockURLProtocol.responseError = nil
        MockURLProtocol.statusCode = 200
    }

    func test_successful_response() async throws {
        MockURLProtocol.responseData = """
        {"content":[{"type":"text","text":"Corrected text"}],"id":"msg_1","model":"claude-3-5-haiku-20241022","role":"assistant","stop_reason":"end_turn","type":"message","usage":{"input_tokens":10,"output_tokens":5}}
        """.data(using: .utf8)

        let session = URLSession(configuration: mockConfiguration())
        let result = try await AIService.perform(.corriger, on: "Some text", apiKey: "sk-test", session: session)
        XCTAssertEqual(result, "Corrected text")
    }

    func test_invalid_api_key_throws() async {
        MockURLProtocol.statusCode = 401
        MockURLProtocol.responseData = "{}".data(using: .utf8)

        let session = URLSession(configuration: mockConfiguration())
        do {
            _ = try await AIService.perform(.corriger, on: "text", apiKey: "bad-key", session: session)
            XCTFail("Expected throw")
        } catch AIError.invalidAPIKey {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func test_network_error_throws() async {
        MockURLProtocol.responseError = URLError(.notConnectedToInternet)

        let session = URLSession(configuration: mockConfiguration())
        do {
            _ = try await AIService.perform(.corriger, on: "text", apiKey: "sk-test", session: session)
            XCTFail("Expected throw")
        } catch AIError.networkError {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func test_all_actions_have_system_prompts() {
        for action in AIAction.allCases {
            XCTAssertFalse(action.systemPrompt.isEmpty, "\(action) has empty system prompt")
        }
    }

    private func mockConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}

// MARK: - MockURLProtocol

final class MockURLProtocol: URLProtocol {
    static var responseData: Data?
    static var responseError: Error?
    static var statusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = MockURLProtocol.responseError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: MockURLProtocol.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = MockURLProtocol.responseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
