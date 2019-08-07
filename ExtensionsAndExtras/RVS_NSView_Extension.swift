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

import AppKit

/* ############################################################################################################################## */
// MARK: - View Extension
/* ############################################################################################################################## */
/**
 This is an extension to the standard NSView class, so we can see if we are in "dark mode."
 Cribbed from here: https://stackoverflow.com/a/52523517/879365
 */
extension NSView {
    /* ################################################################## */
    /**
     - returns: True, if the app is in Dark Mode.
     */
    var isDarkMode: Bool {
        if #available(OSX 10.14, *) {
            return .darkAqua == effectiveAppearance.name
        }
        
        return false
    }
}
