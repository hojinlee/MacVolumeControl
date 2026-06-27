import ServiceManagement

enum LaunchAtLoginMenuState: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case failed
}

protocol LaunchAtLoginServicing: AnyObject {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

extension SMAppService: LaunchAtLoginServicing {}

final class LaunchAtLoginController {
    private let service: LaunchAtLoginServicing
    private let settingsStore: SettingsStore
    private let openSystemSettings: () -> Void
    private var lastOperationFailed = false

    init(
        service: LaunchAtLoginServicing = SMAppService.mainApp,
        settingsStore: SettingsStore,
        openSystemSettings: @escaping () -> Void = {
            SMAppService.openSystemSettingsLoginItems()
        }
    ) {
        self.service = service
        self.settingsStore = settingsStore
        self.openSystemSettings = openSystemSettings
    }

    var menuState: LaunchAtLoginMenuState {
        if lastOperationFailed {
            return .failed
        }

        switch service.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .failed
        @unknown default:
            return .failed
        }
    }

    func applyDefaultIfNeeded() {
        guard !settingsStore.hasAppliedLaunchAtLoginDefault else {
            return
        }

        switch service.status {
        case .enabled, .requiresApproval:
            settingsStore.hasAppliedLaunchAtLoginDefault = true
        case .notRegistered, .notFound:
            register()
        @unknown default:
            lastOperationFailed = true
        }
    }

    func performMenuAction() {
        lastOperationFailed = false

        switch service.status {
        case .notRegistered, .notFound:
            register()
        case .enabled:
            do {
                try service.unregister()
            } catch {
                NSLog("Failed to unregister launch at login: \(error as NSError)")
                lastOperationFailed = true
            }
        case .requiresApproval:
            openSystemSettings()
        @unknown default:
            lastOperationFailed = true
        }
    }

    private func register() {
        do {
            try service.register()
            settingsStore.hasAppliedLaunchAtLoginDefault = true
        } catch {
            if service.status == .requiresApproval {
                settingsStore.hasAppliedLaunchAtLoginDefault = true
            } else {
                NSLog("Failed to register launch at login: \(error as NSError)")
                lastOperationFailed = true
            }
        }
    }
}
