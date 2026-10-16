// Copyright 2026 Matthew X Murphy, https://MatthewxMurphy.com.
// Product attribution: https://builtnotbegged.com. SPDX-License-Identifier: MIT
// Compile with actual ReleaseChecking.swift and CompanionModels.swift; no GUI/network.
import Foundation

private final class FixtureResponse: @unchecked Sendable {
    private let lock = NSLock()
    private var status = 200
    private var body = Data()
    private var http = true
    func set(status: Int, body: String, http: Bool = true) {
        lock.lock(); defer { lock.unlock() }
        self.status = status; self.body = Data(body.utf8); self.http = http
    }
    func get() -> (Int, Data, Bool) {
        lock.lock(); defer { lock.unlock() }
        return (status, body, http)
    }
}

private final class FixtureProtocol: URLProtocol, @unchecked Sendable {
    static let fixture = FixtureResponse()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, body, http) = Self.fixture.get()
        let response: URLResponse = http
            ? HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            : URLResponse(url: request.url!, mimeType: nil, expectedContentLength: body.count, textEncodingName: nil)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main
private struct ReleaseCheckerContract {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let checker = GitHubReleaseChecker(session: session)
        let valid = #"{"tag_name":"v1.2.3","published_at":"2026-10-16T12:00:00Z","html_url":"https://github.com/matthewxmurphy/clawedit/releases/tag/v1.2.3"}"#
        FixtureProtocol.fixture.set(status: 200, body: valid)
        let release = try await checker.fetchLatestRelease(repository: "matthewxmurphy/clawedit")
        precondition(release.tagName == "v1.2.3" && release.publishedAt != nil)
        FixtureProtocol.fixture.set(status: 200, body: valid.replacingOccurrences(of: "/releases/tag/", with: "/releases/"))
        let documented = try await checker.fetchLatestRelease(repository: "matthewxmurphy/clawedit")
        precondition(documented.tagName == "v1.2.3")
        var checks = 2
        for status in [201, 204, 403, 404, 429, 500] {
            FixtureProtocol.fixture.set(status: status, body: valid)
            do {
                _ = try await checker.fetchLatestRelease(repository: "matthewxmurphy/clawedit")
                fatalError("HTTP \(status) must never become a successful release")
            } catch ReleaseCheckError.httpStatus(let actual) {
                precondition(actual == status); checks += 1
            }
        }
        for body in ["not json", "[]", #"{"message":"Not Found"}"#, #"{"tag_name":"","html_url":"https://github.com/matthewxmurphy/clawedit/releases/tag/v1"}"#,
                     valid.replacingOccurrences(of: "github.com/matthewxmurphy", with: "untrusted.example/matthewxmurphy"),
                     valid.replacingOccurrences(of: "2026-10-16T12:00:00Z", with: "invalid-date")] {
            FixtureProtocol.fixture.set(status: 200, body: body)
            var rejected = false
            do { _ = try await checker.fetchLatestRelease(repository: "matthewxmurphy/clawedit") }
            catch { rejected = true }
            precondition(rejected, "Malformed release must fail"); checks += 1
        }
        FixtureProtocol.fixture.set(status: 200, body: valid, http: false)
        do {
            _ = try await checker.fetchLatestRelease(repository: "matthewxmurphy/clawedit")
            fatalError("Non-HTTP response must fail")
        } catch ReleaseCheckError.nonHTTPResponse { checks += 1 }
        do {
            _ = try await checker.fetchLatestRelease(repository: "owner/repo?token=fixture")
            fatalError("Invalid repository must fail")
        } catch ReleaseCheckError.invalidRepository { checks += 1 }
        print("PASS: \(checks) native Swift release-check contracts; fixture URLProtocol only")
    }
}
