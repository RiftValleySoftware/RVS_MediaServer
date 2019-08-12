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
 It also provides a [KVO](https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift) wrapper for them.
 This will also explicitly reference the main prefs object, so simply instantiating this class will automagically give you the app prefs. All changes will be sent to the bundle prefs.
 We use a class, even though we could get away with a struct, because we want to make it clear that we are affecting referenced values (saved in the bundle).
 As the class is KVO-enabled, you can bind it for stuff like SwiftUI.
 As it is a class, it can be subclassed and extended.
 */
open class RVS_MediaServer_PersistentPrefs: NSObject, NSCoding {
    /* ############################################################################################################################## */
    // MARK: - Private Static Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is a SINGLETON instance of our prefs.
     I hate SINGLETONS, but in this case, it's safe.
     */
    private static var _prefs: RVS_PersistentPrefs! = nil
    
    /* ############################################################################################################################## */
    // MARK: - Private Enums
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     These are the keys for our prefs.
     */
    private enum _PrefsKeys: String {
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
        _PrefsKeys.input_uri.rawValue: "",
        _PrefsKeys.output_tcp_port.rawValue: 8080,
        _PrefsKeys.login_id.rawValue: "",
        _PrefsKeys.password.rawValue: "",
        _PrefsKeys.temp_directory_name.rawValue: "html"
    ]
    
    /* ############################################################################################################################## */
    // MARK: - Private Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is an accessor that translates between the static prefs SINGLETON, and the instance.
     */
    private var _calcPrefs: RVS_PersistentPrefs! {
        /// We will create a new set of prefs (loading anything saved), if we didn't already have them.
        if  nil == type(of: self)._prefs,
            !tag.isEmpty {
            type(of: self)._prefs = RVS_PersistentPrefs(tag: tag, values: type(of: self)._defaultPrefsValues)
        }
        
        return type(of: self)._prefs
    }

    /* ############################################################################################################################## */
    // MARK: - Class Calculated Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is the "tag" we use for storing the main prefs.
     */
    var tag: String = ""
    
    /* ############################################################################################################################## */
    // MARK: - Instance Stored Properties (Ephemeral)
    /* ############################################################################################################################## */
    
    /* ############################################################################################################################## */
    // MARK: - Internal Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This clears the prefs to default.
     This does not clear the webserver property.
     */
    func reset() {
        _calcPrefs.values = type(of: self)._defaultPrefsValues
    }
    
    /* ################################################################## */
    /**
     Init with a tag for this instance.
     
     - parameter tag: The tag (as a String) for this instance. The default is "0"
     */
    init(tag inTag: String = "0") {
        super.init()
        tag = inTag
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
            return _calcPrefs?.values[_PrefsKeys.stream_name.rawValue] as? String ?? ""
        }
        
        set {
            _calcPrefs?.values[_PrefsKeys.stream_name.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     The input URI, as a String.
     */
    @objc dynamic var input_uri: String {
        get {
            return _calcPrefs?.values[_PrefsKeys.input_uri.rawValue] as? String ?? ""
        }
        
        set {
            _calcPrefs?.values[_PrefsKeys.input_uri.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     The output TCP port, as an Int.
     */
    @objc dynamic var output_tcp_port: Int {
        get {
            return _calcPrefs.values[_PrefsKeys.output_tcp_port.rawValue] as? Int ?? 0
        }
        
        set {
            _calcPrefs.values[_PrefsKeys.output_tcp_port.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     The Login ID, as a String.
     */
    @objc dynamic var login_id: String {
        get {
            return _calcPrefs.values[_PrefsKeys.login_id.rawValue] as? String ?? ""
        }
        
        set {
            _calcPrefs.values[_PrefsKeys.login_id.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     The Password, as a String.
     */
    @objc dynamic var password: String {
        get {
            return _calcPrefs.values[_PrefsKeys.password.rawValue] as? String ?? ""
        }
        
        set {
            _calcPrefs.values[_PrefsKeys.password.rawValue] = newValue
        }
    }
    
    /* ################################################################## */
    /**
     The Temp Directory Name, as a String.
     */
    @objc dynamic var temp_directory_name: String {
        get {
            return _calcPrefs.values[_PrefsKeys.temp_directory_name.rawValue] as? String ?? ""
        }
        
        set {
            _calcPrefs.values[_PrefsKeys.temp_directory_name.rawValue] = newValue
        }
    }

    /* ############################################################################################################################## */
    // MARK: - NSCoding Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This saves off our current state into an encoder.
     
     - parameter with: The encoder we'll be saving into.
     */
    public func encode(with inCoder: NSCoder) {
        inCoder.encode(stream_name, forKey: _PrefsKeys.stream_name.rawValue)
        inCoder.encode(input_uri, forKey: _PrefsKeys.input_uri.rawValue)
        inCoder.encode(output_tcp_port, forKey: _PrefsKeys.output_tcp_port.rawValue)
        inCoder.encode(login_id, forKey: _PrefsKeys.login_id.rawValue)
        inCoder.encode(password, forKey: _PrefsKeys.password.rawValue)
        inCoder.encode(temp_directory_name, forKey: _PrefsKeys.temp_directory_name.rawValue)
    }
    
    /* ################################################################## */
    /**
     This initializes our object off of an encoder.
     
     - parameter coder: The encoder we'll be reading our state from.
     */
    public required init?(coder inDecoder: NSCoder) {
        super.init()
        
        if let value = inDecoder.decodeObject(forKey: _PrefsKeys.stream_name.rawValue) as? String {
            stream_name = value
        }
        
        if let value = inDecoder.decodeObject(forKey: _PrefsKeys.input_uri.rawValue) as? String {
            input_uri = value
        }
        
        if let value = inDecoder.decodeObject(forKey: _PrefsKeys.output_tcp_port.rawValue) as? Int {
            output_tcp_port = value
        }
        
        if let value = inDecoder.decodeObject(forKey: _PrefsKeys.login_id.rawValue) as? String {
            login_id = value
        }
        
        if let value = inDecoder.decodeObject(forKey: _PrefsKeys.password.rawValue) as? String {
            password = value
        }
        
        if let value = inDecoder.decodeObject(forKey: _PrefsKeys.temp_directory_name.rawValue) as? String {
            temp_directory_name = value
        }
    }
}
