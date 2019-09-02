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

/// This is the dependency for a small, embedded GCD Web server.
import GCDWebServers

/* ################################################################################################################################## */
// MARK: - Delegate Protocol
/* ################################################################################################################################## */
/**
 These are methods that can be called from the manager to a registered delegate.
 
 They are all called on the main thread, and are all optional.
 */
protocol RVS_MediaServer_HTTPServerManagerDelegate: class {
    /* ################################################################## */
    /**
     Called if there was an error encountered.
     
     - parameter manager: The manager object
     - parameter httpError: The text received.
     */
    func mediaServerManager( _ manager: RVS_MediaServer_HTTPServerManager, httpError: String)
}

/* ################################################################################################################################## */
// MARK: - Delegate Protocol Extension
/* ################################################################################################################################## */
/**
 This is an extension that allows the protocol methods to be optional.
 
 They do nothing.
 */
extension RVS_MediaServer_HTTPServerManagerDelegate {
    /* ################################################################## */
    /**
     Called if there was an error encountered.
     
     - parameter: ignored
     - parameter httpError: ignored
     */
    func mediaServerManager( _ manager: RVS_MediaServer_HTTPServerManager, httpError: String) { }
}

/* ################################################################################################################################## */
// MARK: - Main HTTP Server Manager Class
/* ################################################################################################################################## */
/**
 This is a model for the HTTP server instance.
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
    private var _outputTmpFile: URL!
    
    /* ################################################################## */
    /**
     */
    private let _port: Int
    
    /* ################################################################## */
    /**
     */
    private let _streamName: String

    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a Web Server instance that is associated with this stream. Its lifetime is the lifetime of the object (not persistent).
     */
    var webServer: GCDWebServer?

    /* ################################################################## */
    /**
     A delegate object for handling the operation of the manager. This is a weak class reference.
     */
    weak var delegate: RVS_MediaServer_HTTPServerManagerDelegate!

    /* ############################################################################################################################## */
    // MARK: - Internal Instance Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Accessor for the temporary HTTP server directory.
     */
    var tempOutputDirURL: URL! {
        return _outputTmpFile?.deletingLastPathComponent()
    }

    /* ############################################################################################################################## */
    // MARK: - Initializer
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     - parameter outputTmpFile: The URL for a temporary file object that describes the temporary index file and directory, where we fetch our data.
     - parameter port: A TCP Port for the server to use.
     - parameter streamname: A name to use for the stream.
     - parameter delegate: The delegate for the object. This is optional.
     */
    init(outputTmpFile inOutputTmpFile: URL, port inPort: Int, streamName inStreamName: String, delegate inDelegate: RVS_MediaServer_HTTPServerManagerDelegate! = nil) {
        _outputTmpFile = inOutputTmpFile
        _port = inPort
        _streamName = inStreamName
        delegate = inDelegate
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
            webServer?.addGETHandler(forBasePath: "/", directoryPath: tempPath, indexFilename: _outputTmpFile?.lastPathComponent, cacheAge: 3600, allowRangeRequests: true)
            // Make sure that our handler is called for all requests.
            webServer?.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: webServerHandler)
            _timeoutTimer = Timer(fire: Date(), interval: type(of: self)._serverStartTimeoutThresholdInSeconds, repeats: false, block: timerDone)
            webServer?.start(withPort: UInt(_port), bonjourName: _streamName)
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

    /* ################################################################## */
    /**
     This will snitch on us, if we encounter an error.
     
     - parameter message: A string, with the error message to be displayed, in un-localized form.
     */
    func handleError(message inMessage: String = "") {
        DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
            self.delegate?.mediaServerManager(self, httpError: inMessage)
        }
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
