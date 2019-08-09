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
            
            webServer?.addGETHandler(forBasePath: "/", directoryPath: outputTmpFile?.directoryURL.path ?? "", indexFilename: "stream.m3u8", cacheAge: 3600, allowRangeRequests: true)
            
            webServer?.start(withPort: UInt(prefs.output_tcp_port), bonjourName: prefs.stream_name)
            
            if let uri = webServer?.serverURL {
                print("Visit \(uri) in your web browser")
            } else {
                print("Error in Setting Up the Web Server!")
            }
        }
    }
    
    /* ################################################################## */
    /**
     This starts the ffmpeg task.
     */
    func startFFMpeg() -> Bool {
        ffmpegTask = Process()
        
        if let ffmpegTask = ffmpegTask {
            if let tmp = try? TemporaryFile(creatingTempDirectoryForFilename: "stream.m3u8") {
                outputTmpFile = tmp
            }
            
            if  nil != outputTmpFile,
                var executablePath = (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent {
                executablePath += "/ffmpeg"
                ffmpegTask.launchPath = executablePath
                ffmpegTask.arguments = [
                    "-i",
                    prefs.input_uri,
                    "-sc_threshold",
                    "0",
                    "-f",
                    "hls",
                    "-hls_flags",
                    "delete_segments",
                    "-hls_time",
                    "4",
                    outputTmpFile?.fileURL.path ?? ""
                ]
                
                #if DEBUG
                    if let args = ffmpegTask.arguments, 1 < args.count {
                        let path = ([executablePath] + args).joined(separator: " ")
                            print("Starting FFMPEG: \(String(describing: path))")
                    }
                #endif
                
                // Create a Pipe and make the task
                // put all the output there
                let pipe = Pipe()
                ffmpegTask.standardOutput = pipe
                
                // Launch the task
                ffmpegTask.launch()
                
                print(pipe)
                
                return ffmpegTask.isRunning
            }
        }
        
        return false
    }
    
    /* ################################################################## */
    /**
     This simply stops the Web server.
     */
    func stopServer() {
        ffmpegTask?.terminate()
        ffmpegTask = nil
        webServer?.stop()
        webServer = nil
        try? outputTmpFile?.deleteDirectory()
        outputTmpFile = nil
    }

    /* ############################################################################################################################## */
    // MARK: - Internal IBAction Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This starts or stops the streaming server, depending on the state of the server.
     
     - parameter inSender: Ignored
     */
    @IBAction func startStopButtonHit(_ inSender: NSButton) {
        isRunning = !isRunning
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
            } else {
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
        if isRunning {
            serverStatusLabel.textColor = NSColor.green
            serverStatusLabel.stringValue = "SLUG-SERVER-IS-RUNNING".localizedVariant
            startStopButton.title = "SLUG-STOP-SERVER".localizedVariant
            if let linkButtonTitle = webServer?.serverURL?.absoluteString {
                linkButton.isHidden = false
                linkButton.title = linkButtonTitle + "stream.m3u8"
            }
        } else {
            serverStatusLabel.textColor = NSColor.red
            serverStatusLabel.stringValue = "SLUG-SERVER-IS-NOT-RUNNING".localizedVariant
            startStopButton.title = "SLUG-START-SERVER".localizedVariant
            linkButton.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     */
    func webServerHandler(_ inRequestObject: GCDWebServerRequest) -> GCDWebServerDataResponse! {
        print(String(describing: inRequestObject))
        do {
            if let url = outputTmpFile?.fileURL {
                let outputData = try Data(contentsOf: url)
                return GCDWebServerDataResponse(data: outputData, contentType: "application/vnd.apple.mpegurl")
            }
        } catch {
            return GCDWebServerDataResponse(html: "<html><body><h1>ERROR!</h1></body></html>")
        }
        
        return nil
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
        serverStatusObserver = observe(\.isRunning, changeHandler: serverStatusObserverHandler)
        serverStatusObserverHandler()
    }
    
    /* ############################################################################################################################## */
    // MARK: - Deinit
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Make sure that we stop the server upon quit/close.
     */
    deinit {
        stopServer()
    }
}
