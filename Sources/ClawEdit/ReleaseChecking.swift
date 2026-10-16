// Copyright 2026 Matthew X Murphy, https://MatthewxMurphy.com.
// Product attribution: https://builtnotbegged.com. SPDX-License-Identifier: MIT
import Foundation

/// Validated GitHub responses only. HTTP errors are failures, never release data.
enum ReleaseCheckError: LocalizedError {
    case invalidRepository
    case nonHTTPResponse
    case httpStatus(Int)
    case invalidRelease

    var errorDescription: String? {
        switch self {
        case .invalidRepository: return "The GitHub repository must use owner/name."
        case .nonHTTPResponse: return "GitHub did not return an HTTP response."
        case .httpStatus(let status): return "GitHub release lookup failed (HTTP \(status))."
        case .invalidRelease: return "GitHub returned incomplete or invalid release information."
        }
    }
}

actor GitHubReleaseChecker {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLatestRelease(repository: String) async throws -> ReleaseInfo {
        guard repository.range(of: #"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil,
              let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest") else {
            throw ReleaseCheckError.invalidRepository
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ClawEdit", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ReleaseCheckError.nonHTTPResponse
        }
        guard http.statusCode == 200 else {
            throw ReleaseCheckError.httpStatus(http.statusCode)
        }
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = payload["tag_name"] as? String,
              !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let html = payload["html_url"] as? String,
              let releaseURL = URLComponents(string: html),
              releaseURL.scheme == "https", releaseURL.host == "github.com",
              releaseURL.user == nil, releaseURL.password == nil, releaseURL.port == nil,
              releaseURL.path.lowercased().hasPrefix("/\(repository.lowercased())/releases/"),
              releaseURL.path.count > "/\(repository)/releases/".count else {
            throw ReleaseCheckError.invalidRelease
        }
        let isoFormatter = ISO8601DateFormatter()
        var publishedAt: Date?
        if let rawDate = payload["published_at"], !(rawDate is NSNull) {
            guard let text = rawDate as? String, let date = isoFormatter.date(from: text) else {
                throw ReleaseCheckError.invalidRelease
            }
            publishedAt = date
        }
        return ReleaseInfo(tagName: tag, publishedAt: publishedAt, htmlURL: html)
    }
}
