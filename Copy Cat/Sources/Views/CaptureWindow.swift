//
//  CaptureWindow.swift
//  Copy Cat
//
//  Created by Cade May on 5/3/19.
//  Copyright © 2019 21CFC. All rights reserved.
//


import Cocoa

/** A screen-covering transparent window capable of managing a drag interaction. Call `open` and `close` to show and hide the window, and set `action` to the desired callback in order to be notified when the user selects a rectangle on the screen. */
class CaptureWindow: NSPanel, NSWindowDelegate {
    
    /** The callback function that the window should invoke when a drag is completed. This function should accept an `NSRect` object, representing the region that the user selected. */
    var onCapture: ((NSRect) -> Void)?
    
    /** The feedback view used to show the user the currently selected region while dragging. */
    private let dragBox = NSView(frame: .zero)
    
    /** Starting point for a drag action. Set in `mouseDown`. If the user is not currently dragging, this will be `nil`. */
    private var dragStart: CGPoint?
    
    /** Current ending point for a drag action. Updated in `mouseDragged`. If the user is not currently dragging or has not yet moved their mouse in a particular drag, this will be `nil`.*/
    private var dragEnd: CGPoint?

    private let cursor = NSImageView(image: NSCursor.crosshair.image)
    
    /** Create a new capture window. Set's up appearanges, behaviors, things like that. This will not open the window. */
    init() {
        
        // WTF
        let pString = CFStringCreateWithCString(kCFAllocatorDefault, "SetsCursorInBackground", 0)
        CGSSetConnectionProperty(_CGSDefaultConnection(), _CGSDefaultConnection(), pString, kCFBooleanTrue)
        
        //  Get a reference to the main (currently focused) screen. If it fails, oh well!
        let screen = NSScreen.main!
        
        //  Initialize the window superclass to be a borderless window that covers the whole screen.
        super.init(contentRect: screen.frame,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        
        //  Ensure that the window can always appear above all other windows.
        level = .screenSaver
        
        collectionBehavior = [.stationary, .moveToActiveSpace, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = false
        
        //  We want the user to be able to see everything on their screen as usual.
        backgroundColor = .clear
        
        //  Oi macOS, you ain't off the hook! Since the window will be transparent, tell macOS that it has to keep rendering things behind it.
        isOpaque = false
        
        //  *However*, even though the window is transparent, we still want it to receieve mouse events (so the user can drag their mouse on it.
        ignoresMouseEvents = false
        
        // Init drag box
        dragBox.layer = CALayer()
        dragBox.layer!.borderColor = .white
        dragBox.layer!.borderWidth = 1
        dragBox.layer!.backgroundColor = CGColor(gray: 0, alpha: 0.13)
        
        
        contentView!.addSubview(dragBox)

        // Add our custom cursor image to the window.
        contentView!.addSubview(cursor)
        cursor.frame = CGRect(origin: .zero, size: cursor.image!.size)

        // Disable shadow computation; otherwise moving the cursor is super slow.
        hasShadow = false
        
        // Create a tracking area, so we can follow the mouse around even if we're not the active app.
        contentView!.addTrackingArea(NSTrackingArea(rect: contentView!.bounds, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
    }
    
    /** Open the window. Since this window is never *really* closed (see `close`), opening it simply means bringing it to the front. */
    func open() {
        CGDisplayHideCursor(kCGNullDirectDisplay)
        DispatchQueue.main.async {
            self.makeKeyAndOrderFront(nil)
        }
    }
    
    /** Close the window. Overriden to simply hide the window from the screen rather than truly "close" it, which is irreversible. */
    override func close() {
        orderOut(nil)
        DispatchQueue.main.async {
            CGDisplayShowCursor(kCGNullDirectDisplay)
        }
    }
    
    func updateCursor(position: NSPoint) {
        let width = cursor.frame.width
        let height = cursor.frame.height
        cursor.setFrameOrigin(NSPoint(x: position.x - width / 2, y: position.y - height / 2))
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Update the cursor position.
        updateCursor(position: event.locationInWindow)
    }
    
    override func mouseEntered(with event: NSEvent) {
        // Update the cursor position.
        updateCursor(position: event.locationInWindow)
    }
    
    /** Handle mouse-down actions on the capture window. This records the start of a drag action. */
    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
    }
    
    /** Handle mouse-dragged actions on the capture window. This records the latest ending position of the current drag action and updates the visible selection box to match. */
    override func mouseDragged(with event: NSEvent) {
        
        //  Update the ending position of the drag. This also has the effect of recording that the user has dragged their mouse at least once since beginning the drag.
        dragEnd = event.locationInWindow
        
        //  Update the visible drag box's frame based on the latest ending position.
        dragBox.frame = boundingRect(dragStart!, dragEnd!)
        
        // Update the cursor position.
        updateCursor(position: event.locationInWindow)
    }
    
    /** Handle mouse-up actions on the capture window. If a drag was made, this will call the action callback for the capture window (set in `init`) with the relevant part of the screen. */
    override func mouseUp(with event: NSEvent) {
        
        //  Only take action if the user actually dragged their mouse (and not if they simply clicked it without moving it).
        if dragEnd != nil {
            
            // Little kludgy; just move the cursor off the screen so it's not there when the view pops back up before we reposition it.
            updateCursor(position: NSPoint(x: -100, y: -100))
            let rect = dragBox.frame
            
            // Reset drag trackers.
            dragStart = nil
            dragEnd = nil
            dragBox.frame = .zero
            
            onCapture?(rect)
        }
    }
    
    /** Compute the bounding box for two points. The two points will form two opposite corners of the resulting box---either top-left and bottom-right or top-right and bottom-left, depending on the particular placement of the points. */
    private func boundingRect(_ a: CGPoint, _ b: CGPoint) -> NSRect {
        let x0 = floor(min(a.x, b.x))
        let y0 = floor(min(a.y, b.y))
        let x1 = ceil(max(a.x, b.x))
        let y1 = ceil(max(a.y, b.y))
        return NSRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
}
