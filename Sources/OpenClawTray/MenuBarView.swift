import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var poller: StatusPoller
    @State private var isPerformingAction = false
    @State private var actionLabel: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusHeader
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                menuButton("Start Gateway", icon: "play.fill") {
                    performAction(label: "Starting...") { try await GatewayService.start() }
                }
                .disabled(!poller.status.canStart || isPerformingAction)

                menuButton("Stop Gateway", icon: "stop.fill") {
                    performAction(label: "Stopping...") { try await GatewayService.stop() }
                }
                .disabled(!poller.status.canStop || isPerformingAction)

                menuButton("Restart Gateway", icon: "arrow.clockwise") {
                    performAction(label: "Restarting...") { try await GatewayService.restart() }
                }
                .disabled(isPerformingAction)
            }
            .padding(.vertical, 4)

            Divider()

            menuButton("Open Dashboard", icon: "globe") {
                Task {
                    guard let url = try? await GatewayService.dashboardURL() else { return }
                    NSWorkspace.shared.open(url)
                }
            }
            .disabled(poller.status != .running)
            .padding(.vertical, 4)

            Divider()

            LaunchAtLoginToggle()
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            Divider()

            menuButton("Quit OpenClaw", icon: "xmark.circle") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 220)
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: poller.status.icon)
                    .foregroundStyle(poller.status.iconColor)
                Text("Gateway: \(poller.status.label)")
                    .font(.headline)
            }

            if let actionLabel {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text(actionLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func performAction(label: String, _ action: @escaping () async throws -> Void) {
        isPerformingAction = true
        actionLabel = label
        errorMessage = nil
        let statusBeforeAction = poller.status

        Task {
            do {
                try await action()
            } catch {
                errorMessage = error.localizedDescription
                scheduleErrorDismissal()
            }

            actionLabel = nil

            for _ in 0..<8 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await poller.checkNow()
                if poller.status != statusBeforeAction {
                    break
                }
            }

            isPerformingAction = false
        }
    }

    private func scheduleErrorDismissal() {
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if errorMessage != nil {
                errorMessage = nil
            }
        }
    }
}
