import SwiftUI

struct AboutClawEditView: View {
    @ObservedObject var model: CompanionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ArtworkCard(imageName: "splash", height: 220)

            HStack(alignment: .top, spacing: 16) {
                if let icon = ClawEditArt.image(named: "Icon") {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ClawEdit")
                        .font(.largeTitle.bold())
                    Text("OpenClaw macOS settings and privacy utility")
                        .foregroundStyle(.secondary)
                    Text("Built by \(model.identity.ownerName)")
                        .font(.subheadline)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("ClawEdit exists for the annoying Mac-side stuff that should have been easier: privacy panels, Full Disk Access, automation permissions, bridge exports, and the settings that keep OpenClaw-related tooling usable.")
                Text("Inspired by the old Mac era of ResEdit, but pointed at modern macOS permissions and tool readiness.")
                    .foregroundStyle(.secondary)
            }
            .font(.body)

            VStack(alignment: .leading, spacing: 6) {
                Link(model.identity.website, destination: URL(string: model.identity.website)!)
                Link(model.identity.email, destination: URL(string: "mailto:\(model.identity.email)")!)
                Link("GitHub Releases", destination: URL(string: "https://github.com/\(model.identity.repository)/releases")!)
            }
            .font(.subheadline)

            Spacer()

            HStack {
                Label(model.identity.license, systemImage: "doc.text")
                Label("Unsigned GitHub Build", systemImage: "exclamationmark.shield")
                Label("Option + About = Snake", systemImage: "gamecontroller")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.04), .blue.opacity(0.06), .orange.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        }
    }
}
