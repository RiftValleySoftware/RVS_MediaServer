/*
 This is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 
 This Software is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this code.  If not, see <http: //www.gnu.org/licenses/>.

 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import Cocoa

/* ################################################################################################################################## */
// MARK: - Main Application Class
/* ################################################################################################################################## */
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
    // MARK: - Internal Enums
    /* ############################################################################################################################## */

    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is the prefs object that we'll use to maintain our persistent state.
     */
    fileprivate var _prefs: RVS_MediaServer_PersistentPrefs! = nil
    
    /* ############################################################################################################################## */
    // MARK: - Internal Calculated Properties
    /* ############################################################################################################################## */

    /* ############################################################################################################################## */
    // MARK: - Internal Class Functions
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This displays a simple alert, with an OK button.
     
     - parameter header: The header to display at the top.
     - parameter message: A String, containing whatever messge is to be displayed below the header.
     */
    class func displayAlert(header inHeader: String, message inMessage: String = "") {
        let alert = NSAlert()
        alert.messageText = inHeader
        alert.informativeText = inMessage
        alert.addButton(withTitle: "SLUG-OK-BUTTON-TEXT".localizedVariant)
        alert.runModal()
    }
    
    /* ############################################################################################################################## */
    // MARK: - NSApplicationDelegate Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _prefs = RVS_MediaServer_PersistentPrefs()
    }

    /* ################################################################## */
    /**
     */
    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
