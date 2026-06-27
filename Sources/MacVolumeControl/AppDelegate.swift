import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settingsStore = SettingsStore()
    private let volumeController = VolumeController()
    private lazy var eventTapController = EventTapController(
        settingsStore: settingsStore,
        volumeController: volumeController,
        onStatusChange: { [weak self] in
            DispatchQueue.main.async {
                self?.refreshMenuState()
            }
        },
        onVolumeAdjusted: { [weak self] in
            DispatchQueue.main.async {
                self?.refreshVolumeTitle()
            }
        },
        onInputIntercepted: { [weak self] description in
            DispatchQueue.main.async {
                self?.lastInterceptedInputDescription = description
                self?.refreshMenuState()
            }
        }
    )
    private lazy var launchAtLoginController = LaunchAtLoginController(
        settingsStore: settingsStore
    )

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private let volumeItem = NSMenuItem(title: "현재 볼륨: --", action: nil, keyEquivalent: "")
    private let captureStatusItem = NSMenuItem(title: "입력 감시 상태: --", action: nil, keyEquivalent: "")
    private let lastInputItem = NSMenuItem(title: "마지막 감지: --", action: nil, keyEquivalent: "")
    private let fineModeItem = NSMenuItem(title: "미세 조정 사용", action: nil, keyEquivalent: "")
    private let modeDescriptionItem = NSMenuItem(title: "현재 모드: --", action: nil, keyEquivalent: "")
    private let restartItem = NSMenuItem(title: "입력 감시 다시 시작", action: nil, keyEquivalent: "")
    private let permissionsItem = NSMenuItem(title: "권한 설정 열기…", action: nil, keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "로그인 시 자동 실행", action: nil, keyEquivalent: "")
    private var lastInterceptedInputDescription = "--"

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        configureMenu()
        launchAtLoginController.applyDefaultIfNeeded()
        refreshMenuState()
        refreshVolumeTitle()

        if settingsStore.isFineModeEnabled {
            restartEventCapture()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventTapController.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshMenuState()
        refreshVolumeTitle()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = StatusKnobIcon.makeImage()
            button.toolTip = "MacVolumeControl"
        }
        item.menu = menu
        statusItem = item
    }

    private func configureMenu() {
        menu.delegate = self

        volumeItem.isEnabled = false
        captureStatusItem.isEnabled = false
        lastInputItem.isEnabled = false
        modeDescriptionItem.isEnabled = false

        fineModeItem.target = self
        fineModeItem.action = #selector(toggleFineMode(_:))

        restartItem.target = self
        restartItem.action = #selector(restartCapture(_:))

        permissionsItem.target = self
        permissionsItem.action = #selector(openPermissionSettings(_:))

        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin(_:))

        menu.addItem(volumeItem)
        menu.addItem(captureStatusItem)
        menu.addItem(lastInputItem)
        menu.addItem(.separator())
        menu.addItem(fineModeItem)
        menu.addItem(modeDescriptionItem)
        menu.addItem(restartItem)
        menu.addItem(permissionsItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quitApplication(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func refreshMenuState() {
        fineModeItem.state = settingsStore.isFineModeEnabled ? .on : .off
        modeDescriptionItem.title = settingsStore.isFineModeEnabled
            ? "현재 모드: 시스템 미세 조정 (⌥⇧F11/F12)"
            : "현재 모드: 원래 동작"
        restartItem.isEnabled = settingsStore.isFineModeEnabled
        captureStatusItem.title = "입력 감시 상태: \(captureStatusText())"
        lastInputItem.title = "마지막 감지: \(lastInterceptedInputDescription)"
        refreshLaunchAtLoginItem()
    }

    private func refreshLaunchAtLoginItem() {
        let presentation = LaunchAtLoginMenuPresentation(
            state: launchAtLoginController.menuState
        )
        launchAtLoginItem.title = presentation.title
        launchAtLoginItem.state = presentation.itemState
    }

    private func refreshVolumeTitle() {
        if let percentage = volumeController.currentVolumePercentage() {
            volumeItem.title = "현재 볼륨: \(percentage)%"
        } else {
            volumeItem.title = "현재 볼륨: 확인 불가"
        }
    }

    private func captureStatusText() -> String {
        guard settingsStore.isFineModeEnabled else {
            return "꺼짐"
        }

        if eventTapController.isRunning {
            return "활성"
        }

        if isAccessibilityTrusted() {
            return "추가 권한 또는 재시작 필요"
        }

        return "권한 필요"
    }

    private func isAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    private func requestAccessibilityPromptIfNeeded() {
        guard !AXIsProcessTrusted() else {
            return
        }

        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    private func restartEventCapture() {
        eventTapController.stop()

        guard settingsStore.isFineModeEnabled else {
            refreshMenuState()
            return
        }

        _ = eventTapController.start()
        refreshMenuState()
    }

    @objc
    private func toggleFineMode(_ sender: NSMenuItem) {
        settingsStore.isFineModeEnabled.toggle()
        restartEventCapture()
    }

    @objc
    private func restartCapture(_ sender: NSMenuItem) {
        restartEventCapture()
    }

    @objc
    private func openPermissionSettings(_ sender: NSMenuItem) {
        requestAccessibilityPromptIfNeeded()

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc
    private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        launchAtLoginController.performMenuAction()
        refreshMenuState()
    }

    @objc
    private func quitApplication(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}
