import Foundation
import Observation

@Observable
final class VetPickupDetailViewModel {
    let jobDetailViewModel: JobDetailViewModel

    init(jobDetailViewModel: JobDetailViewModel) {
        self.jobDetailViewModel = jobDetailViewModel
    }

    var booking: Booking { jobDetailViewModel.booking }
    var routesToVetPickupView: Bool { booking.isVetBooking }
    var condition: String { booking.vetSpec?.condition ?? "Vet pickup" }
    var medications: [VetMedication] { booking.vetSpec?.medications ?? [] }
    var handlingInstructions: String { booking.vetSpec?.handlingInstructions ?? booking.notes ?? "" }
    var vetName: String { booking.vetSpec?.vetName ?? booking.pickupAddress.line1 }
    var vetPhone: String { booking.vetSpec?.vetPhone ?? "" }
    var requiresColdChain: Bool { booking.vetSpec?.requiresColdChain == true || medications.contains { $0.requiresColdChain } }
}
