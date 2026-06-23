import AppKit
import AudioToolbox
import CoreAudio
import Foundation

enum VolumeDirection {
    case up
    case down
}

final class VolumeController {
    private enum MediaKey {
        static let volumeUp = 0
        static let volumeDown = 1
        static let systemDefinedSubtype = 8
        static let keyDownState = 0xA
        static let keyUpState = 0xB
    }

    func sendFineAdjustment(for direction: VolumeDirection, isKeyDown: Bool) {
        let mediaKeyCode = switch direction {
        case .up: MediaKey.volumeUp
        case .down: MediaKey.volumeDown
        }

        postModifiedMediaKeyEvent(keyCode: mediaKeyCode, isKeyDown: isKeyDown)
    }

    func currentVolumePercentage() -> Int? {
        guard
            let deviceID = defaultOutputDeviceID(),
            let currentVolume = currentVolume(for: deviceID)
        else {
            return nil
        }

        return Int((currentVolume * 100).rounded())
    }

    private func postModifiedMediaKeyEvent(keyCode: Int, isKeyDown: Bool) {
        let keyState = isKeyDown ? MediaKey.keyDownState : MediaKey.keyUpState
        let data1 = (keyCode << 16) | (keyState << 8)
        let stateFlags = NSEvent.ModifierFlags(rawValue: UInt(isKeyDown ? 0xA00 : 0xB00))
        let modifierFlags: NSEvent.ModifierFlags = [.shift, .option, stateFlags]

        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: modifierFlags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            subtype: Int16(MediaKey.systemDefinedSubtype),
            data1: data1,
            data2: -1
        ) else {
            return
        }

        event.cgEvent?.post(tap: .cghidEventTap)
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr else {
            return nil
        }

        return deviceID
    }

    private func currentVolume(for deviceID: AudioDeviceID) -> Float32? {
        if let volume = readVolume(
            selector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            deviceID: deviceID,
            channel: kAudioObjectPropertyElementMain
        ) {
            return volume
        }

        let channelVolumes = readableChannelVolumes(for: deviceID)
        guard !channelVolumes.isEmpty else {
            return nil
        }

        let total = channelVolumes.map(\.volume).reduce(0, +)
        return total / Float32(channelVolumes.count)
    }

    private func readableChannelVolumes(for deviceID: AudioDeviceID) -> [(channel: UInt32, volume: Float32)] {
        [1, 2].compactMap { channel in
            guard let volume = readVolume(
                selector: kAudioDevicePropertyVolumeScalar,
                deviceID: deviceID,
                channel: UInt32(channel)
            ) else {
                return nil
            }

            return (UInt32(channel), volume)
        }
    }

    private func readVolume(
        selector: AudioObjectPropertySelector,
        deviceID: AudioDeviceID,
        channel: AudioObjectPropertyElement
    ) -> Float32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: channel
        )

        guard AudioObjectHasProperty(deviceID, &address) else {
            return nil
        }

        var volume = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        guard status == noErr else {
            return nil
        }

        return volume
    }
}
