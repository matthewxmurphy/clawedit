import Foundation

struct AppIdentity: Codable {
    let ownerName: String
    let website: String
    let email: String
    let repository: String
    let license: String
    let unsignedDistribution: Bool

    static let matthew = AppIdentity(
        ownerName: "Matthew Murphy",
        website: "https://www.matthewxmurphy.com",
        email: "hello@matthewxmurphy.com",
        repository: "matthewxmurphy/clawedit",
        license: "MIT",
        unsignedDistribution: true
    )
}

enum CapabilityKey: String, CaseIterable, Codable, Identifiable {
    case iMessage
    case reminders
    case notes
    case homebrewBridge
    case wakeOnLan
    case keepAwake

    var id: String { rawValue }

    var title: String {
        switch self {
        case .iMessage: return "iMessage"
        case .reminders: return "Reminders"
        case .notes: return "Notes"
        case .homebrewBridge: return "Homebrew Bridge"
        case .wakeOnLan: return "Wake-on-LAN"
        case .keepAwake: return "Keep Awake"
        }
    }

    var subtitle: String {
        switch self {
        case .iMessage:
            return "Prepare Mac-backed iMessage access for the gateway."
        case .reminders:
            return "Prepare Reminders access and export bridge metadata."
        case .notes:
            return "Prepare Notes access and bridge metadata."
        case .homebrewBridge:
            return "Expose Homebrew-backed CLI tools to Linux wrappers."
        case .wakeOnLan:
            return "Allow sleeping Mac nodes to be woken before wrapper retries."
        case .keepAwake:
            return "Keep the Mac available during work windows."
        }
    }
}

struct CapabilityState: Codable, Identifiable {
    let key: CapabilityKey
    var isEnabled: Bool
    var statusNote: String
    var requiredPermission: String?

    var id: CapabilityKey { key }
}

struct CompanionConfiguration: Codable {
    var identity: AppIdentity
    var githubReleasesURL: String
    var exportedAt: Date
    var capabilities: [CapabilityState]
    var preferredGatewayHost: String
    var preferredGatewayPort: Int
    var supportWebsite: String
    var supportEmail: String
}

struct ReleaseInfo: Codable {
    let tagName: String
    let publishedAt: Date?
    let htmlURL: String
}
