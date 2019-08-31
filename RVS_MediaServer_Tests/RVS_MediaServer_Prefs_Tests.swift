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

import XCTest

/* ################################################################################################################################## */
// MARK: - Tests for the Persistent Prefs.
/* ################################################################################################################################## */
/**
 Just some simple tests, to make sure that our persistent prefs are in good shape.
 */
class RVS_MediaServer_Prefs_Tests: XCTestCase {
    let instanceTestUUID = UUID().uuidString    // This is a UUID that will be valid for the lifetime of the instance (across tests).
    var spotTestUUID: String!                   // This is a UUID that is established in setup(), so is only valid per test.
    
    /* ################################################################## */
    /**
     This sets up a UUID to ensure that every test has a unique UUID, and won't mix up with other tests.
     */
    override func setUp() {
        spotTestUUID = UUID().uuidString
    }
    
    /* ################################################################## */
    /**
     This test will make sure that the internal values[:] Dictionary jives with the binding/casting accessors.
     */
    func testBasicValueSync() {
        let testingSet: [String: Any] = [
            "stream_name": "testBasicValueSync",
            "input_uri": "https://xkcd.com",
            "output_tcp_port": 12345,
            "login_id": "Fred",
            "password": "WILMAAAA!!!",
            "temp_directory_name": "Barney",
            "mode_flag": "HLS",
            "rawFFMPEGString": "Supercalifragilisticexpialidocious",
            "use_output_http_server": true,
            "prefs_window_open": true,
            "display_console_screen": true
        ]
        let prefsUnderTest = RVS_MediaServer_PersistentPrefs(key: spotTestUUID)
        prefsUnderTest.values = testingSet
        XCTAssertEqual(testingSet["stream_name"] as? String ?? "", prefsUnderTest.stream_name)
        XCTAssertEqual(testingSet["input_uri"] as? String ?? "", prefsUnderTest.input_uri)
        XCTAssertEqual(testingSet["output_tcp_port"] as? Int ?? 0, prefsUnderTest.output_tcp_port)
        XCTAssertEqual(testingSet["login_id"] as? String ?? "", prefsUnderTest.login_id)
        XCTAssertEqual(testingSet["password"] as? String ?? "", prefsUnderTest.password)
        XCTAssertEqual(testingSet["temp_directory_name"] as? String ?? "", prefsUnderTest.temp_directory_name)
        XCTAssertEqual(false, prefsUnderTest.use_raw_parameters)
        XCTAssertEqual(testingSet["rawFFMPEGString"] as? String ?? "", prefsUnderTest.rawFFMPEGString)
        XCTAssertEqual(true, prefsUnderTest.use_output_http_server)
        XCTAssertEqual(true, prefsUnderTest.prefs_window_open)
        XCTAssertEqual(true, prefsUnderTest.display_console_screen)
    }
}
