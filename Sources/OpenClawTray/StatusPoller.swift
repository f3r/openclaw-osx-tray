import Foundation
import SwiftUI

@MainActor
final class StatusPoller: ObservableObject {
    @Published private(set) var status: GatewayStatus = .unknown

    private var timer: Timer?

    init() {
        startPolling()
        Task { await checkNow() }
    }

    deinit {
        timer?.invalidate()
    }

    func checkNow() async {
        let newStatus = await Self.probe()
        status = newStatus
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(
            withTimeInterval: Constants.pollInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.checkNow()
            }
        }
    }

    private static func probe() async -> GatewayStatus {
        var request = URLRequest(url: Constants.healthURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               (200...499).contains(httpResponse.statusCode) {
                return .running
            }
            return .stopped
        } catch {
            return .stopped
        }
    }
}
