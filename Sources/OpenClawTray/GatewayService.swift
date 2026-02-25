import Foundation

enum GatewayService {
    static func start() async throws {
        try await run(command: "start")
    }

    static func stop() async throws {
        try await run(command: "stop")
    }

    static func restart() async throws {
        try await run(command: "restart")
    }

    static func install() async throws {
        try await run(subcommand: "gateway", command: "install")
    }

    static func openDashboard() async throws {
        try await run(subcommand: nil, command: "dashboard")
    }

    @discardableResult
    private static func run(subcommand: String? = "gateway", command: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()

                process.executableURL = URL(fileURLWithPath: Constants.binaryPath)
                if let subcommand {
                    process.arguments = [subcommand, command]
                } else {
                    process.arguments = [command]
                }
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: output)
                    } else {
                        let error = GatewayError.commandFailed(
                            command: command,
                            status: process.terminationStatus,
                            output: output
                        )
                        continuation.resume(throwing: error)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum GatewayError: LocalizedError {
    case commandFailed(command: String, status: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case let .commandFailed(command, status, output):
            return "Gateway \(command) failed (exit \(status)): \(output)"
        }
    }
}
