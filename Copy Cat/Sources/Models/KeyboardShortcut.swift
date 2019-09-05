//
//  KeyboardShortcut.swift
//  Copy Cat
//
//  Created by Cade May on 6/7/19.
//  Copyright © 2019 21CFC. All rights reserved.
//

import HotKey

/** The key used to store the keyboard shortcut setting in the user defaults store. Note: it is probably best not to touch this; changing this will cause the app to forget the user's preferred keyboard shortcut. */
private let storageKey: String = "KeyboardShortcut"

/** Interface for the keyboard shortcut system. This class allows getting and setting the global keyboard shortcut, and also allows changing the callback function that gets run when the shortcut is pressed. Within the MVC pattern, this class would most likely be considered a model. See `AppDelegate.swift` for usage. */
class KeyboardShortcut {
    
    /** The set of legal keyboard shortcut values. The numbers 6 through 9 correspond to the key combinations Shift + Cmd + 6 through Shift + Cmd + 9. */
    static let validShortcuts = 6...9
    
    /** Singleton pattern. Shared instance to be used anywhere the client wants to access the global keyboard shortcut system. */
    static let shared = KeyboardShortcut()
    
    /** The current keyboard shortcut, as an integer. Value can range from 6 to 9 (inclusive), and corresponds to the keyboard shortcut Cmd + Shift + #, where # is the integer value of `current`. */
    var current: Int = UserDefaults.standard.object(forKey: storageKey) as? Int ?? 9 {
        didSet { updateShortcut(new: current) }
    }
    
    /** The action that is triggered whenever the user presses the current keyboard shortcut. */
    var action: (() -> ())? {
        didSet { updateAction(new: action) }
    }
    
    /** The current hot key object. Depends on the `HotKey` library to actually install the shortcut with macOS. We create a new hot key object whenever the user selects a new shortcut. */
    private var hotKey: HotKey?
    
    /** Set up the keyboard shortcut system. This initializer is defined as private to enforce the shared instance's singleton-ness. */
    private init() {
        updateShortcut(new: current)
    }
    
    /** Set up a new keyboard shortcut. This is an internal method that's called from the `didSet` for `current` to create a listener for the new shortcut. */
    private func updateShortcut(new number: Int) {
        
        // Sanitize the requested number to be between 6 and 9.
        let validNumber = KeyboardShortcut.validShortcuts.contains(number) ? number : 9
        
        // Start listening to the new key combination.
        let key: Key = [.six, .seven, .eight, .nine][validNumber - 6]
        hotKey = HotKey(key: key, modifiers: [.command, .shift])
        hotKey!.keyDownHandler = action
        
        // Also save the setting in user defaults.
        UserDefaults.standard.set(validNumber, forKey: storageKey)
    }
    
    /** Set up a new callback action. This is an internal method that's called from the `didSet` for `action` to update the hot key object with the new callback. */
    private func updateAction(new action: (() -> ())?) {
        if let hotKey = hotKey {
            hotKey.keyDownHandler = action
        }
    }
}
