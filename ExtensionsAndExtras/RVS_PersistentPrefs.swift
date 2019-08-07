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
// MARK: - Persistent Prefs Class
/* ############################################################################################################################## */
/**
 This class translates from the rather generic prefs we have in persistent storage, to an object model.
 This will also explicitly reference the main prefs object, so simply instantiating this struct will automagically give you the app prefs.
 We use a class, even though we could get away with a struct, because we want to make it clear that we are affecting referenced values (saved in the bundle).
 This class is also set up for key/value observing, so you can bind it.
 */
class RVS_MediaServer_PersistentPrefs: NSObject {
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
            // We use the app name as our tag.
            let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String {
            type(of: self)._prefs = RVS_PersistentPrefs(tag: appName, values: type(of: self)._defaultPrefsValues)
        }
        
        return type(of: self)._prefs
    }
    
    /* ############################################################################################################################## */
    // MARK: - Internal Calculated Properties
    /* ############################################################################################################################## */
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
    // MARK: - Internal Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This clears the prefs to default.
     */
    func reset() {
        _calcPrefs.values = type(of: self)._defaultPrefsValues
    }
}

/* ################################################################################################################################## */
/**
 This is a "persistent defaults" class (not a struct -we want this to be by reference). It uses the app standard userDefaults mechanism
 for saving and retrieving a Dictionary<String, Any>.
 */
class RVS_PersistentPrefs {
    /* ############################################################################################################################## */
    // MARK: - Private Instance Properties
    /* ############################################################################################################################## */
    /**
     I make these implicitly unwrapped optionals on purpose. I want this puppy to crash if it's in bad shape.
     */
    /* ################################################################## */
    /**
     This will contain the default keys that are used to describe the stored prefs.
     */
    private let _defaultKeys: [String]!
    
    /* ################################################################## */
    /**
     These are the current values.
     */
    private var _values: [String: Any]!
    
    /* ################################################################## */
    /**
     This is the tag for the overall set of prefs.
     */
    private let _tag: String!

    /* ############################################################################################################################## */
    // MARK: - Private Instance Methods
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This simply takes a snapshot of all the text fields, and saves them in the app defaults container.
     */
    private func _saveState() {
        let defaults = UserDefaults.standard
        
        if let _defaults = _defaultKeys {
            var savingPrefs: [String: Any] = [:]
            
            // Read in the defaults that we saved.
            _defaults.forEach {
                savingPrefs[$0] = defaults.object(forKey: $0)
            }

            _values.forEach {
                savingPrefs[$0.key] = $0.value
            }
            
            #if DEBUG
                print("Saving Prefs: \(String(describing: savingPrefs))")
            #endif
            
            UserDefaults.standard.set(savingPrefs, forKey: _tag)
        }
    }
    
    /* ################################################################## */
    /**
     This reads anything in the app defaults container, and applies them to set up the text fields.
     */
    private func _loadState() {
        let standardDefaultsObject = UserDefaults.standard
        #if DEBUG
            print("Standard User Defaults Object: \(String(describing: standardDefaultsObject))")
        #endif

        if let loadedPrefs = standardDefaultsObject.object(forKey: _tag) as? [String: Any] {
            #if DEBUG
                print("Loaded Prefs: \(String(describing: loadedPrefs))")
            #endif
            
            if let _defaults = _defaultKeys {
                var newPrefs: [String: Any] = [:]
                
                // Read in the defaults that we saved. This ensures that we get all the various
                _defaults.forEach {
                    newPrefs[$0] = loadedPrefs[$0]
                }

                // Update the defaults with what we saved the last time.
                loadedPrefs.forEach {
                    newPrefs[$0.key] = $0.value
                }
                
                _values = newPrefs
            }
        }
    }
    
    /* ############################################################################################################################## */
    // MARK: - Private Instance Initializer
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     This is private to prevent this class from being instantiated in an undefined state.
     */
    private init(_defaults inDefaults: [String: Any] = [:], _tag inTag: String = "", _values inValues: [String: Any] = [:]) {
        _defaultKeys = nil
        _tag = nil
        _values = nil
    }

    /* ############################################################################################################################## */
    // MARK: - Public Instance Properties
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     Accessor for the values. Returns them as a String-hashed Dictionary of Any.
     
     When we read, we always load, first, and when we write, we always save, after.
     */
    var values: [String: Any]! {
        get {
            _loadState()
            return _values
        }
        
        set {
            _values = newValue
            _saveState()
        }
    }
    
    /* ############################################################################################################################## */
    // MARK: - Public Instance Initializer
    /* ############################################################################################################################## */
    /* ################################################################## */
    /**
     The default initializer.
     
     - parameter tag: This is the tag for the overall set of stored prefs.
     - parameter values: This is the set of default values, as String-hashed Dictionary of Any.
     */
    init(tag inTag: String, values inValues: [String: Any]) {
        _tag = inTag
        _values = inValues
        _defaultKeys = Array(inValues.keys)
        
        #if DEBUG
            print("Default Prefs: \(String(describing: _values))")
        #endif
        
        UserDefaults.standard.register(defaults: _values)
    }
    
    /* ################################################################## */
    /**
     This allows you to access values directly, via subscript.
     
     -returns: The value (Any), or nil, if not available.
     */
    public subscript(_ inStringKey: String) -> Any! {
        get {
            if let values = values, let value = values[inStringKey] {
                return value
            }
            return nil
        }
        
        set {
            if nil != newValue {
                self.values[inStringKey] = newValue
            } else {
                if var values = values {
                    values.removeValue(forKey: inStringKey)
                    self.values = values
                }
            }
        }
    }
}
