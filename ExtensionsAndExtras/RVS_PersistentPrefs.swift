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
     */
    private let _defaultKeys: [String]!
    
    /* ################################################################## */
    /**
     */
    private var _values: [String: Any]!
    
    /* ################################################################## */
    /**
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
