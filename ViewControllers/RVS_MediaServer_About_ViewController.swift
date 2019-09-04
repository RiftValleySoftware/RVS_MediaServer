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
// MARK: - Main View Controller Class for the About Screen
/* ################################################################################################################################## */
/**
 */
class RVS_MediaServer_About_ViewController: NSViewController {
    /// This is the bold label at the top of the screen.
    @IBOutlet weak var headerLabel: NSTextField!
    /// This is the text view, holding our about info.
    @IBOutlet var aboutTextView: NSTextView!
    
    /* ############################################################################################################################## */
    // MARK: - Superclass Override Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Called when the view finishes loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerLabel.stringValue = headerLabel.stringValue.localizedVariant
        aboutTextView.string = "SLUG-ABOUT-TEXT".localizedVariant
    }
}
