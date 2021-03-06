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

import Foundation   // Only requires Foundation, but don't try running this without ffmpeg! (i.e: Mac-only).

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
     Called to indicate that a running process, is running no more.
     
     - parameter manager: The manager object
     - parameter task: The process that is no longer running.
     */
    func mediaServerManager( _ manager: RVS_MediaServer_FFMPEGServerManager, taskStopped: Process!)
    
    /* ################################################################## */
    /**
     Called to deliver text intercepted from ffmpeg.
     
     - parameter manager: The manager object
     - parameter task: The process running.
     - parameter ffmpegConsoleTextReceived: The text received.
     */
    func mediaServerManager( _ manager: RVS_MediaServer_FFMPEGServerManager, task: Process!, ffmpegConsoleTextReceived: String)
    
    /* ################################################################## */
    /**
     Called if there was an error encountered.
     
     - parameter manager: The manager object
     - parameter task: The process running.
     - parameter ffmpegError: The text received.
     */
    func mediaServerManager( _ manager: RVS_MediaServer_FFMPEGServerManager, task: Process!, ffmpegError: String)
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
     Called to indicate that a running process, is running no more.
     
     - parameter: ignored
     - parameter task: Ignored
     */
    func mediaServerManager( _: RVS_MediaServer_FFMPEGServerManager, taskStopped: Process) { }
    
    /* ################################################################## */
    /**
     Does Nothing.
     
     - parameter: ignored
     - parameter task: ignored
     - parameter ffmpegConsoleTextReceived: ignored.
     */
    func mediaServerManager( _: RVS_MediaServer_FFMPEGServerManager, task: Process, ffmpegConsoleTextReceived: String) { }
    
    /* ################################################################## */
    /**
     Called if there was an error encountered.
     
     - parameter: ignored
     - parameter task: Ignored
     - parameter ffmpegError: ignored
     */
    func mediaServerManager( _ manager: RVS_MediaServer_FFMPEGServerManager, task: Process, ffmpegError: String) { }
}

/* ################################################################################################################################## */
// MARK: - Main ffmpeg Service Manager Class
/* ################################################################################################################################## */
/**
 This is a model for the server status screen. It handles the management of the actual ffmpeg instance.
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
    
    /* ############################################################################################################################## */
    // MARK: - Private Instance Propeties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This will hold the url of our output streaming file.
     */
    private var _outputTmpFile: URL!
    
    /* ################################################################## */
    /**
     This will hold the ffmpeg command line task.
     */
    private var _ffmpegTask: Process?

    /* ################################################################## */
    /**
     ffmpeg sends its reports out via stderr; not stdout, so we trap that, in order to report it in the console.
     */
    private var _stderrPipe: Pipe!
    
    /* ################################################################## */
    /**
     This is an observer handler for stderr (ffmpeg).
     */
    private var _stdErrObserver: NSObjectProtocol!
    
    /* ################################################################## */
    /**
     This is an input source URI.
     */
    private let _inputURI: String
    
    /* ################################################################## */
    /**
     This is a login ID for authorization.
     */
    private let _loginID: String!

    /* ################################################################## */
    /**
     This is a password for authorization.
     */
    private let _password: String!
    
    /* ################################################################## */
    /**
     A String, containing raw parameters to use, if that is how we are rolling.
     */
    private let _raw_parameters: String!
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     A delegate object for handling the operation of the manager. This is a weak class reference.
     */
    weak var delegate: RVS_MediaServer_FFMPEGServerManagerDelegate!

    /* ############################################################################################################################## */
    // MARK: - Initializer
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     - parameter outputTmpFile: The URL to the temporary file object that describes the temporary directory, where we fetch our data. This can be omitted or nil, if we are not using one.
     - parameter inputURI: A String with the input URI.
     - parameter login_id: A String, with a login for authorization. This is optional. If not provided, authorization will not be attempted.
     - parameter password: A String, with a password for authorization. This is optional. If not provided, authorization will not be attempted.
     - parameter raw_parameters: A String, containing raw parameters to use (instead of the standard HLS).
     - parameter delegate: The delegate for the object. This is optional.
     */
    init(outputTmpFile inOutputTmpFile: URL! = nil, inputURI inInputURI: String, login_id inLoginID: String! = nil, password inPassword: String! = nil, raw_parameters inRawParameters: String! = nil, delegate inDelegate: RVS_MediaServer_FFMPEGServerManagerDelegate! = nil) {
        _outputTmpFile = inOutputTmpFile
        _inputURI = inInputURI
        _loginID = inLoginID
        _password = inPassword
        _raw_parameters = inRawParameters
        delegate = inDelegate
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
    func startFFMPEGProcess() -> Bool {
        // We check to make sure we have a viable RTSP URL
        let rtspURI = createRTSPURI(uri: _inputURI, loginID: _loginID, password: _password)
        
        if !rtspURI.isEmpty {
            _ffmpegTask = Process()
            
            // First, we make sure that we got a Process. It's a conditional init.
            if let ffmpegTask = _ffmpegTask {
                // Fetch the executable path from the bundle. We have our copy of ffmpeg in there with the app.
                if var executablePath = (Bundle.main.executablePath as NSString?)?.deletingLastPathComponent {
                    executablePath += "/ffmpeg"
                    ffmpegTask.launchPath = executablePath
                    // For "raw" parameters, each line is one argument pair, with the key, followed by the value, separated by one space (" ").
                    // For example: "-c:v libx264\n-crf 21" would be two arguments.
                    if let rawFFMPEGString = _raw_parameters {
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
                        let timeSlice = type(of: self)._hlsTimeSliceInSeconds
                        
                        let arguments = [
                            "-i", rtspURI,                      // This is the main URL to the stream. It should have any auth parameters included.
                            "-c:v", "libx264",                  // This denotes that we use the libx264 (VideoLAN) version of the H.264 decoder.
                            "-crf", "21",                       // This is a "middle" quality level (1...51, with 1 being the best -slowest-, and 51 being the worst -fastsest-).
                            "-preset", "superfast",             // As fast as possible (we are streaming).
                            "-g", "30",                         // This says assume that the input is coming at 30 frames/sec.
                            "-sc_threshold", "0",               // This tells ffmpeg not to do scene analysis, so we can regulate the time slices
                            "-f", "hls",                        // This says output HLS
                            "-hls_flags", "delete_segments",    // This says that the streamer should pick up after itself, and remove old files. This keeps a "window" going.
                            "-hls_time", "\(timeSlice)"         // The size of HLS slices, in seconds.
                        ]
                        
                        ffmpegTask.arguments = arguments
                    }
                    
                    // If we have been provided an output file and directory.
                    if  let path = _outputTmpFile?.path {
                        ffmpegTask.arguments?.append(path) // The output temp file and dir. The Web server picks up the stream, here.
                    }

                    #if DEBUG
                        if let args = _ffmpegTask?.arguments, 1 < args.count {
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
                } else {
                    handleError(message: "SLUG-CANNOT-START-FFMPEG-MESSAGE")
                }
            } else {
                handleError(message: "SLUG-CANNOT-START-FFMPEG-MESSAGE")
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
        _stderrPipe = Pipe()
        
        // This closure will intercept stderr from the input task.
        _stdErrObserver = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: _stderrPipe.fileHandleForReading, queue: nil) { [unowned self] _ in
            let data = self._stderrPipe.fileHandleForReading.availableData
            if 0 < data.count {
                let str = String(data: data, encoding: .ascii) ?? "<Unexpected \(data.count) elements of data!>\n"
                // We call delegate methods in the main thread.
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.mediaServerManager(self!, task: self!._ffmpegTask, ffmpegConsoleTextReceived: str)
                }
                self._stderrPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            } else if let stdErrObserver = self._stdErrObserver {
                NotificationCenter.default.removeObserver(stdErrObserver)
                self._stdErrObserver = nil
            }
            
            if !(self._ffmpegTask?.isRunning ?? false) {
                DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
                    self.delegate?.mediaServerManager(self, taskStopped: self._ffmpegTask)
                }
            }
        }
        
        inTask.standardError = _stderrPipe
        self._stderrPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    /* ################################################################## */
    /**
     This simply stops the Web server.
     */
    func stopFFMPEGServer() {
        _ffmpegTask?.terminate() // Ah'll be bach...
        _ffmpegTask = nil
        // Make sure that we unwind any interceptor.
        if let stdErrObserver = self._stdErrObserver {
            NotificationCenter.default.removeObserver(stdErrObserver)
            self._stdErrObserver = nil
        }
    }

    /* ################################################################## */
    /**
     This will snitch on us, if we encounter an error.

     - parameter message: A string, with the error message to be displayed, in un-localized form.
     */
    func handleError(message inMessage: String = "") {
        DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
            self.delegate?.mediaServerManager(self, task: self._ffmpegTask, ffmpegError: inMessage)
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
