//
//  README_models.md
//  ocrTool
//
//  Created by Cade May on 5/25/19.
//  Copyright © 2019 Cade May. All rights reserved.
//

/*********************************************  AppDelegateModel.swift *********************************************/


func enterOcrMode():
This method activates the application's primary functionality: allowing users to capture any text visible on their screen. It does so by instantiating a CaptureWindow. A CaptureWindow is a transparent window that overlays the screen and allows the mouse to interact with it for the purpose of selecting a region of the screen. This method provides a callback function, which performs OCR on the region of the screen selected through the CaptureWindow. The callback function performs OCR on the selected image and then copies the corresponding text to the clipboard. 



func saveImage(_ image: NSImage) -> URL 


func runTesseract(_ url: URL) -> String? 


func appSupportDirectory() -> URL 



func sayIt(_ text: String) 


/* This method queries UserDefaults for information on the user's preference vocalization setting. If the user has indicated that the captured text should be spoken by the computer, then this returns true. */
func vocalizeSettingIsOn () -> Bool {




private var hotKey: HotKey? 
This is the HotKey variable, which allows users to access the app's functionality globally via keyboard shortcuts.





/*********************************************  CaptureWindowModel.swift *********************************************/


func createTargetImage() -> NSImage



func getScreenShot() -> NSImage 
This method takes a screenshot of the entire screen using the CGDisplayCreateImage() method. Then, it converts the image to an NSImage and returns it.


func boundingRect(_ a: CGPoint, _ b: CGPoint) -> NSRect 







/*********************************************  PreferencesModel.swift *********************************************/


init() 
/* This method is called when a new instance of a preferences window is created. It prepares the relevant variables for the setting up of the corresponding view. */

func configureVitalVariables()
/* This method helps to set up the view by checking UserDefaults for any previously stored preferences. */

func getVocalizeSetting() -> Int 
/* This method queries the UserDefaults storage system. If a vocalize setting has been saved, it returns it. Otherwise, it returns the default value, which is 0. */

