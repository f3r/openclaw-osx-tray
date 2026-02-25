import Foundation

enum Constants {
    static let binaryPath = "/opt/homebrew/bin/openclaw"
    static let gatewayHost = "127.0.0.1"
    static let gatewayPort: UInt16 = 18789
    static let dashboardURL = URL(string: "http://127.0.0.1:18789/")!
    static let healthURL = URL(string: "http://127.0.0.1:18789/")!
    static let pollInterval: TimeInterval = 5.0
}
