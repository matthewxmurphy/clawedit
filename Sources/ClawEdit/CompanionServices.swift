import Foundation

enum CompanionPaths {
    static let bundleID = "com.matthewxmurphy.clawedit"

    static var appSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("ClawEdit", isDirectory: true)
    }

    static var exportedConfigURL: URL {
        appSupportDirectory.appendingPathComponent("bridge-config.json")
    }

    static var persistedStateURL: URL {
        appSupportDirectory.appendingPathComponent("companion-state.json")
    }
}

enum CompanionStorage {
    static func ensureDirectories() throws {
        try FileManager.default.createDirectory(
            at: CompanionPaths.appSupportDirectory,
            withIntermediateDirectories: true
        )
    }

    static func loadCapabilities() -> [CapabilityState]? {
        guard let data = try? Data(contentsOf: CompanionPaths.persistedStateURL) else {
            return nil
        }
        return try? CodableFactory.decoder.decode([CapabilityState].self, from: data)
    }

    static func saveCapabilities(_ capabilities: [CapabilityState]) throws {
        try ensureDirectories()
        let data = try CodableFactory.encoder.encode(capabilities)
        try data.write(to: CompanionPaths.persistedStateURL, options: .atomic)
    }

    static func exportConfiguration(_ configuration: CompanionConfiguration) throws {
        try ensureDirectories()
        let data = try CodableFactory.encoder.encode(configuration)
        try data.write(to: CompanionPaths.exportedConfigURL, options: .atomic)
    }
}

enum CodableFactory {
    static var encoder: Foundation.JSONEncoder {
        let encoder = Foundation.JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static var decoder: Foundation.JSONDecoder {
        let decoder = Foundation.JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

actor GitHubReleaseChecker {
    func fetchLatestRelease(repository: String) async throws -> ReleaseInfo {
        let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ClawEdit", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        let isoFormatter = ISO8601DateFormatter()
        return ReleaseInfo(
            tagName: payload["tag_name"] as? String ?? "unknown",
            publishedAt: (payload["published_at"] as? String).flatMap(isoFormatter.date(from:)),
            htmlURL: payload["html_url"] as? String ?? "https://github.com/\(repository)/releases"
        )
    }
}

@MainActor
final class CompanionViewModel: ObservableObject {
    @Published var identity = AppIdentity.matthew
    @Published var preferredGatewayHost = "192.168.88.11"
    @Published var preferredGatewayPort = 18789
    @Published var capabilities: [CapabilityState] = CompanionViewModel.defaultCapabilities
    @Published var lastExportPath = CompanionPaths.exportedConfigURL.path
    @Published var lastExportStatus = "Not exported yet."
    @Published var latestReleaseText = "Not checked yet."
    @Published var latestReleaseURL = ""
    @Published var updateCheckInFlight = false

    private let releaseChecker = GitHubReleaseChecker()

    static let defaultCapabilities: [CapabilityState] = [
        CapabilityState(key: .iMessage, isEnabled: false, statusNote: "Needs Full Disk Access and Messages data access.", requiredPermission: "Full Disk Access"),
        CapabilityState(key: .reminders, isEnabled: false, statusNote: "Needs Reminders access approval.", requiredPermission: "Reminders"),
        CapabilityState(key: .notes, isEnabled: false, statusNote: "Needs Notes or Apple Events access depending on the integration path.", requiredPermission: "Automation"),
        CapabilityState(key: .homebrewBridge, isEnabled: true, statusNote: "Expose /opt/homebrew/bin tools to Linux wrappers after local approval.", requiredPermission: nil),
        CapabilityState(key: .wakeOnLan, isEnabled: true, statusNote: "Enable magic-packet wake + retry for sleeping Mac nodes.", requiredPermission: nil),
        CapabilityState(key: .keepAwake, isEnabled: false, statusNote: "Recommended during work windows so OpenClaw jobs do not stall on sleep.", requiredPermission: nil)
    ]

    init() {
        if let persisted = CompanionStorage.loadCapabilities(), !persisted.isEmpty {
            capabilities = persisted
        }
    }

    func toggle(_ capability: CapabilityKey, enabled: Bool) {
        guard let index = capabilities.firstIndex(where: { $0.key == capability }) else {
            return
        }
        capabilities[index].isEnabled = enabled
        persist()
    }

    func exportConfiguration() {
        let configuration = CompanionConfiguration(
            identity: identity,
            githubReleasesURL: "https://github.com/\(identity.repository)/releases",
            exportedAt: Date(),
            capabilities: capabilities,
            preferredGatewayHost: preferredGatewayHost,
            preferredGatewayPort: preferredGatewayPort,
            supportWebsite: identity.website,
            supportEmail: identity.email
        )

        do {
            try CompanionStorage.exportConfiguration(configuration)
            lastExportPath = CompanionPaths.exportedConfigURL.path
            lastExportStatus = "Exported bridge config to \(lastExportPath)"
            persist()
        } catch {
            lastExportStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    func checkForUpdates() async {
        updateCheckInFlight = true
        defer { updateCheckInFlight = false }

        do {
            let release = try await releaseChecker.fetchLatestRelease(repository: identity.repository)
            latestReleaseText = "Latest GitHub release: \(release.tagName)"
            latestReleaseURL = release.htmlURL
        } catch {
            latestReleaseText = "Update check failed: \(error.localizedDescription)"
        }
    }

    private func persist() {
        do {
            try CompanionStorage.saveCapabilities(capabilities)
        } catch {
            lastExportStatus = "State save failed: \(error.localizedDescription)"
        }
    }
}
