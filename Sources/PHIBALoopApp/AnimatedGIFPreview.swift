import AppKit
import SwiftUI

struct AnimatedGIFPreview: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageAlignment = .alignCenter
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageFrameStyle = .none
        imageView.animates = true
        imageView.canDrawSubviewsIntoLayer = true
        configure(imageView)
        return imageView
    }

    func updateNSView(_ imageView: NSImageView, context: Context) {
        guard context.coordinator.currentURL != url else { return }
        context.coordinator.currentURL = url
        configure(imageView)
    }

    static func dismantleNSView(_ imageView: NSImageView, coordinator: Coordinator) {
        imageView.animates = false
        imageView.image = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentURL: url)
    }

    final class Coordinator {
        var currentURL: URL
        init(currentURL: URL) { self.currentURL = currentURL }
    }

    private func configure(_ imageView: NSImageView) {
        imageView.animates = false
        imageView.image = NSImage(contentsOf: url)
        imageView.animates = true
    }
}
