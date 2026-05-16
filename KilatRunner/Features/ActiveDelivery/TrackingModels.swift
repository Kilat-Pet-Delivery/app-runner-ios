import Foundation

struct TrackingUpdate: Decodable, Equatable {
    let bookingId: String
    let runnerId: String
    let latitude: Double
    let longitude: Double
    let speedKmh: Double
    let headingDegrees: Double
    let timestamp: Date
}
