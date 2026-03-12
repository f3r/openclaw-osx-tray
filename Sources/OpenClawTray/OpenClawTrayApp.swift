import SwiftUI

@main
struct OpenClawTrayApp: App {
    @StateObject private var poller = StatusPoller()

    init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                try? await LiteLLMService.stop()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(poller: poller)
        } label: {
            Label("OpenClaw", systemImage: poller.status.icon)
                .symbolRenderingMode(.palette)
                .foregroundStyle(poller.overallIconColor)
        }
        .menuBarExtraStyle(.window)
    }
}
