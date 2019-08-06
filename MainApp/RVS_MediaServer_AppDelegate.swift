/**
 © Copyright 2019, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import Cocoa

/* ############################################################################################################################## */
// MARK: - Main Application Class
/* ############################################################################################################################## */
/**
 This is an extension to the standard NSView class, so we can see if we are in "dark mode."
 Cribbed from here: https://stackoverflow.com/a/52523517/879365
 */
extension NSView {
    /* ################################################################## */
    /**
     - returns: True, if the app is in Dark Mode.
     */
    var isDarkMode: Bool {
        if #available(OSX 10.14, *) {
            return .darkAqua == effectiveAppearance.name
        }
        
        return false
    }
}

/* ############################################################################################################################## */
// MARK: - Main Application Class
/* ############################################################################################################################## */
/**
 This class implements the main application delegate.
 
 It has a couple of class methods and calculated properties that you can use to get a context.
 */
@NSApplicationMain
class RVS_MediaServer_AppDelegate: NSObject, NSApplicationDelegate {
    /* ############################################################################################################################## */
    // MARK: - Internal Class Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a quick way to get this object instance (it's a SINGLETON), cast as the correct class.
     
     - returns: the app delegate object, in its natural environment.
     */
    class var appDelegateObject: RVS_MediaServer_AppDelegate {
        return (NSApplication.shared.delegate as? RVS_MediaServer_AppDelegate)!
    }

    /* ############################################################################################################################## */
    // MARK: - Internal Class Functions
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     */
    class func displayAlert(header inHeader: String, message inMessage: String = "") {
        let alert = NSAlert()
        alert.messageText = inHeader
        alert.informativeText = inMessage
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    /* ############################################################################################################################## */
    // MARK: - NSApplicationDelegate Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    /* ################################################################## */
    /**
     */
    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
