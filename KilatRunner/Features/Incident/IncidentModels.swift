import Foundation

enum IncidentType: String, Encodable, Decodable, Equatable {
    case cancelActive = "cancel_active"
    case problemReport = "problem_report"
    case sos
}

enum IncidentSeverity: String, Encodable, Decodable, Equatable {
    case low
    case medium
    case high
    case critical
}

enum IncidentStatus: String, Decodable, Equatable {
    case open
    case acknowledged
    case resolved
}

struct Incident: Decodable, Equatable {
    let id: String
    let type: IncidentType
    let severity: IncidentSeverity
    let status: IncidentStatus
    let bookingID: String?
    let notes: String?
    let photoURL: String?
    let createdAt: Date?
}

struct CreateIncidentRequest: Encodable, Equatable {
    let type: IncidentType
    let severity: IncidentSeverity
    let bookingID: String?
    let notes: String?
    let photoURL: String?
}

struct IncidentTransitionRequest: Encodable, Equatable {
    let status: IncidentStatusMutation
    let reason: String
}

enum IncidentStatusMutation: String, Encodable, Equatable {
    case resolved
}

enum CancelActiveReason: String, CaseIterable, Identifiable, Equatable {
    case petEmergency = "pet_emergency"
    case customerNotReachable = "customer_not_reachable"
    case vendorClosed = "vendor_closed"
    case vehicleBrokeDown = "vehicle_broke_down"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .petEmergency: return "Pet emergency"
        case .customerNotReachable: return "Customer not reachable"
        case .vendorClosed: return "Vendor closed"
        case .vehicleBrokeDown: return "My vehicle broke down"
        case .other: return "Other"
        }
    }
}

enum ReportProblemIssue: String, CaseIterable, Identifiable, Equatable {
    case petUnwell = "pet_unwell"
    case vendorNotReady = "vendor_not_ready"
    case wrongItem = "wrong_item"
    case traffic
    case locationWrong = "location_wrong"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .petUnwell: return "Pet unwell"
        case .vendorNotReady: return "Vendor not ready"
        case .wrongItem: return "Wrong item"
        case .traffic: return "Traffic"
        case .locationWrong: return "Location wrong"
        case .other: return "Other"
        }
    }
}
