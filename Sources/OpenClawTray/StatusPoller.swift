import Foundation
import SwiftUI

@MainActor
final class StatusPoller: ObservableObject {
    @Published private(set) var status: GatewayStatus = .unknown
    @Published private(set) var litellmStatus: GatewayStatus = .unknown

    private var timer: Timer?

    init() {
        startPolling()
        Task { await checkNow() }
    }

    deinit {
        timer?.invalidate()
    }

    func checkNow() async {
        async let gw = Self.probe()
        async let ll = Self.probeLiteLLM()
        status = await gw
        litellmStatus = await ll
    }

    var overallIconColor: Color {
        if status == .running && litellmStatus == .running { return .green }
        if status == .stopped && litellmStatus == .stopped { return .gray }
        return .orange
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

    private static func probeLiteLLM() async -> GatewayStatus {
        var request = URLRequest(url: Constants.litellmHealthURL)
        request.httpMethod = "GET"
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
