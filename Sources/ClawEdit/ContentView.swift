import SwiftUI

struct ContentView: View {
    @ObservedObject var model: CompanionViewModel

    var body: some View {
        NavigationSplitView {
            List {
                Section("Owner") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.identity.ownerName)
                            .font(.headline)
                        Link(model.identity.website, destination: URL(string: model.identity.website)!)
                        Link(model.identity.email, destination: URL(string: "mailto:\(model.identity.email)")!)
                    }
                    .padding(.vertical, 4)
                }

                Section("Distribution") {
                    Label("Unsigned GitHub Build", systemImage: "exclamationmark.shield")
                    Text("This app is meant to live outside the App Store and may require manual trust approval.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Capabilities") {
                    ForEach(model.capabilities) { capability in
                        CapabilityRow(capability: capability) { enabled in
                            model.toggle(capability.key, enabled: enabled)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("ClawEdit")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    ArtworkCard(imageName: "splash", height: 300)
                    gatewayCard
                    exportCard
                    updatesCard
                }
                .padding(24)
            }
            .navigationTitle("ClawEdit")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                if let icon = ClawEditArt.image(named: "Icon") {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 16, y: 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ClawEdit")
                        .font(.largeTitle.bold())
                    Text("Built for Matthew Murphy. Inspired by ResEdit, this is the Mac-side utility for privacy panels, bridge exports, system adjustments, and the ugly setup work OpenClaw should not have to narrate in chat.")
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Label("MIT Licensed", systemImage: "doc.text")
                Label("GitHub Distributed", systemImage: "arrow.down.circle")
                Label("Privacy Adjustments", systemImage: "lock.shield")
                Label("ResEdit Spirit", systemImage: "sparkles.rectangle.stack")
            }
            .font(.subheadline)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.22), .blue.opacity(0.18), .red.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var gatewayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gateway Target")
                .font(.title2.bold())
            HStack {
                VStack(alignment: .leading) {
                    Text("Host")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("192.168.88.11", text: $model.preferredGatewayHost)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text("Port")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("18789", value: $model.preferredGatewayPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }
            Text("These values are exported for Linux bridge tooling after the Mac-side settings and permissions are in place.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bridge Export")
                .font(.title2.bold())
            Text("Export the current settings-adjuster state so a gateway or wrapper layer can consume approved Mac capabilities.")
                .foregroundStyle(.secondary)
            Button("Export Companion Config") {
                model.exportConfiguration()
            }
            Text(model.lastExportStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(model.lastExportPath)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var updatesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GitHub Updates")
                .font(.title2.bold())
            Text("No App Store path assumed. Version checks come from GitHub releases.")
                .foregroundStyle(.secondary)
            HStack {
                Button(model.updateCheckInFlight ? "Checking..." : "Check GitHub Releases") {
                    Task { await model.checkForUpdates() }
                }
                .disabled(model.updateCheckInFlight)

                if !model.latestReleaseURL.isEmpty, let url = URL(string: model.latestReleaseURL) {
                    Link("Open Releases", destination: url)
                }
            }
            Text(model.latestReleaseText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

private struct CapabilityRow: View {
    let capability: CapabilityState
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(
                get: { capability.isEnabled },
                set: { enabled in
                    onToggle(enabled)
                }
            )) {
                Text(capability.key.title)
            }
            Text(capability.key.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(capability.statusNote)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if let requiredPermission = capability.requiredPermission {
                Text("Permission: \(requiredPermission)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @ObservedObject var model: CompanionViewModel

    var body: some View {
        Form {
            Section("Owner Identity") {
                TextField("Owner", text: .constant(model.identity.ownerName))
                TextField("Website", text: .constant(model.identity.website))
                TextField("Email", text: .constant(model.identity.email))
            }

            Section("Repository") {
                TextField("GitHub Repo", text: .constant(model.identity.repository))
                Toggle("Unsigned Distribution", isOn: .constant(model.identity.unsignedDistribution))
            }

            Section("License") {
                Text(model.identity.license)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}
