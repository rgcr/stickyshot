/**
 * KeyCodeMapping.swift
 * ~~~~~~~~~~~~~~~~~~~~~
 *
 * Keyboard key code mappings and modifier flag conversions for global hotkey registration
 */

import Carbon
import AppKit


struct KeyCodeMapping {

    // MARK: - Key Code Mapping

    static let keyCodeMap: [String: UInt32] = [
        "a": UInt32(kVK_ANSI_A),
        "b": UInt32(kVK_ANSI_B),
        "c": UInt32(kVK_ANSI_C),
        "d": UInt32(kVK_ANSI_D),
        "e": UInt32(kVK_ANSI_E),
        "f": UInt32(kVK_ANSI_F),
        "g": UInt32(kVK_ANSI_G),
        "h": UInt32(kVK_ANSI_H),
        "i": UInt32(kVK_ANSI_I),
        "j": UInt32(kVK_ANSI_J),
        "k": UInt32(kVK_ANSI_K),
        "l": UInt32(kVK_ANSI_L),
        "m": UInt32(kVK_ANSI_M),
        "n": UInt32(kVK_ANSI_N),
        "o": UInt32(kVK_ANSI_O),
        "p": UInt32(kVK_ANSI_P),
        "q": UInt32(kVK_ANSI_Q),
        "r": UInt32(kVK_ANSI_R),
        "s": UInt32(kVK_ANSI_S),
        "t": UInt32(kVK_ANSI_T),
        "u": UInt32(kVK_ANSI_U),
        "v": UInt32(kVK_ANSI_V),
        "w": UInt32(kVK_ANSI_W),
        "x": UInt32(kVK_ANSI_X),
        "y": UInt32(kVK_ANSI_Y),
        "z": UInt32(kVK_ANSI_Z),
        "0": UInt32(kVK_ANSI_0),
        "1": UInt32(kVK_ANSI_1),
        "2": UInt32(kVK_ANSI_2),
        "3": UInt32(kVK_ANSI_3),
        "4": UInt32(kVK_ANSI_4),
        "5": UInt32(kVK_ANSI_5),
        "6": UInt32(kVK_ANSI_6),
        "7": UInt32(kVK_ANSI_7),
        "8": UInt32(kVK_ANSI_8),
        "9": UInt32(kVK_ANSI_9),
        "space": UInt32(kVK_Space),
        "return": UInt32(kVK_Return),
        "tab": UInt32(kVK_Tab),
        "escape": UInt32(kVK_Escape),
        "delete": UInt32(kVK_Delete),
        "f1": UInt32(kVK_F1),
        "f2": UInt32(kVK_F2),
        "f3": UInt32(kVK_F3),
        "f4": UInt32(kVK_F4),
        "f5": UInt32(kVK_F5),
        "f6": UInt32(kVK_F6),
        "f7": UInt32(kVK_F7),
        "f8": UInt32(kVK_F8),
        "f9": UInt32(kVK_F9),
        "f10": UInt32(kVK_F10),
        "f11": UInt32(kVK_F11),
        "f12": UInt32(kVK_F12)
    ]


    // MARK: - Public Methods

    static func keyCode(for key: String) -> UInt32? {
        return keyCodeMap[key.lowercased()]
    }


    static func modifierFlags(from modifiers: [String]) -> UInt32 {
        var flags: UInt32 = 0

        for modifier in modifiers {
            switch modifier.lowercased() {
            case "command", "cmd":
                flags |= UInt32(cmdKey)
            case "shift":
                flags |= UInt32(shiftKey)
            case "option", "alt":
                flags |= UInt32(optionKey)
            case "control", "ctrl":
                flags |= UInt32(controlKey)
            default:
                break
            }
        }

        return flags
    }


    static func modifierFlagsNS(from modifiers: [String]) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []

        for modifier in modifiers {
            switch modifier.lowercased() {
            case "command", "cmd":
                flags.insert(.command)
            case "shift":
                flags.insert(.shift)
            case "option", "alt":
                flags.insert(.option)
            case "control", "ctrl":
                flags.insert(.control)
            default:
                break
            }
        }

        return flags
    }


    static func displayString(key: String, modifiers: [String]) -> String {
        var parts: [String] = []

        for modifier in modifiers {
            switch modifier.lowercased() {
            case "command", "cmd":
                parts.append("⌘")
            case "shift":
                parts.append("⇧")
            case "option", "alt":
                parts.append("⌥")
            case "control", "ctrl":
                parts.append("⌃")
            default:
                break
            }
        }

        parts.append(key.uppercased())

        return parts.joined()
    }
}
