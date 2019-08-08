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
// MARK: - Basic Window Controller Class
/* ################################################################################################################################## */
/**
 The main reason for creating this class was to allow us to interpret settings, and to fix an issue with Interface Builder.
 */
class RVS_MediaServer_WindowController: NSWindowController {
    /* ################################################################## */
    /**
     This accounts for a bug in Xcode, where the [`restorable`](https://developer.apple.com/documentation/appkit/nswindow/1526255-restorable) flag is ignored. If you set the name here, it will restore.
     */
    override func windowDidLoad() {
        super.windowDidLoad()
        self.windowFrameAutosaveName = (window?.title ?? "ERROR") + "-position"
    }
}
