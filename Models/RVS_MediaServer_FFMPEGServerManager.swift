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
// MARK: - Delegate Protocol
/* ################################################################################################################################## */
/**
 These are methods that can be called from the manager to a registered delegate.
 
 They are all called on the main thread, and are all optional.
 */
protocol RVS_MediaServer_FFMPEGServerManagerDelegate: class {
    /* ################################################################## */
    /**
     Called to deliver text intercepted from ffmpeg.
     
     - parameter manager: The manager object
     - parameter ffmpegConsoleTextReceived: The text received.
     */
    func mediaServerManager( _ manager: RVS_MediaServer_FFMPEGServerManager, ffmpegConsoleTextReceived: String)
}

/* ################################################################################################################################## */
// MARK: - Delegate Protocol Extension
/* ################################################################################################################################## */
/**
 This is an extension that allows the protocol methods to be optional.
 
 They do nothing.
 */
extension RVS_MediaServer_FFMPEGServerManagerDelegate {
    /* ################################################################## */
    /**
     Does Nothing.
     
     - parameter: ignored
     - parameter ffmpegConsoleTextReceived: ignored.
     */
    func mediaServerManager( _: RVS_MediaServer_FFMPEGServerManager, ffmpegConsoleTextReceived: String) { }
}

/* ################################################################################################################################## */
// MARK: - Main View Controller Class
/* ################################################################################################################################## */
/**
 This is a model for the server status screen. It handles the management of the actual ffmpeg instance, and any HTTP server we set up.
 */
class RVS_MediaServer_FFMPEGServerManager {
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
     This will hold the ffmpeg command line task.
     */
    private var ffmpegTask: Process?
    
    /* ################################################################## */
    /**
     ffmpeg sends its reports out via stderr; not stdout, so we trap that, in order to report it in the console.
     */
    var stderrPipe: Pipe!
    
    /* ################################################################## */
    /**
     This is an observer handler for stderr (ffmpeg).
     */
    var stdErrObserver: NSObjectProtocol!
    
    /* ################################################################## */
    /**
     A delegate object for handling the operation of the manager. This is a weak class reference.
     */
    weak var delegate: RVS_MediaServer_FFMPEGServerManagerDelegate!
    
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
                // Fetch the executable path from the bundle. We have our copy of ffmpeg in there with the app.
                if var executablePath = (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent {
                    executablePath += "/ffmpeg"
                    ffmpegTask.launchPath = executablePath
                    // For "raw" parameters, each line is one argument pair, with the key, followed by the value, separated by one space (" ").
                    // For example: "-c:v libx264\n-crf 21" would be two arguments.
                    if prefs.use_raw_parameters {
                        let rawFFMPEGString = prefs.rawFFMPEGString
                        let lines = rawFFMPEGString.split(separator: "\n")
                        if 0 < lines.count {
                            var arguments: [String] = []
                            
                            lines.forEach {
                                let lineItem = $0.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                                if 2 == lineItem.count {
                                    let flag = String(lineItem[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                                    let value = String(lineItem[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !flag.isEmpty, !value.isEmpty {
                                        arguments.append(flag)
                                        arguments.append(value)
                                    }
                                }
                            }
                            
                            ffmpegTask.arguments = arguments
                        }
                    } else {
                        let arguments =
                            [
                            "-i", rtspURI,          // This is the main URL to the stream. It should have auth parameters included.
                            "-c:v", "libx264",      // This denotes that we use the libx264 (VideoLAN) version of the H.264 decoder.
                            "-crf", "21",           // This is a "middle" quality level (1...51, with 1 being the best -slowest-, and 51 being the worst -fastsest-).
                            "-preset", "superfast", // As fast as possible (we are streaming).
                            "-g", "30",             // This says assume that the input is coming at 30 frames/sec.
                            "-sc_threshold", "0",   // This tells ffmpeg not to do scene analysis, so we can regulate the time slices
                            "-f", "hls",            // This says output HLS
                            "-hls_flags", "delete_segments",    // This says that the streamer should pick up after itself, and remove old files. This keeps a "window" going.
                            "-hls_time", "\(type(of: self)._hlsTimeSliceInSeconds)"    // The size of HLS slices, in seconds.
                        ]
                        
                        ffmpegTask.arguments = arguments
                    }
                    
                    // We use the output Webserver for simple HLS, or if the raw parameters mode requests it.
                    if  prefs.use_output_http_server || !prefs.use_raw_parameters,
                        let path = tempOutputFileURL?.path {
                        ffmpegTask.arguments?.append(path) // The output temp file and dir. The Web server picks up the stream, here.
                    }

                    #if DEBUG
                        if let args = ffmpegTask.arguments, 1 < args.count {
                            let path = ([executablePath] + args).joined(separator: " ")
                            print("\n----\n\(path)")
                        }
                    #endif
                    
                    openErrorPipe(ffmpegTask)

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
        } else {
            handleError(message: "SLUG-BAD-URI-MESSAGE")
        }
        
        return false
    }
    
    /* ################################################################## */
    /**
     This sets up a trap, so we can intercept the textual output from ffmpeg (which comes out on stderr).
     
     - parameter inTask: The ffmpeg task we're intercepting.
     */
    func openErrorPipe(_ inTask: Process) {
        stderrPipe = Pipe()
        // This closure will intercept stderr from the input task.
        stdErrObserver = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stderrPipe.fileHandleForReading, queue: nil) { [unowned self] _ in
            let data = self.stderrPipe.fileHandleForReading.availableData
            if 0 < data.count {
                let str = String(data: data, encoding: .ascii) ?? "<Unexpected \(data.count) elements of data!>\n"
                if let delegate = self.delegate {   // If we have a delegate, then we call it.
                    // We call delegate methods in the main thread.
                    DispatchQueue.main.async {
                        delegate.mediaServerManager(self, ffmpegConsoleTextReceived: str)
                    }
                } else {
                    print(str)  // Otherwise, just print to the console.
                }
                self.stderrPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            } else if let stdErrObserver = self.stdErrObserver {
                NotificationCenter.default.removeObserver(stdErrObserver)
                self.stdErrObserver = nil
            }
        }
        
        inTask.standardError = stderrPipe
        self.stderrPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    /* ################################################################## */
    /**
     This simply stops the Web server.
     */
    func stopFFMPEGServer() {
        ffmpegTask?.terminate() // Ah'll be bach...
        ffmpegTask = nil
        // Make sure that we unwind any interceptor.
        if let stdErrObserver = self.stdErrObserver {
            NotificationCenter.default.removeObserver(stdErrObserver)
            self.stdErrObserver = nil
        }
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
    // MARK: - Deinit
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Make sure that we stop the server upon dealloc.
     */
    deinit {
        stopFFMPEGServer()
    }
}
