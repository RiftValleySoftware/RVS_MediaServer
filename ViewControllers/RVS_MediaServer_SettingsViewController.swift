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
 */
class RVS_MediaServer_SettingsViewController: RVS_MediaServer_BaseViewController {
    /* ############################################################################################################################## */
    // MARK: - Internal IBOutlet Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     The label for the Stream Name Text Field
     */
    @IBOutlet weak var stream_name_label: NSTextField!
    
    /* ################################################################## */
    /**
     The Stream Name Text Field
     */
    @IBOutlet weak var stream_name_text_field: NSTextField!
    
    /* ################################################################## */
    /**
     The label for the Input URI Text Field
     */
    @IBOutlet weak var input_uri_label: NSTextField!
    
    /* ################################################################## */
    /**
     The Input URI Text Field
     */
    @IBOutlet weak var input_uri_text_field: NSTextField!
    
    /* ################################################################## */
    /**
     The label for the Output TCP Port Text Field
     */
    @IBOutlet weak var output_tcp_port_label: NSTextField!
    
    /* ################################################################## */
    /**
     The Output TCP Port Text Field
     */
    @IBOutlet weak var output_tcp_port_text_field: NSTextField!
    
    /* ################################################################## */
    /**
     The Login ID Label
     */
    @IBOutlet var login_label: NSTextField!
    
    /* ################################################################## */
    /**
     The Login ID Text Field
     */
    @IBOutlet weak var login_text_field: NSTextField!
    
    /* ################################################################## */
    /**
     The Password Label
     */
    @IBOutlet var password_label: NSTextField!
    
    /* ################################################################## */
    /**
     The Password Text Field
     */
    @IBOutlet weak var password_text_field: NSTextField!
    
    /* ################################################################## */
    /**
     The Temp HTML Directory Label
     */
    @IBOutlet var temp_directory_name_label: NSTextField!
    
    /* ################################################################## */
    /**
     The Temp HTML Directory Text Field
     */
    @IBOutlet weak var temp_directory_name_text_field: NSTextField!

    /* ############################################################################################################################## */
    // MARK: - Internal Instance Properties
    /* ############################################################################################################################## */
    
    /* ############################################################################################################################## */
    // MARK: - Internal Instance Methods
    /* ############################################################################################################################## */
    func setUpLocalizations() {
        stream_name_label.stringValue = stream_name_label.stringValue.localizedVariant
        stream_name_text_field.placeholderString = stream_name_text_field.placeholderString?.localizedVariant
        input_uri_label.stringValue = input_uri_label.stringValue.localizedVariant
        input_uri_text_field.placeholderString = input_uri_text_field.placeholderString?.localizedVariant
        output_tcp_port_label.stringValue = output_tcp_port_label.stringValue.localizedVariant
        login_label.stringValue = login_label.stringValue.localizedVariant
        login_text_field.placeholderString = login_text_field.placeholderString?.localizedVariant
        password_label.stringValue = password_label.stringValue.localizedVariant
        password_text_field.placeholderString = password_text_field.placeholderString?.localizedVariant
        temp_directory_name_label.stringValue = temp_directory_name_label.stringValue.localizedVariant
        temp_directory_name_text_field.placeholderString = temp_directory_name_text_field.placeholderString?.localizedVariant
    }
    
    /* ############################################################################################################################## */
    // MARK: - Superclass Override Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Set up the various localized items and initial values.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLocalizations()
    }
}
