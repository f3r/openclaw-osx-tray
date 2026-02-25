import SwiftUI
import ServiceManagement

struct LaunchAtLoginToggle: View {
    @State private var isEnabled = false
    @State private var errorMessage: String?

    var body: some View {
        Toggle("Launch at Login", isOn: $isEnabled)
            .onChange(of: isEnabled) { newValue in
                setLaunchAtLogin(enabled: newValue)
            }
            .onAppear {
                isEnabled = SMAppService.mainApp.status == .enabled
            }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            NSLog("Launch at login toggle failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
