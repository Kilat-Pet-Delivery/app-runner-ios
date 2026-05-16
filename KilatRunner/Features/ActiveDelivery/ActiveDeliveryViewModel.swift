import CoreLocation
import Foundation
import Observation

enum DeliveryPhase: Equatable {
    case enroute
    case pickedUp
    case delivered
}

@Observable
final class ActiveDeliveryViewModel {
    private(set) var booking: Booking
    var currentLocation: CLLocationCoordinate2D?
    private(set) var deliveryPhase: DeliveryPhase = .enroute
    var errorMessage: String?

    var pickupCoordinate: CLLocationCoordinate2D { booking.pickupCoordinate }
    var dropoffCoordinate: CLLocationCoordinate2D { booking.dropoffCoordinate }

    init(booking: Booking) {
        self.booking = booking
    }
}
