//
//  Vocalization.swift
//  Copy Cat
//
//  Created by Toby Bell on 6/7/19.
//  Copyright © 2019 21CFC. All rights reserved.
//


/** The key used to store whether or not vocalization is enabled in the user defaults store. Note: it is probably best not to touch this; changing this will cause the app to forget the user's preference for vocalization. */
private let isEnabledKey: String = "Vocalization"

/** Interface for the vocalization system. This class allows for keeping track of whether or not vocalization is enabled (persistently, between application runs) and speaking strings via the macOS text-to-speech `say` app. Within the MVC pattern, this class would most likely be considered a model. See `AppDelegate.swift` for usage. */
class Vocalization {
    
    /** Singleton pattern. Shared instance to be used anywhere the client wants to access the global vocalization system. */
    static let shared = Vocalization()
    
    /** Whether or not vocalization is currently enabled. If it is disabled, then calling `say` will be a no-op. */
    var isEnabled: Bool = UserDefaults.standard.object(forKey: isEnabledKey) as? Bool ?? false {
        didSet { updateIsEnabled(new: isEnabled) }
    }
    
    /** Change callback function. This function will be called whenever the is-enabled state of the vocalization system changes. */
    var onChange: (() -> ())?
    
    /** Toggle the current `isEnabled` state. This is simply a cenvenience method for flipping the `isEnabled` variable. */
    func toggle() {
        isEnabled = !isEnabled
    }

    /** Speak a string, if vocalization is enabled. If vocalization is not enabled, this method will not do anything. This uses the system's built-in `say` executable. */
    func say(_ text: String) {
        if isEnabled {
            let say = Process()
            say.launchPath = "/usr/bin/say"
            say.arguments = [text]
            do { try say.run() } catch {}
        }
    }
    
    /** Update based on the new is-enabled state. Saves the value to the persistent store. This is an internal method, only called when the `isEnabled` value is set by someone. */
    private func updateIsEnabled(new isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: isEnabledKey)
        onChange?()
    }
}
