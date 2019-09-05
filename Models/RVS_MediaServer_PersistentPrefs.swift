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

import Foundation

/* ############################################################################################################################## */
// MARK: - Specific Persistent Prefs Class
/* ############################################################################################################################## */
/**
 This class translates from the rather generic prefs we have in persistent storage, to an object model.
 It also provides a [KVO](https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift) wrapper for them, and
 will also explicitly reference the main prefs object, so simply instantiating this class will automagically give you the app prefs.
 All changes will be sent to the bundle prefs.
 We use a class, even though we could get away with a struct, because we want to make it clear that we are affecting referenced values (saved in the bundle).
 As the class is KVO-enabled, you can bind it for stuff like SwiftUI.
 As it is a class, it can be subclassed and extended.
 */
public class RVS_MediaServer_PersistentPrefs: RVS_PersistentPrefs {
    /* ############################################################################################################################## */
    // MARK: - Private Enums
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     These are the keys for our prefs.
     Making it CaseIterable means that we can access the cases and return them as strings.
     */
    private enum _PrefsKeys: String, CaseIterable {
        /// This is the Stream Name for the input RTSP stream.
        case stream_name
        /// This is the URI for the input RTSP stream.
        case input_uri
        /// This is the TCP port to use for the output HLS stream
        case output_tcp_port
        /// This is the login ID of the RTSP streaming device.
        case login_id
        /// This is the password for the RTSP streaming device.
        case password
        /// This is the name for our temporary stream files directory.
        case temp_directory_name
        /// This is a flag that determines what type of ffmpeg interaction we will have.
        /// Possible values are "HLS" (simple HLS recoding), "raw" ("raw" ffmpeg argument string).
        case mode_flag
        /// This is the string to be applied, if mode_flag is set to "raw".
        case rawFFMPEGString
        /// This is true, if we are to use an output HTTP server.
        case use_output_http_server
        /// This is true, if the preferences window is open (used to reopen the window on startup).
        case prefs_window_open
        /// This is true, if we are displaying the console screen.
        case display_console_screen
        /// This is true, if we are displaying the video screen.
        case display_video_screen
    }
    
    /* ############################################################################################################################## */
    // MARK: - Private Static Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     These are the default prefs values.
     */
    private static let _defaultPrefsValues: [String: Any] = [
        _PrefsKeys.stream_name.rawValue: "RVS_MediaServer_Stream",
        _PrefsKeys.input_uri.rawValue: "rtsp://170.93.143.139/rtplive/470011e600ef003a004ee33696235daa",
        _PrefsKeys.output_tcp_port.rawValue: 8080,
        _PrefsKeys.login_id.rawValue: "",
        _PrefsKeys.password.rawValue: "",
        _PrefsKeys.temp_directory_name.rawValue: "html",
        _PrefsKeys.mode_flag.rawValue: "HLS",
        _PrefsKeys.rawFFMPEGString.rawValue: "",
        _PrefsKeys.use_output_http_server.rawValue: true,
        _PrefsKeys.prefs_window_open.rawValue: false,
        _PrefsKeys.display_console_screen.rawValue: false,
        _PrefsKeys.display_video_screen.rawValue: false
    ]
    
    /* ############################################################################################################################## */
    // MARK: - Internal Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This clears the prefs to default.
     This does not clear the webserver property.
     */
    func reset() {
        values = type(of: self)._defaultPrefsValues
    }
    
    /* ################################################################## */
    /**
     Init with a key for this instance.
     
     - parameter key: The key (as a String) for this instance.
     */
    init(key inKey: String) {
        super.init(key: inKey)
    }
    
    /* ############################################################################################################################## */
    // MARK: - Public Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     It is an Array of String, containing the keys used to store and retrieve the values from persistent storage.
     */
    override public var keys: [String] {
        return _PrefsKeys.allCases.compactMap { $0.rawValue }
    }
    
    /* ############################################################################################################################## */
    // MARK: - Internal Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     These properties are the "meat" of the class. Accessing them interacts directly with the stored persistent prefs.
     */
    /* ################################################################## */
    /**
     The Stream Title, as a String.
     */
    @objc dynamic var stream_name: String {
        get {
            return values[_PrefsKeys.stream_name.rawValue] as? String ?? ""
        }
        
        set {
            values[_PrefsKeys.stream_name.rawValue] = newValue
            self.didChangeValue(for: \.stream_name)
        }
    }
    
    /* ################################################################## */
    /**
     The input URI, as a String.
     */
    @objc dynamic var input_uri: String {
        get {
            return values[_PrefsKeys.input_uri.rawValue] as? String ?? ""
        }
        
        set {
            values[_PrefsKeys.input_uri.rawValue] = newValue
            self.didChangeValue(for: \.input_uri)
        }
    }
    
    /* ################################################################## */
    /**
     The output TCP port, as an Int.
     */
    @objc dynamic var output_tcp_port: Int {
        get {
            return values[_PrefsKeys.output_tcp_port.rawValue] as? Int ?? 0
        }
        
        set {
            values[_PrefsKeys.output_tcp_port.rawValue] = newValue
            self.didChangeValue(for: \.output_tcp_port)
        }
    }
    
    /* ################################################################## */
    /**
     The Login ID, as a String.
     */
    @objc dynamic var login_id: String {
        get {
            return values[_PrefsKeys.login_id.rawValue] as? String ?? ""
        }
        
        set {
            values[_PrefsKeys.login_id.rawValue] = newValue
            self.didChangeValue(for: \.login_id)
        }
    }
    
    /* ################################################################## */
    /**
     The Password, as a String.
     */
    @objc dynamic var password: String {
        get {
            return values[_PrefsKeys.password.rawValue] as? String ?? ""
        }
        
        set {
            values[_PrefsKeys.password.rawValue] = newValue
            self.didChangeValue(for: \.password)
        }
    }
    
    /* ################################################################## */
    /**
     The Temp Directory Name, as a String.
     */
    @objc dynamic var temp_directory_name: String {
        get {
            return values[_PrefsKeys.temp_directory_name.rawValue] as? String ?? ""
        }
        
        set {
            values[_PrefsKeys.temp_directory_name.rawValue] = newValue
            self.didChangeValue(for: \.temp_directory_name)
        }
    }
    
    /* ################################################################## */
    /**
     Returns true, if we are using a raw parameter list.
     */
    @objc dynamic var use_raw_parameters: Bool {
        get {
            return "raw" == (values[_PrefsKeys.mode_flag.rawValue] as? String ?? "HLS")
        }
        
        set {
            values[_PrefsKeys.mode_flag.rawValue] = newValue ? "raw" : "HLS"
            self.didChangeValue(for: \.use_raw_parameters)
        }
    }
    
    /* ################################################################## */
    /**
     The parameter list (only used if use_raw_parameters is true).
     */
    @objc dynamic var rawFFMPEGString: String {
        get {
            return values[_PrefsKeys.rawFFMPEGString.rawValue] as? String ?? ""
        }
        
        set {
            values[_PrefsKeys.rawFFMPEGString.rawValue] = newValue
            self.didChangeValue(for: \.rawFFMPEGString)
        }
    }
    
    /* ################################################################## */
    /**
     Returns true, if we are using a built-in HTTP server.
     */
    @objc dynamic var use_output_http_server: Bool {
        get {
            return values[_PrefsKeys.use_output_http_server.rawValue] as? Bool ?? true
        }
        
        set {
            values[_PrefsKeys.use_output_http_server.rawValue] = newValue
            self.didChangeValue(for: \.use_output_http_server)
        }
    }
    
    /* ################################################################## */
    /**
     Returns true, if the prefs window is open.
     */
    @objc dynamic var prefs_window_open: Bool {
        get {
            return values[_PrefsKeys.prefs_window_open.rawValue] as? Bool ?? false
        }
        
        set {
            values[_PrefsKeys.prefs_window_open.rawValue] = newValue
            self.didChangeValue(for: \.prefs_window_open)
        }
    }
    
    /* ################################################################## */
    /**
     Returns true, if the console screen is open.
     */
    @objc dynamic var display_console_screen: Bool {
        get {
            return values[_PrefsKeys.display_console_screen.rawValue] as? Bool ?? false
        }
        
        set {
            values[_PrefsKeys.display_console_screen.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     Returns true, if the video screen is open.
     */
    @objc dynamic var display_video_screen: Bool {
        get {
            return values[_PrefsKeys.display_video_screen.rawValue] as? Bool ?? false
        }
        
        set {
            values[_PrefsKeys.display_video_screen.rawValue] = newValue
        }
    }
}
