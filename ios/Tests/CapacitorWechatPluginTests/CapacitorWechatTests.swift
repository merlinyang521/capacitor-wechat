import XCTest
@testable import CapacitorWechatPlugin

class CapacitorWechatTests: XCTestCase {
    func testIsInstalled() {
        // Ensure the basic API wiring still works.
        let implementation = CapacitorWechat()
        let result = implementation.isInstalled()

        // Without WeChat SDK integrated, this should return false
        XCTAssertFalse(result)
    }
}
