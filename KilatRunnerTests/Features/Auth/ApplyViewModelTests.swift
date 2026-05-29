import XCTest
@testable import KilatRunner

@MainActor
final class ApplyViewModelTests: XCTestCase {
    func test_submitsWithAllFields() async {
        let repo = MockApplicationRepository()
        let viewModel = makeCompleteViewModel(repository: repo)

        await viewModel.submit()

        XCTAssertEqual(repo.applyCallCount, 1)
        XCTAssertEqual(viewModel.submittedApplicationId, "KR-2026-00001")
        XCTAssertEqual(repo.lastRequest?.phone, "+60123456789")
        XCTAssertEqual(repo.lastRequest?.plateNumber, "VKL4521")
    }

    func test_submitDisabledUntilConsent() {
        let viewModel = makeCompleteViewModel()
        viewModel.consentAcknowledged = false

        XCTAssertFalse(viewModel.isSubmitEnabled)

        viewModel.consentAcknowledged = true
        XCTAssertTrue(viewModel.isSubmitEnabled)
    }

    func test_chipSelection_multipleAllowed() {
        let viewModel = ApplyViewModel(repository: MockApplicationRepository())

        viewModel.toggleExperience(.dogs)
        viewModel.toggleExperience(.cats)

        XCTAssertEqual(viewModel.petExperience, [.dogs, .cats])
    }

    private func makeCompleteViewModel(repository: ApplicationRepositoryProtocol = MockApplicationRepository()) -> ApplyViewModel {
        let vm = ApplyViewModel(repository: repository)
        vm.name = "Aiman Hakim"
        vm.phone = "123456789"
        vm.icNumber = "900101141234"
        vm.vehicleType = .motorbike
        vm.plateNumber = "vkl4521"
        vm.petExperience = [.dogs, .cats]
        vm.comfortableWithLivePets = true
        vm.consentAcknowledged = true
        return vm
    }
}

final class MockApplicationRepository: ApplicationRepositoryProtocol {
    var applyCallCount = 0
    var lastRequest: RunnerApplicationRequest?
    var result = RunnerApplicationResponse(applicationId: "KR-2026-00001")

    func apply(_ request: RunnerApplicationRequest) async throws -> RunnerApplicationResponse {
        applyCallCount += 1
        lastRequest = request
        return result
    }
}
