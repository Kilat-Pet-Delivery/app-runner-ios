import Foundation

enum APIEndpoint: Equatable {
    case login
    case refresh
    case logout
    case profile
    case runnerMe
    case runnerOnline
    case runnerOffline
    case runnerLocation
    case availableJobs(page: Int = 1, limit: Int = 20)
    case bookingDetail(id: String)
    case acceptBooking(id: String)
    case markPickup(id: String)
    case markDelivered(id: String)
    case earnings(page: Int = 1, limit: Int = 20)

    var method: HTTPMethod {
        switch self {
        case .login, .refresh, .logout, .runnerOnline, .runnerOffline, .runnerLocation,
                .acceptBooking, .markPickup, .markDelivered:
            return .post
        case .profile, .runnerMe, .availableJobs, .bookingDetail, .earnings:
            return .get
        }
    }

    var path: String {
        switch self {
        case .login:
            return "auth/login"
        case .refresh:
            return "auth/refresh"
        case .logout:
            return "auth/logout"
        case .profile:
            return "auth/profile"
        case .runnerMe:
            return "runners/me"
        case .runnerOnline:
            return "runners/me/online"
        case .runnerOffline:
            return "runners/me/offline"
        case .runnerLocation:
            return "runners/me/location"
        case .availableJobs:
            return "bookings"
        case let .bookingDetail(id):
            return "bookings/\(id)"
        case let .acceptBooking(id):
            return "bookings/\(id)/accept"
        case let .markPickup(id):
            return "bookings/\(id)/pickup"
        case let .markDelivered(id):
            return "bookings/\(id)/deliver"
        case .earnings:
            // The backend currently derives runner earnings from completed bookings.
            return "bookings"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .availableJobs(page, limit), let .earnings(page, limit):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        default:
            return []
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .refresh:
            return false
        default:
            return true
        }
    }
}
