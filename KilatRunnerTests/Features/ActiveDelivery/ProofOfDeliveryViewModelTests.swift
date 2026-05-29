import Foundation
import XCTest
@testable import KilatRunner

@MainActor
final class ProofOfDeliveryViewModelTests: XCTestCase {
    func test_submit_requiresSignature_whenRecipientIsCustomer() async {
        let viewModel = ProofOfDeliveryViewModel(
            photoUploader: FakePhotoUploader(),
            signatureUploader: FakePhotoUploader(),
            submitHandler: { _ in Self.makeBooking() }
        )
        viewModel.recipient = .customer
        viewModel.photoData = Data([1, 2, 3])

        await viewModel.submit()

        XCTAssertEqual(viewModel.errorMessage, "Customer handoff requires a signature.")
    }

    func test_submit_doesNotRequireSignature_whenRecipientIsLeftAtDoor() async {
        var submittedProof: ProofOfDeliveryRequest?
        let viewModel = ProofOfDeliveryViewModel(
            photoUploader: FakePhotoUploader(returning: "photo-key"),
            signatureUploader: FakePhotoUploader(returning: "signature-key"),
            submitHandler: { proof in
                submittedProof = proof
                return Self.makeBooking()
            }
        )
        viewModel.recipient = .leftAtDoor
        viewModel.photoData = Data([1, 2, 3])

        await viewModel.submit()

        XCTAssertTrue(viewModel.didSubmit)
        XCTAssertEqual(submittedProof?.photoStorageKey, "photo-key")
        XCTAssertNil(submittedProof?.signatureStorageKey)
        XCTAssertEqual(submittedProof?.recipient, .leftAtDoor)
    }

    func test_submit_uploadsPhotoFirst_thenSubmitsProof() async {
        let recorder = UploadRecorder()
        var submittedProof: ProofOfDeliveryRequest?
        let viewModel = ProofOfDeliveryViewModel(
            photoUploader: FakePhotoUploader(returning: "photo-key", recorder: recorder, label: "photo"),
            signatureUploader: FakePhotoUploader(returning: "signature-key", recorder: recorder, label: "signature"),
            submitHandler: { proof in
                await recorder.append("submit")
                submittedProof = proof
                return Self.makeBooking()
            }
        )
        viewModel.recipient = .customer
        viewModel.photoData = Data([1])
        viewModel.signatureData = Data([2])

        await viewModel.submit()

        let events = await recorder.events
        XCTAssertEqual(events, ["photo", "signature", "submit"])
        XCTAssertEqual(submittedProof?.photoStorageKey, "photo-key")
        XCTAssertEqual(submittedProof?.signatureStorageKey, "signature-key")
    }

    private static func makeBooking() -> Booking {
        ActiveDeliveryFixture.makeBooking()
    }
}

private actor UploadRecorder {
    private(set) var events: [String] = []

    func append(_ event: String) {
        events.append(event)
    }
}

private struct FakePhotoUploader: PhotoUploading {
    let returning: String
    let recorder: UploadRecorder?
    let label: String

    init(returning: String = "uploaded-key", recorder: UploadRecorder? = nil, label: String = "upload") {
        self.returning = returning
        self.recorder = recorder
        self.label = label
    }

    func upload(data: Data, fileName: String) async throws -> String {
        await recorder?.append(label)
        return returning
    }
}
