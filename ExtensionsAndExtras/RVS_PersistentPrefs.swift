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
/* ################################################################################################################################## */
// MARK: - Generic Persisten Prefs Class
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
