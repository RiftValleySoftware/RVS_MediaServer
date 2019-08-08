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
    /* ################################################################## */
    /**
     Simply test creating a new instance of our prefs, making sure that the initial values are correct, then setting random values, then finally, clearing again.
     */
    func testSimpleChangeValues() {
        // Start by allocating a new instance. Since the tests are sandboxed, we can be sure that it will not have any dingleberries.
        let test_Target = RVS_MediaServer_PersistentPrefs()
        test_Target.reset()    // We reset the instance to default.

        // Make sure we have our defaults.
        XCTAssertEqual("RVS_MediaServer_Stream", test_Target.stream_name)
        XCTAssertEqual("", test_Target.input_uri)
        XCTAssertEqual(8080, test_Target.output_tcp_port)
        XCTAssertEqual("", test_Target.login_id)
        XCTAssertEqual("", test_Target.password)
        XCTAssertEqual("html", test_Target.temp_directory_name)

        // Now, set a few random values.
        test_Target.stream_name = "NOPROBLEM"
        test_Target.input_uri = "HIHOWAYA"
        test_Target.output_tcp_port = 80
        test_Target.login_id = "IMFINETANKS"
        test_Target.password = "HOWRU"
        test_Target.temp_directory_name = "OK"

        // Make sure that our prefs are available in this instance.
        XCTAssertEqual("NOPROBLEM", test_Target.stream_name)
        XCTAssertEqual("HIHOWAYA", test_Target.input_uri)
        XCTAssertEqual(80, test_Target.output_tcp_port)
        XCTAssertEqual("IMFINETANKS", test_Target.login_id)
        XCTAssertEqual("HOWRU", test_Target.password)
        XCTAssertEqual("OK", test_Target.temp_directory_name)

        // Make sure that they carry over into a new instance.
        let test_Target2 = RVS_MediaServer_PersistentPrefs()

        XCTAssertEqual("NOPROBLEM", test_Target2.stream_name)
        XCTAssertEqual("HIHOWAYA", test_Target2.input_uri)
        XCTAssertEqual(80, test_Target2.output_tcp_port)
        XCTAssertEqual("IMFINETANKS", test_Target2.login_id)
        XCTAssertEqual("HOWRU", test_Target2.password)
        XCTAssertEqual("OK", test_Target2.temp_directory_name)
        
        // Now, make sure that we can go back to defaults.
        test_Target2.reset()    // We reset the second instance, which should affect the first.
        
        XCTAssertEqual("RVS_MediaServer_Stream", test_Target.stream_name)
        XCTAssertEqual("", test_Target.input_uri)
        XCTAssertEqual(8080, test_Target.output_tcp_port)
        XCTAssertEqual("", test_Target.login_id)
        XCTAssertEqual("", test_Target.password)
        XCTAssertEqual("html", test_Target.temp_directory_name)
    }
    
    /* ################################################################## */
    /**
     This makes sure that we can do key/value obesrving.
     */
    func testKeyValueBinding() {
        class TestObserverClass: NSObject {
            @objc var objectToObserve: RVS_MediaServer_PersistentPrefs
            var observation_stream_name: NSKeyValueObservation?
            var observation_input_uri: NSKeyValueObservation?
            var observation_output_tcp_port: NSKeyValueObservation?
            var observation_login_id: NSKeyValueObservation?
            var observation_password: NSKeyValueObservation?
            var observation_temp_directory_name: NSKeyValueObservation?
            var expectationFulfiller: () -> Void
            
            init(_ object: RVS_MediaServer_PersistentPrefs, fulfiller: @escaping () -> Void) {
                expectationFulfiller = fulfiller
                objectToObserve = object
                super.init()
                
                observation_stream_name = observe(
                    \.objectToObserve.stream_name,
                    options: [.old, .new]
                ) { _, change in
                    XCTAssertEqual("RVS_MediaServer_Stream", change.oldValue)
                    XCTAssertEqual("YOURLYTINKSO", change.newValue)
                    self.expectationFulfiller()
                }
                
                observation_input_uri = observe(
                    \.objectToObserve.input_uri,
                    options: [.old, .new]
                ) { _, change in
                    XCTAssertEqual("", change.oldValue)
                    XCTAssertEqual("WHAZZUP", change.newValue)
                    self.expectationFulfiller()
                }

                observation_output_tcp_port = observe(
                    \.objectToObserve.output_tcp_port,
                    options: [.old, .new]
                ) { _, change in
                    XCTAssertEqual(8080, change.oldValue)
                    XCTAssertEqual(80, change.newValue)
                    self.expectationFulfiller()
                }
                
                observation_login_id = observe(
                    \.objectToObserve.login_id,
                    options: [.old, .new]
                ) { _, change in
                    XCTAssertEqual("", change.oldValue)
                    XCTAssertEqual("IMFINETANKS", change.newValue)
                    self.expectationFulfiller()
                }
                
                observation_password = observe(
                    \.objectToObserve.password,
                    options: [.old, .new]
                ) { _, change in
                    XCTAssertEqual("", change.oldValue)
                    XCTAssertEqual("HOWRU", change.newValue)
                    self.expectationFulfiller()
                }
                
                observation_temp_directory_name = observe(
                    \.objectToObserve.temp_directory_name,
                    options: [.old, .new]
                ) { _, change in
                    XCTAssertEqual("html", change.oldValue)
                    XCTAssertEqual("OK", change.newValue)
                    self.expectationFulfiller()
                }
            }
        }
        
        let test_Target = RVS_MediaServer_PersistentPrefs()
        test_Target.reset()    // We reset the instance to default.
        
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 5
        
        _ = TestObserverClass(test_Target, fulfiller: { expectation.fulfill() })
        
        test_Target.stream_name = "YOURLYTINKSO"
        test_Target.input_uri = "WHAZZUP"
        test_Target.output_tcp_port = 80
        test_Target.login_id = "IMFINETANKS"
        test_Target.password = "HOWRU"
        test_Target.temp_directory_name = "OK"

        // Wait until the expectation is fulfilled, with a timeout of a second.
        wait(for: [expectation], timeout: 1.0)
    }
}
