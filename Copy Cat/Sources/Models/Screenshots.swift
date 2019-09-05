//
//  Screenshots.swift
//  Copy Cat
//
//  Created by Cade May on 6/8/19.
//  Copyright © 2019 21CFC. All rights reserved.
//

import Foundation
import Cocoa

/** An interface for capturing images from the user's screen. This class is capable of returning an image of the entire screen or of a specified rectangular region of the screen. Within the MVC pattern, this class would most likely be considered a model. See `AppDelegate.swift` for usage. */
class Screenshots {
    
    /** Singleton pattern. Shared instance to be used anywhere the client wants to access the global screenshotter system. */
    static let shared = Screenshots()
    
    /** Take a screenshot of the entire main screen. */
    func captureScreen() -> NSImage {
        let mainDisplayID = CGMainDisplayID()
        let screenshot = CGDisplayCreateImage(mainDisplayID)!
        let size = CGSize(width: screenshot.width / 2, height: screenshot.height / 2)
        return NSImage(cgImage: screenshot, size: size)
    }
    
    /** Take a screenshot of just the part of the screen contained in `rect`. */
    func capture(rect: NSRect) -> NSImage? {
        
        // Capture the whole screen, then prepare a new image to hold a crop of the whole screen.
        let image = captureScreen()
        let processedImage = processImage(image: image, rect: rect)
        
        // Draw the whole-screen image into the cropped image in the appropriate location.
        let crop = NSImage(size: rect.size);
        NSGraphicsContext.saveGraphicsState()
        crop.lockFocus()
        processedImage.draw(in: NSRect(origin: -rect.origin, size: image.size))
        crop.unlockFocus()
        NSGraphicsContext.restoreGraphicsState()
        
        // for some reason, processing once more after cropping yields drastic improvements
        // then another time on top of that seems to help as well
        let processedCrop = processImage(image: crop, rect: rect)
        let output = processImage(image: processedCrop, rect: rect)
        
        return output
        
    }
    
    func processImage(image: NSImage, rect: NSRect) -> NSImage {
        
        let IMAGE_CONTRAST = 1.75
        
        let imageData = image.tiffRepresentation;
        
        var outputImage = NSImage();
        
        if let i = imageData {

            let coreImage = CIImage(data: i);
            let bwImage = coreImage?.applyingFilter("CIColorControls", parameters: ["inputSaturation": 0, "inputContrast": IMAGE_CONTRAST]);

            if let bw = bwImage {

                //Convert CIImage to NSImage
                let rep = NSCIImageRep(ciImage: bw)
                outputImage = NSImage(size: rep.size)
                outputImage.addRepresentation(rep)

            } else {

                // failure safety net
                outputImage = image

            }
        }
        
        return outputImage;
        
    }
    
    // helpful for debugging the image preprocessing step; allows you to see what's going on
    func saveImage(_ image: NSImage, path: String) -> URL {
        var rect = CGRect(origin: .zero, size: image.size)
        let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let data = bitmap.representation(using: .png, properties: [:])!
        
        let fileURL = URL(fileURLWithPath: path);
        
        do {
            try data.write(to: fileURL)
            print(fileURL)
        } catch {}
        return fileURL
    }
    
    
    func appSupportDirectory() -> URL {
        let fileManager = FileManager.default
        let globalDirURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let localDirURL = globalDirURL.appendingPathComponent("OCRTool")
        
        do {
            try fileManager.createDirectory(at: localDirURL,
                                            withIntermediateDirectories: false,
                                            attributes: nil)
        } catch {}
        
        return localDirURL
    }
}

/** Negate a `CGPoint`. */
prefix func -(a: CGPoint) -> CGPoint {
    return CGPoint(x: -a.x, y: -a.y)
}

