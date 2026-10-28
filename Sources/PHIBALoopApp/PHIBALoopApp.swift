import SwiftUI

@main
struct PHIBALoopApp: App {
    @StateObject private var store = ConversionStore()

    var body: some Scene {
        WindowGroup("PHIBALoop") {
            ContentView(store: store)
        }
        .defaultSize(width: 1240, height: 760)
    }
}
