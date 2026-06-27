import AppKit

struct LaunchAtLoginMenuPresentation {
    let title: String
    let itemState: NSControl.StateValue

    init(state: LaunchAtLoginMenuState) {
        switch state {
        case .disabled:
            title = "로그인 시 자동 실행"
            itemState = .off
        case .enabled:
            title = "로그인 시 자동 실행"
            itemState = .on
        case .requiresApproval:
            title = "로그인 시 자동 실행 (승인 필요)"
            itemState = .mixed
        case .failed:
            title = "로그인 시 자동 실행 (설정 실패)"
            itemState = .off
        }
    }
}
