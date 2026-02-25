import SwiftUI

struct MenuBarView: View {
    @ObservedObject var poller: StatusPoller
    @State private var isPerformingAction = false

    var body: some View {
        VStack {
            statusHeader
            Divider()
            gatewayControls
            Divider()
            dashboardButton
            Divider()
            launchAtLoginToggle
            Divider()
            quitButton
        }
    }

    private var statusHeader: some View {
        HStack {
            Image(systemName: poller.status.icon)
                .foregroundStyle(poller.status.iconColor)
            Text("Gateway: \(poller.status.label)")
                .font(.headline)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var gatewayControls: some View {
        Group {
            Button("Start Gateway") {
                performAction { try await GatewayService.start() }
            }
            .disabled(!poller.status.canStart || isPerformingAction)

            Button("Stop Gateway") {
                performAction { try await GatewayService.stop() }
            }
            .disabled(!poller.status.canStop || isPerformingAction)

            Button("Restart Gateway") {
                performAction { try await GatewayService.restart() }
            }
            .disabled(isPerformingAction)
        }
    }

    private var dashboardButton: some View {
        Button("Open Dashboard") {
            Task {
                try? await GatewayService.openDashboard()
            }
        }
        .disabled(poller.status != .running)
    }

    private var launchAtLoginToggle: some View {
        LaunchAtLoginToggle()
    }

    private var quitButton: some View {
        Button("Quit OpenClaw") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func performAction(_ action: @escaping () async throws -> Void) {
        isPerformingAction = true
        Task {
            do {
                try await action()
            } catch {
                NSLog("Gateway action failed: \(error.localizedDescription)")
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await poller.checkNow()
            isPerformingAction = false
        }
    }
}
