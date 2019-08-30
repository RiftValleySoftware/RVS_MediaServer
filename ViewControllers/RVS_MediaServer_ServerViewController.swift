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
 This is the view controller for the main server status window.
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
    
    /* ############################################################################################################################## */
    // MARK: - Private Instance Propeties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is the server handler view model.
     */
    private var _serverHandler: RVS_MediaServer_ServerViewModel!
    
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
                if _serverHandler?.startFFMpeg() ?? false,
                prefs.use_output_http_server || !prefs.use_raw_parameters {
                    _serverHandler?.startHTTPServer()
                    isRunning = _serverHandler?.webServer?.isRunning ?? false   // Can't be running if the Web server is not running.
                    DispatchQueue.main.async {
                        if let linkButtonTitle = self._serverHandler?.webServer?.serverURL?.absoluteString {
                            self.linkButton.isHidden = false
                            self.linkButton.title = linkButtonTitle + "stream.m3u8"
                        }
                    }
                } else {
                    linkButton.isHidden = true
                }
            } else {
                linkButton.isHidden = true
                _serverHandler?.stopHTTPServer()
                _serverHandler?.stopFFMPEGServer()
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
        self.linkButton.isHidden = !self.isRunning || !prefs.use_output_http_server
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
        _serverHandler = RVS_MediaServer_ServerViewModel()
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
        _serverHandler?.stopHTTPServer()
        _serverHandler?.stopFFMPEGServer()
        serverStateSegmentedSwitch.selectedSegment = 0
        serverStatusObserverHandler()   // Make sure the UI is reset.
    }
}
