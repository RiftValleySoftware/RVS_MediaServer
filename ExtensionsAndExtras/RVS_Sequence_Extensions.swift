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

/* ###################################################################################################################################### */
/**
 This file contains extensions and simple utilities that form a baseline of extra runtime seasoning for our projects.
 */
/* ###################################################################################################################################### */
/**
 This cool little extension comes straight from here: https://stackoverflow.com/a/55796671/879365
 */
public extension Sequence {
    /* ################################################################## */
    /**
     This allows us to sort through a sequence container of various instances,
     looking for ones that match a given protocol.
     
     - parameter of: The type that we are filtering for.
     - returns: An Array of elements that conform to the given type.
     */
    func filterForInstances<T>(of: T.Type) -> [T] {
        return self.compactMap { $0 as? T }
    }
}
