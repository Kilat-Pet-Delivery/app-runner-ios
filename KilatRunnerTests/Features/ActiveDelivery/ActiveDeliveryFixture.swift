import Foundation
@testable import KilatRunner

enum ActiveDeliveryFixture {
    static func makeBooking(status: String = "accepted") -> Booking {
        let json = """
        {
          "id": "10000000-0000-4000-8000-000000000001",
          "booking_number": "BK-AB12CD",
          "owner_id": "20000000-0000-4000-8000-000000000001",
          "runner_id": "22222222-2222-4222-8222-222222222222",
          "status": "\(status)",
          "pet_spec": {
            "pet_type": "cat",
            "breed": "Persian",
            "name": "Milo",
            "weight_kg": 4.5,
            "special_needs": "",
            "photo_url": ""
          },
          "pickup_address": {
            "line1": "123 Jalan Ampang",
            "line2": "",
            "city": "Kuala Lumpur",
            "state": "WP",
            "postal_code": "50450",
            "country": "MY",
            "latitude": 3.1626,
            "longitude": 101.7185
          },
          "dropoff_address": {
            "line1": "1 Jalan SS2/24",
            "line2": "",
            "city": "Petaling Jaya",
            "state": "Selangor",
            "postal_code": "47300",
            "country": "MY",
            "latitude": 3.1170,
            "longitude": 101.6190
          },
          "route_spec": {
            "pickup_lat": 3.1626,
            "pickup_lng": 101.7185,
            "dropoff_lat": 3.1170,
            "dropoff_lng": 101.6190,
            "distance_km": 12.4,
            "estimated_duration_min": 28,
            "polyline": ""
          },
          "estimated_price_cents": 2500,
          "currency": "MYR",
          "version": 1,
          "created_at": "2026-05-16T10:00:00Z",
          "updated_at": "2026-05-16T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(Booking.self, from: Data(json.utf8))
    }
}
