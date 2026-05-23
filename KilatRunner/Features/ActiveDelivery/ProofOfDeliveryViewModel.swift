import Foundation
import Observation

@MainActor
@Observable
final class ProofOfDeliveryViewModel {
    var recipient: ProofRecipient = .customer
    var notes = ""
    var photoData: Data?
    var signatureData: Data?
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let photoUploader: PhotoUploading
    @ObservationIgnored private let signatureUploader: PhotoUploading
    @ObservationIgnored private let submitHandler: (ProofOfDeliveryRequest) async throws -> Booking

    init(
        photoUploader: PhotoUploading = PhotoUploader(),
        signatureUploader: PhotoUploading = PhotoUploader(),
        submitHandler: @escaping (ProofOfDeliveryRequest) async throws -> Booking
    ) {
        self.photoUploader = photoUploader
        self.signatureUploader = signatureUploader
        self.submitHandler = submitHandler
    }

    convenience init(bookingID: String, repository: BookingRepositoryProtocol = BookingRepository()) {
        self.init { proof in
            try await repository.submitProofOfDelivery(id: bookingID, proof: proof)
        }
    }

    func submit() async {
        guard !isSubmitting else { return }
        guard let photoData else {
            errorMessage = "Add a delivery photo before submitting."
            return
        }
        guard !recipient.requiresSignature || signatureData != nil else {
            errorMessage = "Customer handoff requires a signature."
            return
        }

        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let photoKey = try await photoUploader.upload(data: photoData, fileName: "proof-photo.jpg")
            let signatureKey: String?
            if let signatureData {
                signatureKey = try await signatureUploader.upload(data: signatureData, fileName: "signature.png")
            } else {
                signatureKey = nil
            }
            let proof = ProofOfDeliveryRequest(
                photoStorageKey: photoKey,
                signatureStorageKey: signatureKey,
                recipient: recipient,
                notes: notes
            )
            _ = try await submitHandler(proof)
            didSubmit = true
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
