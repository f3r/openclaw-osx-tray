import SwiftUI

@main
struct OpenClawTrayApp: App {
    @StateObject private var poller = StatusPoller()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(poller: poller)
        } label: {
            Label("OpenClaw", systemImage: poller.status.icon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(poller.status.iconColor)
        }
    }
}
