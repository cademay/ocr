//
//  RecentCaptures.swift
//  Copy Cat
//
//  Created by Toby Bell on 6/7/19.
//  Copyright © 2019 21CFC. All rights reserved.
//

import HotKey

/** The key used to store the list of recently captured strings in the user defaults store. Note: it is probably best not to touch this; changing this will cause the app to forget the list of recent captures. */
private let storageKey: String = "RecentCaptures"

/** Number of recent captures to remember until we start forgetting old ones. */
private let maxRecentCaptures: Int = 8

/** Interface for the recetly captured strings system. This class allows adding new recent captures, retrieving the list of recent captures, and clearing the list of recent captures. */
class RecentCaptures {
    
    /** Singleton pattern. Shared instance to be used anywhere the client wants to access the global recent captures system. */
    static let shared = RecentCaptures()
    
    /** The current list of recently captured strings. It is guaranteed to contain no more than `maxRecentCaptures` items. */
    private (set) var current: [String] = UserDefaults.standard.object(forKey: storageKey) as? [String] ?? []
    
    /** Change callback function. This function will be called whenever the current list of recent captures changes. */
    var onChange: (() -> ())?
    
    /** Add a new recent capture. If the list of recent captures has reached its maximum length, this will cause the system to forget the oldest one. */
    func add(_ new: String) {
        current.insert(new, at: 0)
        current.removeLast(max(current.count - maxRecentCaptures, 0))
        UserDefaults.standard.set(current, forKey: storageKey)
        onChange?()
    }
    
    /** Clear the list of recently captured strings. */
    func clear() {
        current = []
        UserDefaults.standard.set(current, forKey: storageKey)
        onChange?()
    }
}
