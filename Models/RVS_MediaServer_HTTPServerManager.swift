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
// MARK: - Main HTTP Server Manager Class
/* ################################################################################################################################## */
/**
 This is a model for the server status screen. It handles the management of the actual ffmpeg instance, and any HTTP server we set up.
 */
class RVS_MediaServer_HTTPServerManager {
    /* ############################################################################################################################## */
    // MARK: - Private Static Propeties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     The size of time slices in the HLS output. ffmpeg defaults to 2. Apple recommends 6.
     */
    static private let _hlsTimeSliceInSeconds: Int = 2
    
    /* ################################################################## */
    /**
     The number of seconds to wait between page refreshes, while waiting to load.
     */
    static private let _pageReloadDelayInSeconds: Float = 1.0
    
    /* ################################################################## */
    /**
     The number of seconds to wait as a timeout, when starting the server.
     */
    static private let _serverStartTimeoutThresholdInSeconds: TimeInterval = 10.0
    
    /* ############################################################################################################################## */
    // MARK: - Private Instance Propeties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a timer that we use to trap too long a wait.
     */
    private var _timeoutTimer: Timer!

    /* ################################################################## */
    /**
     This will hold the url of our output streaming file.
     */
    private var _outputTmpFile: TemporaryFile!
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a Web Server instance that is associated with this stream. Its lifetime is the lifetime of the object (not persistent).
     */
    var webServer: GCDWebServer?
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a direct accessor to the app prefs object for this instance. We just access the main App Delegate prefs.
     */
    var prefs: RVS_MediaServer_PersistentPrefs {
        return RVS_MediaServer_AppDelegate.appDelegateObject.prefs
    }

    /* ################################################################## */
    /**
     Accessor for the temporary HTTP server file.
     */
    var tempOutputFileURL: URL! {
        return _outputTmpFile?.fileURL
    }
    
    /* ################################################################## */
    /**
     Accessor for the temporary HTTP server directory.
     */
    var tempOutputDirURL: URL! {
        return _outputTmpFile?.directoryURL
    }

    /* ############################################################################################################################## */
    // MARK: - Initializer
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     - parameter outputTmpFile: The temporary file object that describes the temporary directory, where we fetch our data.
     */
    init(outputTmpFile inOutputTmpFile: TemporaryFile) {
        _outputTmpFile = inOutputTmpFile
    }
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This simply starts the Web server.
     
     - parameter webServerHandler: This is an optional handling closure for Web Server calls.
     If not provided (or set to nil), then whatever we already have is used. This will replace any existing handler.
     */
    func startHTTPServer() {
        if  nil == webServer || !(webServer?.isRunning ?? false),
            let tempPath = tempOutputDirURL?.path {
            webServer = GCDWebServer()
            
            // Add a default get handler to make sure that the stream file is considered our index.
            webServer?.addGETHandler(forBasePath: "/", directoryPath: tempPath, indexFilename: "stream.m3u8", cacheAge: 3600, allowRangeRequests: true)
            // Make sure that our handler is called for all requests.
            webServer?.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: webServerHandler)
            _timeoutTimer = Timer(fire: Date(), interval: type(of: self)._serverStartTimeoutThresholdInSeconds, repeats: false, block: timerDone)
            webServer?.start(withPort: UInt(prefs.output_tcp_port), bonjourName: prefs.stream_name)
            if !(webServer?.isRunning ?? false) {
                handleError(message: "SLUG-CANNOT-START-WEBSERVER-MESSAGE")
            }
        }
    }

    /* ################################################################## */
    /**
     This simply stops the Web server.
     */
    func stopHTTPServer() {
        _timeoutTimer?.invalidate()
        _timeoutTimer = nil
        webServer?.stop()
        webServer = nil
    }

    /* ################################################################## */
    /**
     This will throw up an error alert, if we encounter an error.
     
     - parameter messag: A string, with the error message to be displayed, in un-localized form.
     */
    func handleError(message inMessage: String = "") {
        DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
            RVS_MediaServer_AppDelegate.displayAlert(header: "SLUG-SERVER-ERROR-HEADER".localizedVariant, message: inMessage.localizedVariant)
        }
    }

    /* ############################################################################################################################## */
    // MARK: - Internal Callback Handler Methods
    /* ############################################################################################################################## */    
    /* ################################################################## */
    /**
     This is the HTTP server callback. It is called with HTTP requests from the server, and we handle it all here.
     
     - parameter inRequestObject: The request from the server.
     
     - returns: A data response; usually some form of HTML or stream data.
     */
    func webServerHandler(_ inRequestObject: GCDWebServerRequest) -> GCDWebServerDataResponse! {
        #if DEBUG
            print("Requested URI: " + String(describing: inRequestObject))
        #endif
        
        // If they are requesting the animated throbber GIF, then we give it to them.
        if  "/throbber.gif" == inRequestObject.path,
            let resourceURL = Bundle.main.url(forResource: "throbber", withExtension: "gif") {
            
            if let throbberData = try? Data(contentsOf: resourceURL) {
                return GCDWebServerDataResponse(data: throbberData, contentType: "application/gif")
            }
        } else {
            // If we have started to build up video data files, then we stop the server, strip out this handler, and then restart it.
            if  let path = tempOutputDirURL?.path,
                let dirContents = try? FileManager.default.contentsOfDirectory(atPath: path),
                1 < dirContents.count {
                #if DEBUG
                    print("Restarting the Server")
                #endif
                // Kill our timeout clock.
                _timeoutTimer?.invalidate()
                _timeoutTimer = nil
                webServer?.stop()
                webServer?.removeAllHandlers()
                // Re-add the default handler for the directory.
                webServer?.addGETHandler(forBasePath: "/", directoryPath: path, indexFilename: "stream.m3u8", cacheAge: 3600, allowRangeRequests: true)
                webServer?.start()
                // We emit a "LOADING..." text, and set the browser to refresh in one second.
                var retHTML = "<html><head><meta http-equiv=\"refresh\" content=\""
                retHTML += String(type(of: self)._pageReloadDelayInSeconds)
                retHTML += "; URL=/\"></head><body style=\"background-color:black\"><h1 style=\"font-family:Helvetica,Sans-serif;margin:0;margin-top:-0.5em;text-align:center;position:absolute;top:50%;left:0;width:100%;color: white\">"
                retHTML += "SLUG-LOADING".localizedVariant
                retHTML += "</h1></body></html>"
                return GCDWebServerDataResponse(html: retHTML)
            }
        }
        
        var retHTML = "<html><head><meta http-equiv=\"refresh\" content=\""
        retHTML += String(type(of: self)._pageReloadDelayInSeconds)
        retHTML += "; URL=/\"></head><body style=\"background-color:black\"><img src=\"throbber.gif\" style=\"display:block;position:absolute;top:50%;left:50%;margin-left:-16px;margin-top:-16px\" /></body></html>"
        return GCDWebServerDataResponse(html: retHTML)
    }

    /* ################################################################## */
    /**
     This will catch a timeout, stop the server, and throw up an error alert.
     */
    @objc func timerDone(_ inTimer: Timer) {
        #if DEBUG
            print("Timeout!")
        #endif
        stopHTTPServer()
        handleError(message: "SLUG-TIMEOUT-MESSAGE")
    }

    /* ############################################################################################################################## */
    // MARK: - Deinit
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Make sure that we stop the server upon dealloc.
     */
    deinit {
        stopHTTPServer()
    }
}
