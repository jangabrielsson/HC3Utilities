import XCTest
@testable import HC3Utilities

final class HC3UtilitiesTests: XCTestCase {
    var hc3: HC3Utilities = HC3Utilities(ip:"192.168.1.57",user:"admin",password:"admin")
    
    func testDecodeJSON() throws {
        let data = stringFrom(resource:"test1.device")!
        if let res = try? hc3.decode(str:data) as HC3Utilities.types.Device {
            XCTAssertEqual(res.name, "Dimmer switch")
        }
    }
    
    func testDetDevices() throws {
        let res = try hc3.fibaro.getDevices()
        XCTAssert(res.count > 0)
    }
}
