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
// MARK: - App Delegate Notifier Protocol
/* ################################################################################################################################## */
/**
 This protocol allows view controllers to register for updates.
 */
protocol RVS_MediaServer_AppDelegateNotifier {
    /* ################################################################## */
    /**
     Called by the app delegate to ask registrants to re-up their UI.
     */
    func updateUI()
}

/* ################################################################################################################################## */
// MARK: - Main Application Delegate Class
/* ################################################################################################################################## */
/**
 This class implements the main application delegate.
 
 It has a couple of class methods and calculated properties that you can use to get a context.
 */
@NSApplicationMain
class RVS_MediaServer_AppDelegate: NSObject, NSApplicationDelegate {
    /* ################################################################## */
    /**
     This just holds the view controllers that request updates.
     */
    private var _notifierClients: [RVS_MediaServer_AppDelegateNotifier?] = []
    
    /* ################################################################## */
    /**
     This holds our registered observers. They need to be kept around.
     */
    private var _registeredObservers: [NSKeyValueObservation] = []
    
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
     This is the prefs object that we'll use to maintain our persistent state.
     */
    @objc dynamic var prefsObject: RVS_MediaServer_PersistentPrefs! = nil
    
    /* ############################################################################################################################## */
    // MARK: - Internal Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Accessor for the prefs state (READ ONLY).
     
     make it dynamic, so that we could attach observers.
     */
    @objc dynamic var prefs: RVS_MediaServer_PersistentPrefs {
        if nil == prefsObject {
            prefsObject = RVS_MediaServer_PersistentPrefs(key: "0") // The first one is the main, or default one. Its tag will be "0."
        }
        
        return prefsObject   // I deliberately want this to crash if it is not available.
    }

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
    // MARK: - Internal Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This adds a notifier to our list (if not already there).
     
     - parameter inNotifier: The notifier (View Controller) to be added.
     */
    func addNotifier(_ inNotifier: RVS_MediaServer_AppDelegateNotifier) {
        if !_notifierClients.contains(where: { (element) -> Bool in
            if  let element = element as? NSViewController,
                let inNotifier = inNotifier as? NSViewController {
                return inNotifier == element
            }
            
            return false
        }) {
            _notifierClients.append(inNotifier)
        }
    }
    
    /* ################################################################## */
    /**
     This removes a notifier from our list.
     
     - parameter inNotifier: The notifier (View Controller) to be removed.
     */
    func removeNotifier(_ inNotifier: RVS_MediaServer_AppDelegateNotifier) {
        if let index = _notifierClients.firstIndex(where: { (element) -> Bool in
            if  let element = element as? NSViewController,
                let inNotifier = inNotifier as? NSViewController {
                return inNotifier == element
            }
            
            return false
        }) {
            _notifierClients.remove(at: index)
        }
    }
    
    /* ################################################################## */
    /**
     This sends UI updates to all registered notifier clients.
     */
    func forceUpdate() {
        DispatchQueue.main.async {  // Must be in the main thread.
            self._notifierClients.forEach {
                $0?.updateUI()
            }
        }
    }

    /* ############################################################################################################################## */
    // MARK: - NSApplicationDelegate Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     */
    func applicationDidFinishLaunching(_ inNotification: Notification) {
        if prefs.prefs_window_open {
            if let myPreferencesController = NSStoryboard.main?.instantiateController(withIdentifier: "SETTINGS") as? RVS_MediaServer_WindowController {
                myPreferencesController.showWindow(nil)
            }
        }
        
        _registeredObservers.append(observe(\.prefsObject?.use_raw_parameters, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.use_output_http_server, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.login_id, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.password, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.output_tcp_port, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.input_uri, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.temp_directory_name, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
        _registeredObservers.append(observe(\.prefsObject?.rawFFMPEGString, options: [], changeHandler: { [unowned self] _, _ in self.forceUpdate() }))
    }
}
