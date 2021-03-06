//
//  DefaultsManager.swift
//  OpenInTerminalCore
//
//  Created by Jianing Wang on 2019/10/14.
//  Copyright © 2019 Jianing Wang. All rights reserved.
//

import Foundation

public class DefaultsManager {
    
    public static var shared = DefaultsManager()
    
    public var isFirstUsage: BoolType {
        if Defaults[.firstUsage] == nil {
            Defaults[.firstUsage] = BoolType._false.rawValue
            return ._true
        } else {
            return ._false
        }
    }
    
    // MARK: - General Settings
    
    public var defaultTerminal: TerminalType? {
        get {
            if let groupDefaults = GroupDefaults {
                return groupDefaults[.defaultTerminal]
                    .map(TerminalType.init(rawValue: )) ?? nil
            } else {
                // OpenInTerminal-Lite and OpenInEditor-Lite don't have Group UserDefaults.
                return Defaults[.defaultTerminal]
                    .map(TerminalType.init(rawValue: )) ?? nil
            }
        }
        
        set {
            guard let newValue = newValue else { return }
            Defaults[.defaultTerminal] = newValue.rawValue
            if let groupDefaults = GroupDefaults {
                groupDefaults[.defaultTerminal] = newValue.rawValue
            }
        }
    }
    
    public func removeDefaultTerminal() {
        Defaults.removeObject(forKey: Constants.Key.defaultTerminal)
        if let groupDefaults = GroupDefaults {
            groupDefaults.removeObject(forKey: Constants.Key.defaultTerminal)
        }
    }
    
    public var defaultEditor: EditorType? {
        get {
            if let groupDefaults = GroupDefaults {
                return groupDefaults[.defaultEditor]
                    .map(EditorType.init(rawValue: )) ?? nil
            } else {
                // OpenInTerminal-Lite or OpenInEditor-Lite
                return Defaults[.defaultEditor]
                    .map(EditorType.init(rawValue: )) ?? nil
            }
        }
        
        set {
            guard let newValue = newValue else { return }
            Defaults[.defaultEditor] = newValue.rawValue
            if let groupDefaults = GroupDefaults {
                groupDefaults[.defaultEditor] = newValue.rawValue
            }
        }
    }
    
    public func removeDefaultEditor() {
        Defaults.removeObject(forKey: Constants.Key.defaultEditor)
        if let groupDefaults = GroupDefaults {
            groupDefaults.removeObject(forKey: Constants.Key.defaultEditor)
        }
    }
    
    public var isLaunchAtLogin: BoolType {
        get {
            let defaultValue = Defaults[.launchAtLogin].map(BoolType.init(rawValue: )) ?? nil
            if let boolValue = defaultValue {
                return boolValue
            } else {
                // Since we have inited all the values at first setup, if we still get a nil value,
                // that means bad guys changed it to arbitrarily string.
                // We should changed it to default value.
                Defaults[.launchAtLogin] = BoolType._false.rawValue
                return ._false
            }
        }
        
        set {
            Defaults[.launchAtLogin] = newValue.rawValue
        }
    }
    
    public var isHideStatusItem: BoolType {
        get {
            let defaultValue = Defaults[.hideStatusItem].map(BoolType.init(rawValue: )) ?? nil
            if let boolValue = defaultValue {
                return boolValue
            } else {
                Defaults[.hideStatusItem] = BoolType._false.rawValue
                return ._false
            }
        }
        
        set {
            Defaults[.hideStatusItem] = newValue.rawValue
        }
    }
    
    public var isQuickToggle: BoolType {
        get {
            let defaultValue = Defaults[.quickToggle].map(BoolType.init(rawValue: )) ?? nil
            if let boolValue = defaultValue {
                return boolValue
            } else {
                Defaults[.quickToggle] = BoolType._false.rawValue
                return ._false
            }
        }
        
        set {
            Defaults[.quickToggle] = newValue.rawValue
        }
    }
    
    public var quickToggleType: QuickToggleType? {
        get {
            return Defaults[.quickToggleType].map(QuickToggleType.init(rawValue: )) ?? nil
        }
        
        set {
            Defaults[.quickToggleType] = newValue?.rawValue
        }
    }
    
    // MARK: - Terminal Settings
    
    public func getNewOption(_ terminal: TerminalType) -> NewOptionType? {
        var option: String?
        switch terminal {
        case .terminal:
            if let groupDefaults = GroupDefaults {
                option = groupDefaults[.terminalNewOption]
            } else {
                option = Defaults[.terminalNewOption]
            }
        case .iTerm:
            if let groupDefaults = GroupDefaults {
                option = groupDefaults[.iTermNewOption]
            } else {
                option = Defaults[.iTermNewOption]
            }
        case .hyper, .alacritty:
            return nil
        }
        
        return option.map(NewOptionType.init(rawValue: )) ?? nil
    }
    
    public func setNewOption(_ terminal: TerminalType, _ newOption: NewOptionType) throws {
        switch terminal {
        case .terminal:
            Defaults[.terminalNewOption] = newOption.rawValue
            if let groupDefaults = GroupDefaults {
                groupDefaults[.terminalNewOption] = newOption.rawValue
            }
        case .iTerm:
            Defaults[.iTermNewOption] = newOption.rawValue
            if let groupDefaults = GroupDefaults {
                groupDefaults[.iTermNewOption] = newOption.rawValue
            }
            
            let option = newOption == .window ? "true" : "false"
            
            let source = """
            do shell script "defaults write \(TerminalType.iTerm.bundleId) OpenFileInNewWindows -bool \(option)"
            """
            let script = NSAppleScript(source: source)!
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if error != nil {
                throw OITError.cannotSetItermNewOption
            }
        case .hyper, .alacritty:
            return
        }
    }
    
    // MARK: - Advanced Settings
    
    public func firstSetup() {
        guard isFirstUsage == ._true else { return }
        logw("First Setup")
        if let grounpDefaults = GroupDefaults {
            grounpDefaults.removeObject(forKey: Constants.Key.defaultTerminal)
            grounpDefaults.removeObject(forKey: Constants.Key.defaultEditor)
            grounpDefaults[.terminalNewOption] = NewOptionType.window.rawValue
            grounpDefaults[.iTermNewOption] = NewOptionType.window.rawValue
            grounpDefaults.synchronize()
        }
        Defaults[.launchAtLogin] = BoolType._false.rawValue
        Defaults[.hideStatusItem] = BoolType._false.rawValue
        Defaults[.quickToggle] = BoolType._false.rawValue
        Defaults[.quickToggleType] = QuickToggleType.openWithDefaultTerminal.rawValue
        Defaults.removeObject(forKey: Constants.Key.defaultTerminal)
        Defaults.removeObject(forKey: Constants.Key.defaultEditor)
        Defaults[.terminalNewOption] = NewOptionType.window.rawValue
        Defaults[.iTermNewOption] = NewOptionType.window.rawValue
        Defaults.synchronize()
    }
    
    public func removeAllUserDefaults() {
        logw("Remove all UserDefaults")
        if let grounpDefaults = GroupDefaults {
            grounpDefaults.removePersistentDomain(forName: Constants.groupIdentifier)
            grounpDefaults.synchronize()
        }
        let domain = Bundle.main.bundleIdentifier!
        Defaults.removePersistentDomain(forName: domain)
        Defaults.synchronize()
    }
    
}
