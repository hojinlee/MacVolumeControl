import AppKit
import XCTest
@testable import MacVolumeControl

final class LaunchAtLoginMenuPresentationTests: XCTestCase {
    func testPresentationMatchesEveryLoginItemState() {
        let expectations: [(LaunchAtLoginMenuState, String, NSControl.StateValue)] = [
            (.disabled, "로그인 시 자동 실행", .off),
            (.enabled, "로그인 시 자동 실행", .on),
            (.requiresApproval, "로그인 시 자동 실행 (승인 필요)", .mixed),
            (.failed, "로그인 시 자동 실행 (설정 실패)", .off),
        ]

        for (state, title, itemState) in expectations {
            let presentation = LaunchAtLoginMenuPresentation(state: state)

            XCTAssertEqual(presentation.title, title)
            XCTAssertEqual(presentation.itemState, itemState)
        }
    }
}
