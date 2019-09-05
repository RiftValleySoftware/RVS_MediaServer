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
class RVS_MediaServer_DisplayVideoViewController: RVS_MediaServer_BaseViewController {
    /// This is a simple view that will contain the display.
    @IBOutlet weak var videoContainerView: NSView!
    
    /* ################################################################## */
    /**
     Called when the view finishes loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /* ################################################################## */
    /**
     Called just after the view appears.
     
     We use this to mark the preference for the window being open.
     */
    override func viewDidAppear() {
        super.viewDidAppear()
        prefs.display_video_screen = true  // We are open for business.
    }
    
    /* ################################################################## */
    /**
     Called just before the view disappears.
     
     We use this to mark the preference for the window being closed.
     */
    override func viewWillDisappear() {
        super.viewWillDisappear()
        prefs.display_video_screen = false  // We are closed.
    }
}
