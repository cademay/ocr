


/*********************************************  AppDelegate.swift *********************************************/



func applicationDidFinishLaunching(_ aNotification: Notification) 
At launch time, this method configures the application's menubar item, and activates the hotkey system. Hotkeys allow the user to access the ocr functionality from anywhere in their computer by entering a keyboard shortcut. 




@objc func captureTextPressed(_ sender: Any?):
This method is called when the menubar item's "Capture Text" button is pressed. It calls enterOcrMode, which instantiates a CaptureWindow. A CaptureWindow is a transparent window that overlays the screen and allows the mouse to interact with it for the purpose of selecting a region of the screen. This method has to import @obj in order to be compatible with the NSMenuItems. model.enterOcrMode() is decomposed into its own function so that it can be called from other parts of the app, like from global hotkeys. 




@objc func openPreferencesWindow(_ sender: Any?):
This method is called when the menubar item's "Preferences" button is pressed. It instantiates a window through which users can configure their preferred settings for the app. The window that it instantiates, PreferencesView, exists in the main storyboard: main.storyboard.

func createStatusItem() -> NSStatusItem 
This method creates an NSStatusItem, which constitutes the primary user interface for this app. The NSStatusItem sits in the main menu bar of the Mac operating system. It also creates and attaches the corresponding dropdown menu by calling "createDropdownMenu".


func createDropdownMenu() -> NSMenu:
This method creates the app's dropdown menu, which serves as the primary user interface. All of the app's functionality is accessible through the menu and MenuItems that this method creates.








 /*********************************************  CaptureWindow.swift *********************************************/






 /*********************************************  PreferencesViewController.swift *********************************************/
 
 
  override func viewDidLoad() 
 This method is called as the PreferencesView is launched. It uses the PreferencesModel to query the app's storage for the user's stored settings, and then updates the UI accordingly.


  @IBAction func vocalizeCheckBoxAction(_ sender: NSButton) 
 This method is the action associated with the "Vocalize Captured Text?" checkbox available in the preferences menu. It reads the user's selection for the corresponding setting and then saves it to the UserDefaults storage system. 


  func updateUI()
 This method updates all of the UI labels so that they correspond to the settings configuration.

 
override func viewWillDisappear() 
This method is called when the preferences window is closing. It saves all of the user's preferences selections to the UserDefaults storage system. 

func saveVitals() 
 This method saves all of the user's preferences selections to the UserDefaults storage system. 

