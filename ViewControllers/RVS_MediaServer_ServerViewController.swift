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
class RVS_MediaServer_ServerViewController: RVS_MediaServer_BaseViewController {
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
    
    /* ############################################################################################################################## */
    // MARK: - Internal IB Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     The Server Status Segmented Switch
     */
    @IBOutlet weak var serverStateSegmentedSwitch: NSSegmentedControl!
    
    /* ################################################################## */
    /**
     This button displays a link to allow the server to be easily opened.
     */
    @IBOutlet weak var linkButton: NSButton!
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     We use this to observe the current Web Server status
     */
    var serverStatusObserver: NSKeyValueObservation?
    
    /* ################################################################## */
    /**
     This will hold the ffmpeg command line task.
     */
    var ffmpegTask: Process?
    
    /* ################################################################## */
    /**
     This will hold the url of our output streaming file.
     */
    var outputTmpFile: TemporaryFile?
    
    /* ################################################################## */
    /**
     This is a Web Server instance that is associated with this stream. Its lifetime is the lifetime of the object (not persistent).
     */
    var webServer: GCDWebServer?

    /* ############################################################################################################################## */
    // MARK: - Internal Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This simply starts the Web server.
     
     - parameter webServerHandler: This is an optional handling closure for Web Server calls.
     If not provided (or set to nil), then whatever we already have is used. This will replace any existing handler.
     */
    func startServer() {
        if nil == webServer || !(webServer?.isRunning ?? false) {
            webServer = GCDWebServer()
            
            // Add a default get handler to make sure that the stream file is considered our index.
            webServer?.addGETHandler(forBasePath: "/", directoryPath: outputTmpFile?.directoryURL.path ?? "", indexFilename: "stream.m3u8", cacheAge: 3600, allowRangeRequests: true)
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
     This will create a "clean" RTSP URI, adding the login and password as inline Auth elements (rtsp://user:pass@server/path?query).
     
     If either the login ID or password is left out, then the stream will be returned without adding authentication.
     
     - parameter uri: The URL, without auth, as a String. This is required.
     - parameter loginID: The Login ID, as a String. This is optional. If left out, authentication is not added to the URI.
     - parameter password: The Password, as a String. This is optional. If left out, authentication is not added to the URI.
     */
    func createRTSPURI(uri inURI: String, loginID inLoginID: String! = nil, password inPassword: String! = nil) -> String {
        if  let rtspURI = URL(string: inURI),   // The first thing that we do, is get our URI into a URL instance, so the system can do most of the parsing.
            let host = rtspURI.host {           // We need to make sure that we at least have a host.
            // Next, we recreate the URI, adding a scheme (if not provided, it is assumed to be RTSP):
            var newURI = (rtspURI.scheme ?? "rtsp") + "://"
            // If auth parameters are passed in directly, then that trumps anything in the URI. Have to have both.
            if let loginID = inLoginID, let password = inPassword, !loginID.isEmpty, !password.isEmpty {
                newURI += "\(loginID):\(password)@"
                // If nothing was passed in, we see if there were auth parameters already in the URI. Have to have both.
            } else if let loginID = rtspURI.user, let password = rtspURI.password, !loginID.isEmpty, !password.isEmpty {
                newURI += "\(loginID):\(password)@"
            }
            
            newURI += "\(host)"    // Add the host.
            
            if let port = rtspURI.port {
                newURI += ":\(port)"    // Add the port, is one was explicitly provided.
            }
            
            // Append any path, directly.
            newURI += "/\(rtspURI.path)"
            
            // Append any query, directly.
            if let query = rtspURI.query {
                newURI += "?\(query)"
            }

            #if DEBUG
                print("Streaming URI: \(newURI)")
            #endif
            return newURI
        }
        
        return ""
    }
    
    /* ################################################################## */
    /**
     This starts the ffmpeg task.
     
     - returns: True, if the task launched successfully.
     */
    func startFFMpeg() -> Bool {
        // We check to make sure we have a viable RTSP URL
        let rtspURI = createRTSPURI(uri: prefs.input_uri, loginID: prefs.login_id, password: prefs.password)
        
        if !rtspURI.isEmpty {
            ffmpegTask = Process()
            
            // First, we make sure that we got a Process. It's a conditional init.
            if let ffmpegTask = ffmpegTask {
                // Next, set up a tempdir for the stream files.
                if let tmp = try? TemporaryFile(creatingTempDirectoryForFilename: "stream.m3u8") {
                    outputTmpFile = tmp

                    // Fetch the executable path from the bundle. We have our copy of ffmpeg in there with the app.
                    if var executablePath = (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent {
                        executablePath += "/ffmpeg"
                        ffmpegTask.launchPath = executablePath
                        ffmpegTask.arguments = [
                            "-i", rtspURI,          // This is the main URL to the stream. It should have auth parameters included.
                            "-c:v", "libx264",      // This denotes that we use the libx264 (VideoLAN) version of the H.264 decoder.
                            "-crf", "21",           // This is a "middle" quality level (1...51, with 1 being the best -slowest-, and 51 being the worst -fastsest-).
                            "-preset", "superfast", // As fast as possible (we are streaming).
                            "-g", "30",             // This says assume that the input is coming at 30 frames/sec.
                            "-sc_threshold", "0",   // This tells ffmpeg not to do scene analysis, so we can regulate the time slices
                            "-f", "hls",            // This says output HLS
                            "-hls_flags", "delete_segments",    // This says that the streamer should pick up after itself, and remove old files. This keeps a "window" going.
                            "-hls_time", "\(type(of: self)._hlsTimeSliceInSeconds)",    // The size of HLS slices, in seconds.
                            outputTmpFile?.fileURL.path ?? ""   // The output temp dir, where the Webserver picks up the stream.
                        ]
                        
                        #if DEBUG
                            if let args = ffmpegTask.arguments, 1 < args.count {
                                let path = ([executablePath] + args).joined(separator: " ")
                                print("\n----\n\(path)")
                            }
                        #else
                            // This just eats the output from the ffmpeg task for non-debug, so we don't litter the console.
                            let standardOutputPipe = Pipe()
                            ffmpegTask.standardOutput = standardOutputPipe
                        
                            let standardErrorPipe = Pipe()
                            ffmpegTask.standardError = standardErrorPipe
                        #endif
                        
                        // Launch the task
                        ffmpegTask.launch()
                        
                        #if DEBUG
                            print("\n----\n")
                        #endif

                        if !ffmpegTask.isRunning {
                            handleError(message: "SLUG-CANNOT-START-FFMPEG-MESSAGE")
                        }
                        
                        return ffmpegTask.isRunning
                    }
                }
            }
        } else {
            handleError(message: "SLUG-BAD-URI-MESSAGE")
        }
        
        return false
    }

    /* ################################################################## */
    /**
     This simply stops the Web server.
     */
    func stopServer() {
        _timeoutTimer?.invalidate()
        _timeoutTimer = nil
        ffmpegTask?.terminate()
        ffmpegTask = nil
        webServer?.stop()
        webServer = nil
        try? outputTmpFile?.deleteDirectory()
        outputTmpFile = nil
        DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
            self.serverStateSegmentedSwitch.selectedSegment = 0
            self.serverStatusObserverHandler()   // Make sure the UI is reset.
        }
    }

    /* ################################################################## */
    /**
     Set up the various localized items and initial values.
     */
    func setUpLocalizations() {
        linkButton.isHidden = true
        for i in 0..<serverStateSegmentedSwitch.segmentCount {
            if let label = serverStateSegmentedSwitch.label(forSegment: i)?.localizedVariant {
                serverStateSegmentedSwitch.setLabel(label, forSegment: i)
            }
        }
    }

    /* ################################################################## */
    /**
     This will throw up an error alert, if we encounter an error.
     */
    func handleError(message inMessage: String = "") {
        DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
            RVS_MediaServer_AppDelegate.displayAlert(header: "SLUG-SERVER-ERROR-HEADER".localizedVariant, message: inMessage.localizedVariant)
        }
    }

    /* ############################################################################################################################## */
    // MARK: - Internal IBAction Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This starts or stops the streaming server, depending on the state of the server.
     
     - parameter inSender: Ignored
     */
    @IBAction func startStopButtonHit(_ inSender: NSSegmentedControl) {
        isRunning = 1 == inSender.selectedSegment
    }
    
    /* ################################################################## */
    /**
     This responds to the server link button being hit.
     Assuming the server is running, this will ask the default browser to open the link.
     
     - parameter inSender: The  Link button. We will use its text value as our URI source.
     */
    @IBAction func linkButtonHit(_ inSender: NSButton) {
        if isRunning {
            let uriString = inSender.title
            if  let uri = URL(string: uriString),
                NSWorkspace.shared.open(uri) {
            }
        }
    }
    
    /* ############################################################################################################################## */
    // MARK: - Internal Observable Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     The Web Server Running Status.
     If set to true, then the server will start, using whatever handler is already in webServerHandler
     */
    @objc dynamic var isRunning: Bool = false {
        didSet {
            if isRunning, startFFMpeg() {
                startServer()
                isRunning = webServer?.isRunning ?? false
                if let linkButtonTitle = webServer?.serverURL?.absoluteString {
                    linkButton.isHidden = false
                    linkButton.title = linkButtonTitle + "stream.m3u8"
                }
            } else {
                linkButton.isHidden = true
                stopServer()
            }
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
    func serverStatusObserverHandler(_ inObject: Any! = nil, _ inChange: NSKeyValueObservedChange<Bool>! = nil) {
        self.linkButton.isHidden = !self.isRunning
    }
    
    /* ################################################################## */
    /**
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
            if  let path = outputTmpFile?.directoryURL.path,
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
                webServer?.addGETHandler(forBasePath: "/", directoryPath: outputTmpFile?.directoryURL.path ?? "", indexFilename: "stream.m3u8", cacheAge: 3600, allowRangeRequests: true)
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
        stopServer()
        handleError(message: "SLUG-TIMEOUT-MESSAGE")
    }

    /* ############################################################################################################################## */
    // MARK: - Superclass Override Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Called when the view finishes loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocalizations()
        serverStatusObserver = observe(\.isRunning, changeHandler: serverStatusObserverHandler)
        serverStatusObserverHandler()
    }
    
    /* ################################################################## */
    /**
     Called when the view is about to disappear.
     We make sure that we stop our server and the ffmpeg process.
     */
    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopServer()
    }
    
    /* ############################################################################################################################## */
    // MARK: - Deinit
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Make sure that we stop the server upon dealloc.
     */
    deinit {
        stopServer()
    }
}
