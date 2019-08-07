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

import Foundation   // Foundation is required for CharacterSet. If we didn't have that, then, we could do without this.

/* ################################################################################################################################## */
/**
 This protocol is an abstract base for IP addresses. When we parse a String as an IP address, it will return a specific implementation of this.

 When we say "valid," we don't mean the address resolves to anything; just that it is syntactically correct.
 
 This file is the only one that you need for your implementation. Simply copy it wherever you want in your project, and add it to your chosen target.
 */
public protocol RVS_IPAddress {
    /* ################################################################## */
    /**
     - returns: true, if the IP address is invalid (all 0's).
     */
    var isEmpty: Bool { get }
    
    /* ################################################################## */
    /**
     - returns: true, if this is a valid IPV6 address.
     */
    var isV6: Bool { get }
    
    /* ################################################################## */
    /**
     - returns: true, if this is a valid IPV6 or IPV4 address.
     */
    var isValidAddress: Bool { get }
    
    /* ################################################################## */
    /**
     - returns: just the address portion of an address/port pair, as a syntactically correct String.
     */
    var address: String { get }
    
    /* ################################################################## */
    /**
     - returns: both the address, and the port, as a syntactically correct String.
     */
    var addressAndPort: String { get }
    
    /* ################################################################## */
    /**
     - returns: The TCP port, as an unsigned integer.
     */
    var port: Int { get set }
    
    /* ################################################################## */
    /**
     - returns: The actual IP address, as an Array of Int, with each element being one of the displayed elements.
     */
    var addressArray: [Int] { get set }
    
    /* ################################################################## */
    /**
     - returns: The address and port, as a String.
     */
    var description: String { get }
}

/* ################################################################################################################################## */
/**
 This protocol is an abstract base for IP addresses. When we parse a String as an IP address, it will return a specific implementation of this.
 
 When we say "valid," we don't mean the address resolves to anything; just that it is syntactically correct.
 */
extension RVS_IPAddress {
    /* ################################################################## */
    /**
     - returns: true, if the IP address is invalid (all 0's).
     */
    public var isEmpty: Bool { return addressArray.isEmpty }
    
    /* ################################################################## */
    /**
     - returns: true, if this is a valid IPV6 address.
     */
    public var isV6: Bool { return false }
    
    /* ################################################################## */
    /**
     - returns: true, if this is a valid IPV6 or IPV4 address.
     */
    public var isValidAddress: Bool { return false }
    
    /* ################################################################## */
    /**
     - returns: just the address portion of an address/port pair, as a syntactically correct String.
     */
    public var address: String { return "" }
    
    /* ################################################################## */
    /**
     - returns: The address and port, as a String.
     */
    public var description: String { return addressAndPort }
}

/* ################################################################## */
/**
 This is a factory for IP addresses (as Strings).
 
 - parameter inString: The string to be parsed.
 - parameter isPadded: Optional IPv6 padding variable. If true (default is false), then IPv6 addresses will be fully padded. Ignored for IPv4.
 - returns: a valid IPv4 or IPv6 address object. nil, if the String cannot produce a valid IP address.
 */
public func RVS_IPAddressExtractIPAddress(_ inString: String, isPadded inIsPadded: Bool = false) -> RVS_IPAddress! {
    let iPv4 = RVS_IPAddressV4(inString)
    
    if iPv4.isValidAddress {
        return iPv4
    } else {
        var iPv6 = RVS_IPAddressV6(inString)
        iPv6.isPadded = inIsPadded
        if iPv6.isValidAddress {
            return iPv6
        }
    }
    
    return nil
}

/* ################################################################## */
/**
 This is a factory for IP addresses (as Int Arrays).
 
 - parameter array: The Array to be used.
 - parameter port: An optional (default is 0 -no port) Int, with the TCP port.
 - parameter isPadded: Optional IPv6 padding variable. If true (default is false), then IPv6 addresses will be fully 0-padded (no shortcuts). Ignored for IPv4.
 - returns: a valid IPv4 or IPv6 address object. nil, if the Array cannot produce a valid IP address.
 */
public func RVS_IPAddressExtractIPAddress(array inArray: [Int], port inPort: Int = 0, isPadded inIsPadded: Bool = false) -> RVS_IPAddress! {
    let iPv4 = RVS_IPAddressV4(inArray, port: inPort)
    
    if iPv4.isValidAddress {
        return iPv4
    } else {
        var iPv6 = RVS_IPAddressV6(inArray, port: inPort)
        iPv6.isPadded = inIsPadded
        if iPv6.isValidAddress {
            return iPv6
        }
    }
    
    return nil
}

/* ################################################################################################################################## */
/**
 This is a specialization for IPV4
 */
public struct RVS_IPAddressV4: RVS_IPAddress {
    /* ################################################################## */
    /**
     - returns: the TCP Port of the IP address.
     */
    public var port: Int = 0
    
    /* ################################################################## */
    /**
     - returns: The IP address element Array, vetted and cleaned for V4
     */
    public var addressArray: [Int]  = [] {
        didSet {    // This validates the array. It clears it if the array is invalid.
            if 4 != addressArray.count || addressArray.reduce(false, { (prev, element) -> Bool in
                return prev || (0 > element) || (255 < element)
            }) {
                addressArray = []
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: The IPV4 String representation.
     */
    public var address: String {
        var ret = "0.0.0.0"
        
        if !addressArray.isEmpty {
            ret = addressArray.compactMap { String(format: "%d", $0) }.joined(separator: ".")
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     - returns: The String, representing both the address and the port. Just the address, if no port. 0 is a valid TCP port, but we don't count that. 0 is "no port."
     */
    public var addressAndPort: String {
        return address + ((0 < port) ? ":" + String(port) : "")
    }
    
    /* ################################################################## */
    /**
     - returns: true, if this is a valid IPV4 address.
     */
    public var isValidAddress: Bool {
        return 4 == addressArray.count
    }
    
    /* ################################################################## */
    /**
     This init extracts an IPV4 address, and, if applicable, TCP port, from a given string.
     
     The rule for an IPv4 address is quite simple. It is four (4) sequential bytes (8 bits), expressed as decimal (not hexadecimal) numbers, and separated by periods (.), like so: `123.123.123.123`.
     
     Each segment is a positive integer, from 0-255. They can be zero-padded, but generally are not.
     
     If an additional TCP port is provided, that is indicated by appending a colon (:) to the end, followed immediately by a positive integer, like so: `123.123.123.123:456`.
     
     - parameter inString: The String to be parsed.
     */
    public init(_ inString: String) {
        addressArray = []
        port = 0
        
        let charset = CharacterSet(charactersIn: "0123456789.:").inverted
        let parseTarget = inString.trimmingCharacters(in: .whitespacesAndNewlines) // We trim whitespace, because we're nice like that.

        if !parseTarget.isEmpty, nil == parseTarget.rangeOfCharacter(from: charset) {
            let addrPort = parseTarget.components(separatedBy: ":")
            let split = addrPort[0].components(separatedBy: ".")
            
            if 4 == split.count {
                addressArray = split.compactMap {
                    if let ret = Int($0), (0..<256).contains(ret) {
                        return ret
                    }
                    
                    return nil
                }
                
                if 4 == addressArray.count, 1 < addrPort.count {
                    port = Int(addrPort[1]) ?? 0
                } else if 4 != addressArray.count {
                    addressArray = []
                    port = 0
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     Initialize from an Array of Int.
     
     - parameter inArray: An optional Array of Int. Exactly 4 elements, with positive integer values below 256.
     - parameter port: An optional parameter (default is 0), that allows you to explicitly specify the port.
     */
    init(_ inArray: [Int] = [], port inPort: Int = 0) {
        var adArr: [Int] = inArray
        var prt: Int = inPort
        if 4 != inArray.count || inArray.reduce(false, { (current, next) -> Bool in
            return current || !(0..<256).contains(next)
        }) {
            adArr = []
            prt = 0
        }
        addressArray = adArr
        port = prt
    }
}

/* ################################################################################################################################## */
/**
 This is a specialization for IPV6
 */
public struct RVS_IPAddressV6: RVS_IPAddress {
    /* ################################################################## */
    /**
     - returns: true, if we want the address Strings to be zero-padded (default is false).
     */
    public var isPadded: Bool = false
    
    /* ################################################################## */
    /**
     - returns: the TCP Port of the IP address.
     */
    public var port: Int = 0
    
    /* ################################################################## */
    /**
     - returns: true
     */
    public var isV6: Bool = true
    
    /* ################################################################## */
    /**
     - returns: true, if this is a valid IPV6 address.
     */
    public var isValidAddress: Bool {
        return 8 == addressArray.count
    }
    
    /* ################################################################## */
    /**
     - returns: The IPV6 String representation. If isPadded is true, then each element will be zero-padded, and no shortcuts will be taken. If false, then we "shortcut" consecutive zeores.
     */
    public var address: String {
        var ret = isPadded ? "0000:0000:0000:0000:0000:0000:0000:0000" : "::"
        if 8 == addressArray.count {
            if !isPadded {  // If we will be shorcutting, then we should look for the longest run of zeroes.
                // Make our Array of Int into an Array of String.
                var retAr = addressArray.compactMap { String(format: "%X", $0) }
                
                var scrubMap: [Range<Int>] = [] // We will use this to make a "map" of all the places we have consecutive zeroes.
                var currentRange: Range<Int>!   // This will be used to track the current set. It is nil, if there is no current set.
                for en in addressArray.enumerated() {   // We loop through our Array of Int, and look for occurrences of zero.
                    if 0 == en.element, let minimum = currentRange?.lowerBound {    // If we had started a Range, then we simply extend it by the current index position.
                        currentRange = minimum..<en.offset
                    } else if 0 == en.element, nil == currentRange {    // If this is our first zero, then we start a new Range. It's currently empty, but exists.
                        currentRange = en.offset..<en.offset
                    } else if nil != currentRange { // If this is not a zero, but we have an existing current Range, we add the Range to our map, and reset it for the next set of zeroes.
                        if 0 < currentRange.upperBound - currentRange.lowerBound {
                            currentRange = currentRange.lowerBound..<currentRange.upperBound + 1
                            scrubMap.append(currentRange)
                        }
                        currentRange = nil
                    }
                }
                
                // If the last digit is 0, and the shortcut runs to the end, then we need to go up one more, and append it, because it never got caught in the looper.
                if nil != currentRange, 0 < currentRange.upperBound - currentRange.lowerBound, addressArray.count - 1 == currentRange.upperBound, 0 == addressArray[addressArray.count - 1] {
                    currentRange = currentRange.lowerBound..<addressArray.count
                    scrubMap.append(currentRange)
                }
                
                if !scrubMap.isEmpty, 8 == (scrubMap[0].upperBound - scrubMap[0].lowerBound) {   // Nice quick shortcut for a completely zero address.
                    ret = "::"
                } else {
                    // Now, we look for the longest consecutive set of zeroes.
                    let scrubRange = scrubMap.reduce(0..<0) { (_ inCurrent: Range<Int>, _ inValue: Range<Int>) -> Range<Int> in
                        let currentVal = inCurrent.upperBound - inCurrent.lowerBound
                        let newVal = inValue.upperBound - inValue.lowerBound
                        
                        return newVal > currentVal ? inValue : inCurrent
                    }
                    
                    // Replace the longest consecutive run of zeroes with an empty String, so we will get two colons next to each other when we collapse the String Array.
                    if !scrubRange.isEmpty {    // Only if we actually have a scrubrange.
                        retAr.replaceSubrange(scrubRange, with: [""])
                    }
                    
                    // Collapse the String Array.
                    ret = retAr.joined(separator: ":")
                    
                    // In the case of the shortcut going "all the way to the end," we add one more colon.
                    if  !scrubRange.isEmpty, scrubRange.upperBound == addressArray.count {
                        ret += ":"
                    } else if !scrubRange.isEmpty, 0 == scrubRange.lowerBound {  // Same with if the scrub was at the start.
                        ret = ":" + ret
                    }
                }
            } else {    // Otherwise, we simply give the full four digits for each place.
                // Make our Array of Int into an Array of padded Hex value Strings, then join that with colons.
                ret = addressArray.map { String(format: "%04X", $0) }.joined(separator: ":")
            }
        }
        
        return ret.lowercased() // The convention is to use lowercase for hex digits.
    }
    
    /* ################################################################## */
    /**
     */
    public var addressAndPort: String {
        if 0 < port {
            return "[" + self.address + "]:" + String(port)
        } else {
            return address
        }
    }
    
    /* ################################################################## */
    /**
     - returns: The IP address element Array, vetted and cleaned for V6
     */
    public var addressArray: [Int] {
        didSet {
            if 8 != addressArray.count || addressArray.reduce(false, { (prev, element) -> Bool in
                return prev || (0 > element) || (65535 < element)
            }) {
                addressArray = []
            }
        }
    }

    /* ################################################################## */
    /**
     This init extracts an IPV6 address, and, if applicable, TCP port, from a given string.
     
     The definition of an IPV6 address is: `XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX`
     
     Where `X` is 0...F (hexadecimal). There are shortcuts (discussed below), but we assume leading zeroes, and all zeores are represented.
     
     Each segment is a positive integer, from 0 - 65535 (FFFF in hexadecimal).
     
     If there is an additional TCP port, then the IP address is bracketed, and followed immediately by a colon (:), then immediately by a positive integer, like this: `[XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX]:Y`
     
     Where `Y` is a positive integer
     
     SHORTCUTS:
     
     You can specify a range of 0-filled elements by using `::` as a shortcut. This is only allowed once in the entire address, so:
     
     `XXXX:0000:0000:0000:XXXX:0000:0000:XXXX` can be written as `XXXX::XXXX:0000:0000:XXXX` or `XXXX:0000:0000:0000:XXXX::XXXX`
     
     Usually, the first shortcut will be selected, as it's the longest range.
     
     You can have a maximum of four (4) hexadecimal characters in an element. Case of the hex digits is usually lowercased, as a convention, but uppercased is allowed. We use lowercase.
     
     You cannot have characters other than 0-9, a-f (or A-F) in an element.
     
     You must separate elements with colons (:). If you are specifying a port, you must wrap the address in brackets ([]). You must have BOTH brackets if you are wrapping the address.
     
     You can wrap an address in brackets, even if you do not specify a port.
     
     If you specify a port, it must appear after a colon (:), after the closing bracket (]), so you would have `]:12345`, to specify TCP Port 12345.
     
     You can have a maximum of eight (8) elements.
     
     Illegal formats and syntax errors result in no address being set. This method does not guess.
     
     - parameter inString: The String to be parsed.
     */
    public init(_ inString: String) {
        /* ################################################################## */
        /**
         This returns an Array of indexes that map all the occurrences of a given substring.
         
         - parameter in: The string to be searched.
         - parameter of: The substring we're looking for.
         - parameter options: The String options for the search.
         
         - returns: an Array, containing the indexes of each occurrence. Empty Array, if does not occur.
         */
        func indexes(in inContextString: String, of inString: String, options inOptions: String.CompareOptions = []) -> [String.Index] {
            var result: [String.Index] = []
            var start = inContextString.startIndex
            
            while start < inContextString.endIndex, let range = inContextString[start..<inContextString.endIndex].range(of: inString, options: inOptions) {
                result.append(range.lowerBound)
                start = range.lowerBound < range.upperBound ? range.upperBound: inContextString.index(range.lowerBound, offsetBy: 1, limitedBy: inContextString.endIndex) ?? inContextString.endIndex
            }
            
            return result
        }

        addressArray = []
        port = 0
        
        if !inString.isEmpty {
            let parseTarget = inString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() // We use uppercased to ensure consistency. We also trim whitespace, because we're nice like that.
            let shortcutCount = indexes(in: parseTarget, of: "::").count // How many shortcuts we have (should be no more than 1)
            
            // The rules: Has to be valid hexadecimal numbers, possibly bracketed, and no more than one "shortcut."
            if nil == parseTarget.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789ABCDEF:[]").inverted), 2 > shortcutCount {
                // This weird little test is because of edge cases, where we could get something like ":23" (an IPv4 port-only).
                // In that case, we should fail. Also, any less than eight needs a shortcut.
                if 1 == shortcutCount || 7 < parseTarget.components(separatedBy: ":").count {    // We could have 9, if we are specifying a port.
                    var addressStartIndex = parseTarget.startIndex
                    var addressEndIndex = parseTarget.endIndex
                    
                    // See if the address is bracketed (maybe with a port).
                    if let openBracket = parseTarget.firstIndex(of: "[") {
                        if let closeBracket = parseTarget.firstIndex(of: "]"), closeBracket > openBracket { // Close must come after open.
                            addressStartIndex = parseTarget.index(after: openBracket)   // The address always starts after the open bracket.
                            addressEndIndex = closeBracket  // The last digit of the address is just before the close bracket
                            
                            let portString = String(parseTarget[addressEndIndex..<parseTarget.endIndex])    // Any port will come after the closing bracket.
                            // ...and we should have a colon right after the close bracket.
                            if 2 < portString.count, let lastColon = portString.firstIndex(of: ":"), let portInt = Int(portString[portString.index(after: lastColon)...]) {
                                port = portInt
                            }
                        } else {    // If we got here, it means that we didn't have a close bracket.
                            return
                        }
                    } else if nil != parseTarget.firstIndex(of: "]") {  // A close bracket only is also a boo-boo.
                        return
                    }
                    
                    // Exctract the address.
                    let addressString = String(parseTarget[addressStartIndex..<addressEndIndex])
                    
                    // Assuming that we were able to pluck an address string out of the above mess, we look for a shortcut.
                    let shortcutIndexRef = indexes(in: addressString, of: "::")
                    // If we have any shortcuts, we get the first (which is the only) one.
                    let shortcutIndex: String.Index = !shortcutIndexRef.isEmpty ? shortcutIndexRef[0] : addressString.endIndex
                    
                    // Create Integer Arrays for before and after the shortcut. If there's no shortcut, afterShortcut will be empty.
                    let beforeShortcut = (addressString[addressString.startIndex..<shortcutIndex]).components(separatedBy: ":").compactMap { Int($0, radix: 16) }
                    let afterShortcut = (addressString[shortcutIndex..<addressString.endIndex]).components(separatedBy: ":").compactMap { Int($0, radix: 16) }
                    
                    let totalCount = beforeShortcut.count + afterShortcut.count
                    
                    if 8 >= totalCount {  // Can't have more than 8, total.
                        addressArray = beforeShortcut   // At minimum, the before Array is a starting point.
                        addressArray.append(contentsOf: [Int](repeating: 0, count: 8 - totalCount)) // This is how many we need to fill with 0's
                        addressArray.append(contentsOf: afterShortcut)
                    }
                    
                    // Make damn sure we're of legal drinking age.
                    addressArray = addressArray.compactMap { return (0..<65536).contains($0) ? $0 : nil }
                }
            }
            
            // Anything amiss, we SCRAM the reactor completely.
            if 8 != addressArray.count {
                addressArray = []
            }
            
            // Bad address, no port.
            if addressArray.isEmpty {
                port = 0
            }
        }
    }
    
    /* ################################################################## */
    /**
     Default initializer -Allows us to forgo initial values.
     
     - parameter inArray: An optional Array of Int. Exactly 8 elements, with positive integer values below 65536.
     - parameter port: An optional (Default is 0) positive Int, with the TCP Port for the address.
     - parameter isPadded: An optional Bool. If true (default is false), then the address components are complete (no shortcuts) and 0-padded.
     */
    public init(_ inArray: [Int] = [], port inPort: Int = 0, isPadded inIsPadded: Bool = false) {
        var adArr: [Int] = inArray
        var prt: Int = inPort
        if 8 != inArray.count || inArray.reduce(false, { (current, next) -> Bool in
            return current || !(0..<65536).contains(next)
        }) {
            adArr = []
            prt = 0
        }
        addressArray = adArr
        port = prt
    }
}

/* ###################################################################################################################################### */
/**
 This is an extension to the String type that returns the String as an IP address.
 */
public extension String {
    /* ################################################################## */
    /**
     - returns: the String, parsed as an IP address. It will be either an instance of RVS_IPAddressV4 or RVS_IPAddressV6. It will be nil, if the IP Address is invalid (no instance).
     */
    var ipAddress: RVS_IPAddress? {
        return RVS_IPAddressExtractIPAddress(self)
    }
}
