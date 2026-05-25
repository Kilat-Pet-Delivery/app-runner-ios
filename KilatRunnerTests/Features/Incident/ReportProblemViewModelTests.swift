import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class ReportProblemViewModelTests: XCTestCase {
    func test_submit_attachesOptionalPhotoURL() async {
        let repository = IncidentRepositorySpy()
        let uploader = IncidentPhotoUploaderSpy(result: "incident/photo-1.jpg")
        let viewModel = ReportProblemViewModel(
            bookingID: "booking-2",
            repository: repository,
            photoUploader: uploader
        )
        viewModel.selectedIssue = .wrongItem
        viewModel.photoData = Data([0x01, 0x02, 0x03])

        await viewModel.submit()

        XCTAssertTrue(viewModel.didSubmit)
        XCTAssertEqual(uploader.uploadCalls.count, 1)
        XCTAssertEqual(repository.createCalls[0].type, .problemReport)
        XCTAssertEqual(repository.createCalls[0].photoURL, "incident/photo-1.jpg")
    }
}

private final class IncidentPhotoUploaderSpy: PhotoUploading {
    struct UploadCall: Equatable {
        let data: Data
        let fileName: String
    }

    private(set) var uploadCalls: [UploadCall] = []
    private let result: String

    init(result: String) {
        self.result = result
    }

    func upload(data: Data, fileName: String) async throws -> String {
        uploadCalls.append(UploadCall(data: data, fileName: fileName))
        return result
    }
}
