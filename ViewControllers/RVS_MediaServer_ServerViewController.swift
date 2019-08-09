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
// MARK: - Main View Controller Class
/* ################################################################################################################################## */
/**
 */
class RVS_MediaServer_ServerViewController: RVS_MediaServer_BaseViewController {
    /* ############################################################################################################################## */
    // MARK: - Internal IB Instance Properties
    /* ############################################################################################################################## */
    
    /* ################################################################## */
    /**
     This label shows the server status. If running, the color is green. If stopped, the color is red.
     */
    @IBOutlet weak var serverStatusLabel: NSTextField!
    
    /* ################################################################## */
    /**
     This button will either start or stop the server.
     */
    @IBOutlet weak var startStopButton: NSButton!
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     We use this to observe the current Web Server status
     */
    var serverStatusObserver: NSKeyValueObservation?

    /* ############################################################################################################################## */
    // MARK: - Internal Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This starts the streaming server.
     */
    func startServer() {
        prefs.isRunning = true
    }
    
    /* ################################################################## */
    /**
     This stops the streaming server.
     */
    func stopServer() {
        prefs.isRunning = false
    }
    
    /* ############################################################################################################################## */
    // MARK: - Internal IBAction Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This starts or stops the streaming server, depending on the state of the server.
     */
    @IBAction func startStopButtonHit(_ sender: NSButton) {
        if prefs.isRunning {
            stopServer()
        } else {
            startServer()
        }
    }
    
    /* ############################################################################################################################## */
    // MARK: - Internal Callback Handler Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is an observer callback that handles changes in the prefs server running status.
     
     - parameter inObject: The object that is being changed. We ignore it.
     - parameter inChange: The change object. We ignore this, too.
     */
    func serverStatusObserverHandler(_ inObject: Any, _ inChange: NSKeyValueObservedChange<Bool>! = nil) {
        if prefs.isRunning {
            serverStatusLabel.textColor = NSColor.green
            serverStatusLabel.stringValue = "SLUG-SERVER-IS-RUNNING".localizedVariant
            startStopButton.title = "SLUG-STOP-SERVER".localizedVariant
        } else {
            serverStatusLabel.textColor = NSColor.red
            serverStatusLabel.stringValue = "SLUG-SERVER-IS-NOT-RUNNING".localizedVariant
            startStopButton.title = "SLUG-START-SERVER".localizedVariant
        }
    }
    
    /* ############################################################################################################################## */
    // MARK: - Superclass Override Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Set up the various localized items and initial values.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        serverStatusObserver = observe(\.prefs.isRunning, changeHandler: serverStatusObserverHandler)
        serverStatusObserverHandler(prefs)
    }
}
