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
import VLCKit

/* ################################################################################################################################## */
// MARK: - Main View Controller Class for the Display Video Screen
/* ################################################################################################################################## */
/**
 This is the View Controller for the Display Video Screen.
 */
class RVS_MediaServer_DisplayVideoViewController: RVS_MediaServer_BaseViewController, VLCMediaPlayerDelegate {
    /* ################################################################## */
    /**
     This is a simple view that will contain the display.
     */
    @IBOutlet weak var videoContainerView: NSView!
    
    /* ################################################################## */
    /**
     This is the "busy" throbber.
     */
    @IBOutlet weak var throbber: NSProgressIndicator!

    /* ################################################################## */
    /**
     This is the box that surrounds the video display.
     */
    @IBOutlet weak var surroundingBox: NSBox!
    /* ################################################################## */
    /**
     This is the VLCKit media player object.
     */
    var mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()
    
    /* ################################################################## */
    /**
     This is the VLCKit media object for the stream.
     */
    var media: VLCMedia!

    /* ################################################################## */
    /**
     Called when the view finishes loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        media = nil
        mediaPlayer.delegate = self
        mediaPlayer.drawable = videoContainerView
    }
    
    /* ################################################################## */
    /**
     Called just before the view appears.
     
     We use this to mark the preference for the window being open.
     */
    override func viewWillAppear() {
        super.viewWillAppear()
        prefs.display_video_screen = true  // We are open for business.
        videoContainerView.isHidden = true
        throbber?.startAnimation(nil)
        displayStreamingURI()
    }
    
    /* ################################################################## */
    /**
     Called just before the view disappears.
     
     We use this to mark the preference for the window being closed.
     */
    override func viewWillDisappear() {
        mediaPlayer.stop()
        media = nil
        prefs.display_video_screen = false  // We are closed.
        super.viewWillDisappear()
    }

    /* ################################################################## */
    /**
     */
    func displayStreamingURI() {
        if let uri = URL(string: prefs.input_uri) {
            var login_id: String = ""
            var password: String = ""
            
            if !prefs.login_id.isEmpty, prefs.password.isEmpty {
                login_id = prefs.login_id
                password = prefs.password
            }
            
            media = VLCMedia(url: uri)
            media.addOptions([
                "network-caching": 0,
                "network-synchronisation": true,
                "sout-x264-preset": "fast",
                "sout-x264-tune": "zerolatency",
                "sout-x264-lookahead": 15,
                "sout-x264-keyint": 10,
                "sout-x264-intra-refresh": true,
                "sout-x264-mvrange-thread": -1,
                "rtsp-user": login_id,
                "rtsp-pwd": password
                ])
            mediaPlayer.media = media
            mediaPlayer.play()
        }
    }

    /* ################################################################## */
    /**
     This is called when the media player changes state.
     
     - parameter: ignored
     */
    func mediaPlayerStateChanged(_: Notification!) {
        if nil != mediaPlayer.time.value {
            throbber?.stopAnimation(nil)
            videoContainerView.isHidden = false
            surroundingBox?.fillColor = NSColor.black
        }
    }
}
