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
 This is the view controller for the main server status window.
 */
class RVS_MediaServer_ServerViewController: RVS_MediaServer_BaseViewController, RVS_MediaServer_FFMPEGServerManagerDelegate, RVS_MediaServer_HTTPServerManagerDelegate {
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
    
    /* ############################################################################################################################## */
    // MARK: - Private Instance Propeties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is the FFMPEG server handler view model. Most of the work goes on in that class.
     */
    private var _ffmpegServerHandler: RVS_MediaServer_FFMPEGServerManager!
    
    /* ################################################################## */
    /**
     This is the HTTP server handler view model.
     */
    private var _httpServerManager: RVS_MediaServer_HTTPServerManager!

    /* ################################################################## */
    /**
     This will hold the url of our output streaming file.
     */
    private var _outputTmpFile: TemporaryFile!

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
    
    /* ################################################################## */
    /**
     */
    @IBOutlet weak var consoleDisplayScrollView: NSScrollView!
    @IBOutlet var consoleDisplayTextView: NSTextView!
    @IBAction func displayClosureToggleButtonHit(_ sender: Any) {
    }
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
            if  isRunning {
                if _ffmpegServerHandler?.startFFMPEGProcess() ?? false,
                prefs.use_output_http_server || !prefs.use_raw_parameters {
                    _httpServerManager?.startHTTPServer()
                    isRunning = _httpServerManager?.webServer?.isRunning ?? false   // Can't be running if the Web server is not running.
                    DispatchQueue.main.async {
                        self.consoleDisplayTextView.string = ""
                        if let linkButtonTitle = self._httpServerManager?.webServer?.serverURL?.absoluteString {
                            self.linkButton.isHidden = false
                            self.linkButton.title = linkButtonTitle + "stream.m3u8"
                        }
                    }
                } else {
                    linkButton.isHidden = true
                }
            } else {
                linkButton.isHidden = true
                _httpServerManager?.stopHTTPServer()
                _ffmpegServerHandler?.stopFFMPEGServer()
                DispatchQueue.main.async {  // Make sure we call in the main thread, in case we were referenced from a callback, or something.
                    self.serverStateSegmentedSwitch.selectedSegment = 0
                    self.serverStatusObserverHandler()   // Make sure the UI is reset.
                }
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
        self.linkButton.isHidden = !self.isRunning || (!prefs.use_output_http_server && prefs.use_raw_parameters)
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
     Called when the view is about to appear.
     We use this to start the two servers.
     */
    override func viewWillAppear() {
        super.viewWillAppear()
        if !prefs.use_raw_parameters || prefs.use_output_http_server {   // Only if we will be using HTTP.
            guard let outputTmpFileTmp = try? TemporaryFile(creatingTempDirectoryForFilename: "stream.m3u8") else {
                RVS_MediaServer_AppDelegate.displayAlert(header: "SLUG-HTTP-SERVER-ERROR-HEADER".localizedVariant, message: "SLUG-UNABLE-TO-SET-UP-TMP-ERROR".localizedVariant)
                return
            }
            
            _outputTmpFile = outputTmpFileTmp
            _ffmpegServerHandler = RVS_MediaServer_FFMPEGServerManager(outputTmpFile: _outputTmpFile, inputURI: prefs.input_uri, login_id: prefs.login_id, password: prefs.password, raw_parameters: prefs.use_raw_parameters ? prefs.rawFFMPEGString : nil, delegate: self)
            _httpServerManager = RVS_MediaServer_HTTPServerManager(outputTmpFile: _outputTmpFile, port: prefs.output_tcp_port, streamName: prefs.stream_name, delegate: self)
            
        } else {
            _ffmpegServerHandler = RVS_MediaServer_FFMPEGServerManager(inputURI: prefs.input_uri, login_id: prefs.login_id, password: prefs.password, raw_parameters: prefs.use_raw_parameters ? prefs.rawFFMPEGString : nil, delegate: self)
        }
        serverStatusObserverHandler()   // Make sure the UI is reset.
    }
    
    /* ################################################################## */
    /**
     Called when the view is about to disappear.
     We make sure that we stop our server and the ffmpeg process.
     */
    override func viewWillDisappear() {
        super.viewWillDisappear()
        _httpServerManager?.stopHTTPServer()
        _ffmpegServerHandler?.stopFFMPEGServer()
        if let outTmp = _outputTmpFile {
            try? outTmp.deleteDirectory()
        }
        serverStateSegmentedSwitch.selectedSegment = 0
        serverStatusObserverHandler()   // Make sure the UI is reset.
    }
    
    /* ############################################################################################################################## */
    // MARK: - RVS_MediaServer_FFMPEGServerManagerDelegate Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Called to deliver text intercepted from ffmpeg.
     
     This is called on the main thread.
     
     - parameter inManager: The manager object
     - parameter ffmpegConsoleTextReceived: The text received.
     */
    func mediaServerManager( _ inManager: RVS_MediaServer_FFMPEGServerManager, ffmpegConsoleTextReceived inTextReceived: String) {
        consoleDisplayTextView.string += inTextReceived
    }
    
    /* ################################################################## */
    /**
     Called if there was an error encountered.
     
     - parameter: ignored
     - parameter ffmpegError: The text received.
     */
    func mediaServerManager( _: RVS_MediaServer_FFMPEGServerManager, ffmpegError inError: String) {
        RVS_MediaServer_AppDelegate.displayAlert(header: "SLUG-FFMPEG-SERVER-ERROR-HEADER".localizedVariant, message: inError.localizedVariant)
    }
    
    /* ############################################################################################################################## */
    // MARK: - RVS_MediaServer_HTTPServerManagerDelegate Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Called if there was an error encountered.
     
     - parameter: ignored
     - parameter httpError: The text received.
     */
    func mediaServerManager( _: RVS_MediaServer_HTTPServerManagerDelegate, httpError inError: String) {
        RVS_MediaServer_AppDelegate.displayAlert(header: "SLUG-HTTP-SERVER-ERROR-HEADER".localizedVariant, message: inError.localizedVariant)
    }
}
