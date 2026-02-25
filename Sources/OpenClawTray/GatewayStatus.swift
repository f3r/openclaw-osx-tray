import SwiftUI

enum GatewayStatus: Equatable {
    case running
    case stopped
    case unknown

    var icon: String {
        switch self {
        case .running:
            return "antenna.radiowaves.left.and.right"
        case .stopped:
            return "antenna.radiowaves.left.and.right.slash"
        case .unknown:
            return "antenna.radiowaves.left.and.right.slash"
        }
    }

    var iconColor: Color {
        switch self {
        case .running:
            return .green
        case .stopped:
            return .gray
        case .unknown:
            return .orange
        }
    }

    var label: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .unknown:
            return "Unknown"
        }
    }

    var canStart: Bool {
        self != .running
    }

    var canStop: Bool {
        self == .running
    }
}
