import AppKit
import SwiftUI

enum ClawEditArt {
    static func image(named name: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    @MainActor
    static func applyAppIconIfAvailable() {
        guard let image = image(named: "Icon") else {
            return
        }
        NSApp.applicationIconImage = image
    }
}

struct ArtworkCard: View {
    let imageName: String
    let height: CGFloat

    var body: some View {
        if let image = ClawEditArt.image(named: imageName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
        }
    }
}
