import Cocoa
import Carbon

// Global C-compatible callback — must be at file scope
private func hotkeyCallback(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return OSStatus(eventNotHandledErr) }
    let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: .ccquickHotkeyPressed, object: nil)
        service.onHotkey?()
    }
    return noErr
}

extension Notification.Name {
    static let ccquickHotkeyPressed = Notification.Name("ccquickHotkeyPressed")
}

final class HotkeyService: @unchecked Sendable {
    private var hotkeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    var onHotkey: (() -> Void)?

    func start() {
        let shortcut = Preferences.shared.shortcut
        registerHotkey(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers)

        // Listen for shortcut changes
        Preferences.shared.onShortcutChanged = { [weak self] newShortcut in
            self?.unregisterHotkey()
            self?.registerHotkey(keyCode: newShortcut.keyCode, modifiers: newShortcut.modifiers)
        }
    }

    private func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        // Install event handler if not already done
        if handlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            var handler: EventHandlerRef?
            let handlerStatus = InstallEventHandler(
                GetApplicationEventTarget(),
                hotkeyCallback,
                1,
                &eventType,
                selfPtr,
                &handler
            )

            if handlerStatus == noErr {
                self.handlerRef = handler
            } else {
                print("[CCQuick] Failed to install event handler: \(handlerStatus)")
                return
            }
        }

        let hotkeyID = EventHotKeyID(signature: OSType(0x4343_4B59), id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)

        if status == noErr {
            hotkeyRef = ref
            let shortcut = ShortcutKey(keyCode: keyCode, modifiers: modifiers)
            print("[CCQuick] Global hotkey registered: \(shortcut.displayName)")
        } else {
            print("[CCQuick] Failed to register hotkey, status: \(status)")
        }
    }

    private func unregisterHotkey() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
    }

    func stop() {
        unregisterHotkey()
        if let handler = handlerRef {
            RemoveEventHandler(handler)
            handlerRef = nil
        }
    }
}
