import AppKit
import Carbon.HIToolbox

final class EventTapController {
    private static let systemDefinedEventType = CGEventType(rawValue: 14)!

    private let settingsStore: SettingsStore
    private let volumeController: VolumeController
    private let onStatusChange: () -> Void
    private let onVolumeAdjusted: () -> Void
    private let onInputIntercepted: (String) -> Void

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private(set) var isRunning = false

    init(
        settingsStore: SettingsStore,
        volumeController: VolumeController,
        onStatusChange: @escaping () -> Void,
        onVolumeAdjusted: @escaping () -> Void,
        onInputIntercepted: @escaping (String) -> Void
    ) {
        self.settingsStore = settingsStore
        self.volumeController = volumeController
        self.onStatusChange = onStatusChange
        self.onVolumeAdjusted = onVolumeAdjusted
        self.onInputIntercepted = onInputIntercepted
    }

    @discardableResult
    func start() -> Bool {
        stop()

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
            | CGEventMask(1 << Self.systemDefinedEventType.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
            return controller.handleEvent(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            isRunning = false
            onStatusChange()
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        isRunning = true
        onStatusChange()
        return true
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        if isRunning {
            isRunning = false
            onStatusChange()
        }
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard settingsStore.isFineModeEnabled else {
            return Unmanaged.passUnretained(event)
        }

        if let interceptedInput = interceptableInput(type: type, event: event) {
            volumeController.sendFineAdjustment(for: interceptedInput.direction, isKeyDown: interceptedInput.isKeyDown)
            onInputIntercepted(interceptedInput.description)
            if interceptedInput.isKeyDown {
                onVolumeAdjusted()
            }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func interceptableInput(type: CGEventType, event: CGEvent) -> (direction: VolumeDirection, isKeyDown: Bool, description: String)? {
        if let functionKeyInput = transformableFunctionKey(for: event) {
            let description = functionKeyInput.isKeyDown
                ? "F\(functionKeyInput.direction == .up ? "12" : "11") down"
                : "F\(functionKeyInput.direction == .up ? "12" : "11") up"
            return (functionKeyInput.direction, functionKeyInput.isKeyDown, description)
        }

        if let mediaKeyInput = transformableMediaKey(type: type, event: event) {
            let description = mediaKeyInput.isKeyDown
                ? "media \(mediaKeyInput.direction == .up ? "volume up" : "volume down") down"
                : "media \(mediaKeyInput.direction == .up ? "volume up" : "volume down") up"
            return (mediaKeyInput.direction, mediaKeyInput.isKeyDown, description)
        }

        return nil
    }

    private func transformableFunctionKey(for event: CGEvent) -> (direction: VolumeDirection, isKeyDown: Bool)? {
        guard
            event.type == .keyDown || event.type == .keyUp,
            let nsEvent = NSEvent(cgEvent: event)
        else {
            return nil
        }

        let flags = nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if !flags.isEmpty {
            return nil
        }

        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        switch keyCode {
        case kVK_F12:
            return (.up, event.type == .keyDown)
        case kVK_F11:
            return (.down, event.type == .keyDown)
        default:
            return nil
        }
    }

    private func transformableMediaKey(type: CGEventType, event: CGEvent) -> (direction: VolumeDirection, isKeyDown: Bool)? {
        guard
            type == Self.systemDefinedEventType,
            let nsEvent = NSEvent(cgEvent: event),
            nsEvent.subtype.rawValue == 8
        else {
            return nil
        }

        let flags = nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains([.option, .shift]) {
            return nil
        }

        let keyCode = (nsEvent.data1 & 0xFFFF0000) >> 16
        let keyFlags = nsEvent.data1 & 0x0000FFFF
        let keyState = (keyFlags & 0xFF00) >> 8
        let isKeyDown = keyState == 0xA

        switch keyCode {
        case 0:
            return (.up, isKeyDown)
        case 1:
            return (.down, isKeyDown)
        default:
            return nil
        }
    }
}
