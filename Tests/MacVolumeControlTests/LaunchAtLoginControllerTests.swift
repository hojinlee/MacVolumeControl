import ServiceManagement
import XCTest
@testable import MacVolumeControl

final class LaunchAtLoginControllerTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var settingsStore: SettingsStore!
    private var service: FakeLaunchAtLoginService!

    override func setUp() {
        super.setUp()
        suiteName = UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        settingsStore = SettingsStore(defaults: defaults)
        service = FakeLaunchAtLoginService(status: .notRegistered)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        service = nil
        settingsStore = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultIsAppliedOnce() {
        let controller = makeController()

        controller.applyDefaultIfNeeded()
        XCTAssertEqual(controller.menuState, .enabled)

        service.status = .notRegistered
        controller.applyDefaultIfNeeded()

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertTrue(settingsStore.hasAppliedLaunchAtLoginDefault)
    }

    func testDisabledItemRegistersWhenToggled() {
        let controller = makeController()

        controller.performMenuAction()

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertEqual(controller.menuState, .enabled)
    }

    func testEnabledItemUnregistersWhenToggled() {
        service.status = .enabled
        let controller = makeController()

        controller.performMenuAction()

        XCTAssertEqual(service.unregisterCallCount, 1)
        XCTAssertEqual(controller.menuState, .disabled)
    }

    func testApprovalStateOpensSystemSettings() {
        service.status = .requiresApproval
        var openCount = 0
        let controller = makeController(openSystemSettings: { openCount += 1 })

        controller.performMenuAction()

        XCTAssertEqual(openCount, 1)
        XCTAssertEqual(controller.menuState, .requiresApproval)
    }

    func testRegistrationFailureIsExposedAndCanBeRetried() {
        service.registerError = TestError.registration
        let controller = makeController()

        controller.performMenuAction()
        XCTAssertEqual(controller.menuState, .failed)

        service.registerError = nil
        controller.performMenuAction()
        XCTAssertEqual(controller.menuState, .enabled)
    }

    func testApprovalAfterDeniedRegistrationCountsAsAppliedDefault() {
        service.statusAfterRegister = .requiresApproval
        service.registerError = TestError.registration
        let controller = makeController()

        controller.applyDefaultIfNeeded()

        XCTAssertTrue(settingsStore.hasAppliedLaunchAtLoginDefault)
        XCTAssertEqual(controller.menuState, .requiresApproval)
    }

    func testNotFoundServiceAttemptsDefaultRegistration() {
        service.status = .notFound
        let controller = makeController()

        controller.applyDefaultIfNeeded()

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertEqual(controller.menuState, .enabled)
    }

    private func makeController(
        openSystemSettings: @escaping () -> Void = {}
    ) -> LaunchAtLoginController {
        LaunchAtLoginController(
            service: service,
            settingsStore: settingsStore,
            openSystemSettings: openSystemSettings
        )
    }
}

private enum TestError: Error {
    case registration
}

private final class FakeLaunchAtLoginService: LaunchAtLoginServicing {
    var status: SMAppService.Status
    var statusAfterRegister: SMAppService.Status = .enabled
    var registerError: Error?
    var unregisterError: Error?
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(status: SMAppService.Status) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        if let registerError {
            if statusAfterRegister == .requiresApproval {
                status = statusAfterRegister
            }
            throw registerError
        }
        status = statusAfterRegister
    }

    func unregister() throws {
        unregisterCallCount += 1
        if let unregisterError { throw unregisterError }
        status = .notRegistered
    }
}
