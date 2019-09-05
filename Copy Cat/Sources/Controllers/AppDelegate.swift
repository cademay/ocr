//
//  AppDelegate.swift
//  Copy Cat
//
//  Created by Cade May on 4/22/19.
//  Copyright © 2019 21CFC. All rights reserved.
//

import Cocoa

/** The application delegate and main controller class. Per convention in macOS, an instance of this class serves as the delegate for the the `NSApplication` instance. This class also takes responsibility for being the primary controller for the app, so it sets up the user interface (i.e., the menu bar menu) and just sort of coordinates everything. */
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /** A reference to the app's status bar item. Necessary to hold onto this explicitly because of Swift's reference counting behavior. */
    var statusItem: NSStatusItem!
    
    /** Reference to the "Capture Text..." menu item. This reference is used to update thee item's *key equivalent* annotation whenever the user selects a new keyboard shortcut (see `shortcutItemPressed`). */
    let captureItem = NSMenuItem()
    
    /** Reference to the "Speak on Capture" menu item. This reference is used to update the "control state" (whether the item is checked or not) whenever the user enables or disables vocalization (see `updateVocalizationItem`). */
    let vocalizeItem = NSMenuItem()
    
    /** Reference to the "Copy Recent..." menu item. This reference is used to replace the sub-menu for this menu item whenever the list of recent captures changes (see `updateRecentsMenu`). */
    let recentsItem = NSMenuItem()
    
    /** Reference to the list of keyboard shortcut selection menu items. This is used so we can go through and update which item is checkmarked whenever the user changes the shortcut (see `shortcutItemPressed`). */
    var shortcutItems: [NSMenuItem] = []

    /** The capture window. This is a transparent window that covers the entire screen, used by the app to facilitate the box-selection interaction. It can be shown and hidden with `.open()` and `.close()` and will call its `.action` callback whenever the user selects a region on the screen. See `CaptureWindow` documentation for more details. */
    var captureWindow = CaptureWindow()

    /** Models. These provide access to the various core parts of the app. Each model is fairly self explanatory; see the documentation for each class for more details. Note that `SLTesseract` is not an internal model, but rather a reference to the Objective-C Tesseract library, which we use to recognize text in images. */
    let tesseract        = SLTesseract()
    let screenshots      = Screenshots.shared
    let keyboardShortcut = KeyboardShortcut.shared
    let recentCaptures   = RecentCaptures.shared
    let vocalization     = Vocalization.shared

    /** At launch time, this method configures the application's menubar item and sets up various callback functions for the application's models. Any other set-up code for the application should go here. */
    func applicationDidFinishLaunching(_: Notification) {
        setupStatusItem()
        
        //  Set the capture window's callback function, which will be called whenever the user selects a rectangular region on the screen. In this case, we want to close the capture window and then process the selected region.
        captureWindow.onCapture = { rect in
            self.captureWindow.close()
            DispatchQueue.main.async {
                self.userDidSelectRegion(rect: rect)
            }
        }
        
        keyboardShortcut.action = self.enterCaptureMode
        recentCaptures.onChange = self.updateRecentsMenu
        vocalization.onChange   = self.updateVocalizationItem
    }
    
    /** This method creates an `NSStatusItem`, which constitutes the primary user interface for this app. The `NSStatusItem` sits in the macOS menu bar. It also creates and attaches the corresponding dropdown menu using `createMainMenu`. */
    func setupStatusItem() {
        let statusBar: NSStatusBar = .system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button!.image = NSImage(named: "StatusIcon")!
        statusItem.menu = createMainMenu()
    }

    /** Create the app's dropdown menu, which serves as the primary user interface. All of the app's functionality is accessible through the menu and menu items that this method creates. */
    func createMainMenu() -> NSMenu {
        
        //  Create the capture item, which activates the app's primary functionality.
        captureItem.title = "Capture Text..."
        captureItem.action = #selector(AppDelegate.captureItemPressed(_:))
        captureItem.keyEquivalent = String(keyboardShortcut.current)
        captureItem.keyEquivalentModifierMask = [.shift, .command]
        
        //  Create the recent captures item, which houses a secondary dropdown for recently captured strings.
        recentsItem.title = "Copy Recent"
        recentsItem.submenu = createRecentsMenu()
        
        // Create the vocalize setting menu item.
        vocalizeItem.title = "Speak on Capture"
        vocalizeItem.action = #selector(AppDelegate.vocalizeItemPressed(_:))
        vocalizeItem.state = vocalization.isEnabled ? .on : .off
        
        // Create the keyboard shortcut buttons.
        shortcutItems = KeyboardShortcut.validShortcuts.map { i in
            let item = NSMenuItem()
            item.title = "⇧⌘" + String(i)
            item.action = #selector(AppDelegate.shortcutItemPressed(_:))
            item.tag = i
            item.state = (i == keyboardShortcut.current ? .on : .off)
            return item
        }
        
        // Create the quit button.
        let quitItem = NSMenuItem(title: "Quit Copy Cat",
                                  action: #selector(NSApplication.terminate(_:)),
                                  keyEquivalent: "")
        
        // Add everything to a menu.
        let mainMenu = NSMenu()
        mainMenu.minimumWidth = 200
        mainMenu.addItem(captureItem)
        mainMenu.addItem(.separator())
        mainMenu.addItem(recentsItem)
        mainMenu.addItem(.separator())
        mainMenu.addItem(.heading("Options"))
        mainMenu.addItem(vocalizeItem)
        mainMenu.addItem(.separator())
        mainMenu.addItem(.heading("Shortcut"))
        shortcutItems.forEach(mainMenu.addItem)
        mainMenu.addItem(.separator())
        mainMenu.addItem(quitItem)
        
        return mainMenu
    }
    
    /** Create the sub-menu of recent captures. Populated by the `RecentCaptures` model, which stores the list of recently captured strings. This can be called at any time to return a new menu containing the latest recent captures (see `updateRecentsMenu` for an example of such usage). */
    func createRecentsMenu() -> NSMenu {
        let menu = NSMenu()
        
        if recentCaptures.current.isEmpty {
            menu.addItem(.heading("Clear Menu"))
        } else {
            let action = #selector(AppDelegate.recentItemPressed(_:))
            for (i, recent) in recentCaptures.current.enumerated() {
                let label = recent.count > 25 ? recent.prefix(20) + "..." : recent
                let item = NSMenuItem(title: "\"\(label)\"", action: action, keyEquivalent: "")
                item.tag = i
                menu.addItem(item)
            }
            menu.addItem(.separator())
            menu.addItem(withTitle: "Clear Menu",
                         action: #selector(AppDelegate.clearRecentsItemPressed(_:)),
                         keyEquivalent: "")
        }
        
        return menu
    }
    
    /** Handle when the user has selected a particular rectangle (`rect`) on the screen for copying. Takes a screenshot of the specified region, converts it to text, and places it into the user's clipboard. */
    func userDidSelectRegion(rect: NSRect) {
        let image = screenshots.capture(rect: rect)

        // Invoke the OCR backend on the provided image.
        if let text = tesseract.recognize(image) {
            recentCaptures.add(text)
                
            // Copy the captured text to the clipboard.
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(text, forType: .string)
            
            // Vocalize captured text (if enabled).
            vocalization.say(text)
        }
    }
    
    /** Handle when the capture item (*i.e.*, "Capture Text...") is pressed. This will trigger the app to enter its *capture* mode. This method is annotated as `@objc` in order to allow it to be called by `NSMenuItem`s, which use Apple's legacy `Selector` interface. */
    @objc func captureItemPressed(_: Any) {
        enterCaptureMode()
    }
    
    /** Handle when a *recent capture* menu item has been pressed. This will trigger the app to re-copy that text to the user's clipboard. This method is annotated as `@objc` in order to allow it to be called by `NSMenuItem`s, which use Apple's legacy `Selector` interface.
     
    Note: this method uses the particular `NSMenuItem`'s `tag` property to identify which recent capture to copy. */
    @objc func recentItemPressed(_ sender: NSMenuItem) {
        let text = recentCaptures.current[sender.tag]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(text, forType: .string)
    }
    
    /** Handle when the user presses the "Clear Menu" item in the recently captured menu. Clears the app's recently captured strings storage. This method is annotated as `@objc` in order to allow it to be called by `NSMenuItem`s, which use Apple's legacy `Selector` interface. */
    @objc func clearRecentsItemPressed(_: NSMenuItem) {
        recentCaptures.clear()
    }
    
    /** Handle when the vocalization menu item (*i.e.*, "Speak on Capture") is pressed. This should toggle whether or not the app speaks its text every time the user selects something. This method is annotated as `@objc` in order to allow it to be called by `NSMenuItem`s, which use Apple's legacy `Selector` interface. */
    @objc func vocalizeItemPressed(_: Any) {
        vocalization.toggle()
    }
    
    /** Handle when one of the keyboard shortcut selection items is pressed. This uses the tag of the pressed button to determine which shortcut was selected, then updates the shortcut with the app's keyboard shortcut system. */
    @objc func shortcutItemPressed(_ sender: NSMenuItem) {
        
        //  Update actual hot key setting.
        keyboardShortcut.current = sender.tag
        
        //  Update the checkbox on the items to reflect the new value (so the user can see which item is selected).
        for item in shortcutItems {
            item.state = item === sender ? .on : .off
        }
        
        //  Update keyboard shortcut indicator in main menu.
        captureItem.keyEquivalent = String(sender.tag)
    }
    
    /** Enter the app's *capture* mode. Capture mode is characterized by switching the user's cursor to a crosshair and allowing them to draw a box over whatever part of the screen they want to select text from. This method opens the app's `CaptureWindow`—a transparent window that overlays the screen and allows the mouse to interact with it for the purpose of selecting a region of the screen. */
    func enterCaptureMode() {
        captureWindow.open()
    }
    
    /** Regenerate the recently captured text menu (i.e., "Copy Recent") with the latest list of captures. */
    func updateRecentsMenu() {
        recentsItem.submenu = createRecentsMenu()
    }
    
    /** Update the status of the vocalization toggle item to match the current vocalization state. */
    func updateVocalizationItem() {
        vocalizeItem.state = vocalization.isEnabled ? .on : .off
    }
}

extension NSMenuItem {
    
    /** Create a simple section heading menu item. A section heading is simply a disabled (greyed-out) menu item with no interactivity. */
    static func heading(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
