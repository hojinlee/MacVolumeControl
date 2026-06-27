import Foundation

final class SettingsStore {
    private enum Key {
        static let fineModeEnabled = "fineModeEnabled"
        static let hasAppliedLaunchAtLoginDefault = "hasAppliedLaunchAtLoginDefault"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.fineModeEnabled: true
        ])
    }

    var isFineModeEnabled: Bool {
        get { defaults.bool(forKey: Key.fineModeEnabled) }
        set { defaults.set(newValue, forKey: Key.fineModeEnabled) }
    }

    var hasAppliedLaunchAtLoginDefault: Bool {
        get { defaults.bool(forKey: Key.hasAppliedLaunchAtLoginDefault) }
        set { defaults.set(newValue, forKey: Key.hasAppliedLaunchAtLoginDefault) }
    }
}
