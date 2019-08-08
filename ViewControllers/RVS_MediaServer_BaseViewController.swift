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
// MARK: - Main View Controller Class for Use As A Base Class for View Controllers.
/* ################################################################################################################################## */
/**
 This class will provide some common base properties and methods to be made available to derived View Controllers.
 */
class RVS_MediaServer_BaseViewController: NSViewController {
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a direct accessor to the app prefs object.
     */
    @objc dynamic var prefs: RVS_MediaServer_PersistentPrefs {
        return RVS_MediaServer_AppDelegate.appDelegateObject.prefs
    }
}
