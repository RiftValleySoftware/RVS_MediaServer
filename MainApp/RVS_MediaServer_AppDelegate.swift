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
/// This is the dependency for a small, embedded GCD Web server.
import GCDWebServers

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
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This contains the "mini webserver" that we use to serve the converted HSL stream.
     */
    var webServer: GCDWebServer! = nil
    
    /* ################################################################## */
    /**
     This is the prefs object that we'll use to maintain our persistent state.
     */
    var prefs: RVS_PersistentPrefs! = nil

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
        alert.addButton(withTitle: "SLUG-OK-BUTTON-TEXT".localizedVariant)
        alert.runModal()
    }
    
    /* ################################################################## */
    /**
     */
    func startWebServer() {
        webServer = GCDWebServer()
        
        webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { _ in
            return GCDWebServerDataResponse(html: "<html><body><p>Hello World</p></body></html>")
        })
        
        webServer.start(withPort: 8080, bonjourName: "RVS_MediaServer")
        
        if let uri = webServer.serverURL {
            print("Visit \(uri) in your web browser")
        } else {
            print("Error in Setting Up the Web Server!")
        }
    }
    
    /* ############################################################################################################################## */
    // MARK: - NSApplicationDelegate Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startWebServer()
    }

    /* ################################################################## */
    /**
     */
    func applicationWillTerminate(_ aNotification: Notification) {
    }
}
