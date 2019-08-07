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

/* ################################################################################################################################## */
// MARK: - Main View Controller Class
/* ################################################################################################################################## */
/**
 */
class RVS_MediaServer_SettingsViewController: NSViewController {
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This contains the "mini webserver" that we use to serve the converted HSL stream.
     */
    private var _webServer: GCDWebServer! = nil
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This simply starts the Web server.
     */
    func startWebServer() {
        _webServer = GCDWebServer()
        
        _webServer.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: { _ in
            return GCDWebServerDataResponse(html: "<html><body><p>Hello World</p></body></html>")
        })
        
        _webServer.start(withPort: 8080, bonjourName: "RVS_MediaServer")
        
        if let uri = _webServer.serverURL {
            print("Visit \(uri) in your web browser")
        } else {
            print("Error in Setting Up the Web Server!")
        }
    }

    /* ############################################################################################################################## */
    // MARK: - Superclass Override Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /* ################################################################## */
    /**
     */
    override var representedObject: Any? {
        didSet {
        }
    }
}
