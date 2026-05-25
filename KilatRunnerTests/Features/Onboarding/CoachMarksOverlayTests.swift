import XCTest
@testable import KilatRunner

final class CoachMarksOverlayTests: XCTestCase {
    func test_onDismiss_setsUserDefaultsFlag_andDoesNotReappear() {
        let storage = CoachMarksStorageSpy()
        let state = CoachMarksState(storage: storage, key: "coach-test")

        XCTAssertTrue(state.isPresented)

        state.dismiss()

        XCTAssertTrue(storage.values["coach-test"] == true)
        XCTAssertFalse(state.isPresented)
        XCTAssertFalse(CoachMarksState(storage: storage, key: "coach-test").isPresented)
    }
}

private final class CoachMarksStorageSpy: CoachMarksStorage {
    var values: [String: Bool] = [:]

    func bool(forKey key: String) -> Bool {
        values[key] ?? false
    }

    func set(_ value: Bool, forKey key: String) {
        values[key] = value
    }
}
