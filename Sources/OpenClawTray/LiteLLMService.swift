import Foundation

enum LiteLLMService {
    private(set) static var process: Process?

    static func start() async throws {
        if await isHealthy() {
            process = nil
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: Constants.litellmBinaryPath)
        proc.environment = ProcessInfo.processInfo.environment.merging([
            "HOME": NSHomeDirectory(),
            "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "AWS_REGION": "eu-west-1"
        ]) { _, new in new }
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice

        do {
            try proc.run()
        } catch {
            throw LiteLLMError.startFailed(error.localizedDescription)
        }

        process = proc

        for _ in 0..<15 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if await isHealthy() { return }
        }

        proc.terminate()
        process = nil
        throw LiteLLMError.healthCheckFailed
    }

    static func stop() async throws {
        guard let proc = process else {
            return
        }

        proc.terminate()

        let didExit = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let deadline = DispatchTime.now() + 5
                while proc.isRunning {
                    if DispatchTime.now() >= deadline {
                        proc.interrupt()
                        continuation.resume(returning: false)
                        return
                    }
                    Thread.sleep(forTimeInterval: 0.1)
                }
                continuation.resume(returning: true)
            }
        }

        process = nil

        if !didExit {
            NSLog("LiteLLM did not exit within 5s, sent SIGINT")
        }
    }

    static func restart() async throws {
        try await stop()
        try await start()
    }

    static func isHealthy() async -> Bool {
        var request = URLRequest(url: Constants.litellmHealthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 3

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...499).contains(http.statusCode) {
                return true
            }
            return false
        } catch {
            return false
        }
    }
}

enum LiteLLMError: LocalizedError {
    case startFailed(String)
    case healthCheckFailed
    case notRunning

    var errorDescription: String? {
        switch self {
        case let .startFailed(reason):
            return "LiteLLM failed to start: \(reason)"
        case .healthCheckFailed:
            return "LiteLLM started but health check failed after 15 attempts"
        case .notRunning:
            return "LiteLLM is not running"
        }
    }
}
