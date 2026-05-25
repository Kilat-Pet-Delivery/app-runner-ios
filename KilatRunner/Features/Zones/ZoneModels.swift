import CoreLocation
import Foundation

struct ZoneCoordinate: Decodable, Equatable {
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct HotZone: Decodable, Equatable, Identifiable {
    let id: String
    let code: String
    let name: String
    let centroidLatitude: Double
    let centroidLongitude: Double
    let polygon: [ZoneCoordinate]
    var multiplier: Double
    let distanceKm: Double?

    var centroidCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centroidLatitude, longitude: centroidLongitude)
    }

    var fillOpacity: Double {
        guard multiplier > 1 else { return 0 }
        return min(0.5, max(0, (multiplier - 1) / 0.8 * 0.5))
    }

    var pulses: Bool {
        multiplier >= 1.5
    }
}

struct ZoneSurgeChangedEvent: Equatable {
    let zoneCode: String
    let multiplier: Double
}
