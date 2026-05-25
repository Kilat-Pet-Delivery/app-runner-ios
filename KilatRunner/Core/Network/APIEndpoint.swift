import Foundation

enum APIEndpoint: Equatable {
    case login
    case refresh
    case logout
    case forgotPassword
    case resetPassword
    case profile
    case runnerMe
    case runnerApply
    case runnerOnline
    case runnerOffline
    case runnerLocation
    case availableJobs(page: Int = 1, limit: Int = 20)
    case jobAlerts
    case bookingHistory(filter: String, cursor: String?, limit: Int = 20)
    case scheduledBookings
    case bookingDetail(id: String)
    case bookingPet(id: String)
    case acceptBooking(id: String)
    case declineBooking(id: String)
    case arriveAtPickup(id: String)
    case markPickup(id: String)
    case arriveAtDropoff(id: String)
    case proofOfDelivery(id: String)
    case completeDelivery(id: String)
    case rateCustomer(id: String)
    case markDelivered(id: String)
    case trackingHistory(bookingId: String)
    case earnings(page: Int = 1, limit: Int = 20)
    case cashOut
    case bankAccounts
    case addBankAccount
    case setDefaultBankAccount(id: String)
    case deleteBankAccount(id: String)
    case notifications(cursor: String?, limit: Int = 20)
    case threads
    case threadMessages(threadId: String, cursor: String?, limit: Int = 50)
    case sendThreadMessage(threadId: String)
    case sendThreadAttachment(threadId: String)
    case markThreadRead(threadId: String)
    case quickReplies
    case me
    case updateMe
    case mePhoto
    case meSettings
    case updateMeSettings
    case tier
    case incidents
    case incidentDetail(id: String)
    case incidentTransition(id: String)
    case quests
    case redeemQuest(id: String)
    case zones
    case zoneAt(lat: Double, lon: Double)
    case reviews
    case referrals
    case referralCode
    case redeemReferral(id: String)
    case preTripChecklist(id: String)

    var method: HTTPMethod {
        switch self {
        case .login, .refresh, .logout, .forgotPassword, .resetPassword, .runnerApply,
                .runnerOnline, .runnerOffline, .runnerLocation, .jobAlerts, .acceptBooking,
                .declineBooking, .arriveAtPickup, .markPickup, .arriveAtDropoff,
                .proofOfDelivery, .completeDelivery, .rateCustomer, .markDelivered, .cashOut,
                .addBankAccount, .setDefaultBankAccount, .preTripChecklist,
                .sendThreadMessage, .sendThreadAttachment, .markThreadRead, .mePhoto,
                .incidents, .incidentTransition, .redeemQuest, .referralCode, .redeemReferral:
            return .post
        case .deleteBankAccount:
            return .delete
        case .updateMe, .updateMeSettings:
            return .put
        case .profile, .runnerMe, .availableJobs, .bookingHistory, .scheduledBookings, .bookingDetail, .bookingPet, .trackingHistory,
                .earnings, .bankAccounts, .notifications, .threads, .threadMessages, .quickReplies, .me, .meSettings, .tier,
                .incidentDetail, .quests, .zones, .zoneAt, .reviews, .referrals:
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
        case .forgotPassword:
            return "auth/forgot-password"
        case .resetPassword:
            return "auth/reset-password"
        case .profile:
            return "auth/profile"
        case .runnerMe:
            return "runners/me"
        case .runnerApply:
            return "runners/apply"
        case .runnerOnline:
            return "runners/me/online"
        case .runnerOffline:
            return "runners/me/offline"
        case .runnerLocation:
            return "runners/me/location"
        case .availableJobs:
            return "bookings"
        case .jobAlerts:
            return "me/job-alerts"
        case .bookingHistory:
            return "bookings/history"
        case .scheduledBookings:
            return "bookings/scheduled"
        case let .bookingDetail(id):
            return "bookings/\(id)"
        case let .bookingPet(id):
            return "bookings/\(id)/pet"
        case let .acceptBooking(id):
            return "bookings/\(id)/accept"
        case let .declineBooking(id):
            return "bookings/\(id)/decline"
        case let .arriveAtPickup(id):
            return "bookings/\(id)/arrive-pickup"
        case let .markPickup(id):
            return "bookings/\(id)/pickup"
        case let .arriveAtDropoff(id):
            return "bookings/\(id)/arrive-dropoff"
        case let .proofOfDelivery(id):
            return "bookings/\(id)/proof-of-delivery"
        case let .completeDelivery(id):
            return "bookings/\(id)/complete"
        case let .rateCustomer(id):
            return "bookings/\(id)/rate-customer"
        case let .markDelivered(id):
            return "bookings/\(id)/deliver"
        case let .trackingHistory(bookingId):
            return "bookings/\(bookingId)/tracking"
        case .earnings:
            // The backend currently derives runner earnings from completed bookings.
            return "bookings"
        case .cashOut:
            return "payouts/cash-out"
        case .bankAccounts, .addBankAccount:
            return "me/bank-accounts"
        case let .setDefaultBankAccount(id):
            return "me/bank-accounts/\(id)/set-default"
        case let .deleteBankAccount(id):
            return "me/bank-accounts/\(id)"
        case .notifications:
            return "notifications"
        case .threads:
            return "threads"
        case let .threadMessages(threadId, _, _):
            return "threads/\(threadId)/messages"
        case let .sendThreadMessage(threadId):
            return "threads/\(threadId)/messages"
        case let .sendThreadAttachment(threadId):
            return "threads/\(threadId)/attachments"
        case let .markThreadRead(threadId):
            return "threads/\(threadId)/read"
        case .quickReplies:
            return "quick-replies"
        case .me:
            return "me"
        case .updateMe:
            return "me"
        case .mePhoto:
            return "me/photo"
        case .meSettings:
            return "me/settings"
        case .updateMeSettings:
            return "me/settings"
        case .tier:
            return "tier"
        case .incidents:
            return "incidents"
        case let .incidentDetail(id):
            return "incidents/\(id)"
        case let .incidentTransition(id):
            return "incidents/\(id)/transition"
        case .quests:
            return "quests"
        case let .redeemQuest(id):
            return "quests/\(id)/redeem"
        case .zones:
            return "zones"
        case .zoneAt:
            return "zones/at"
        case .reviews:
            return "me/reviews"
        case .referrals:
            return "referrals"
        case .referralCode:
            return "referrals/code"
        case let .redeemReferral(id):
            return "referrals/\(id)/redeem"
        case let .preTripChecklist(id):
            return "bookings/\(id)/pretrip-checklist"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .availableJobs(page, limit):
            return [
                URLQueryItem(name: "status", value: "requested"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case let .bookingHistory(filter, cursor, limit):
            var items = [
                URLQueryItem(name: "filter", value: filter),
                URLQueryItem(name: "limit", value: String(limit))
            ]
            if let cursor, !cursor.isEmpty {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            return items
        case let .earnings(page, limit):
            return [
                URLQueryItem(name: "status", value: "completed"),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        case let .notifications(cursor, limit):
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor, !cursor.isEmpty {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            return items
        case let .threadMessages(_, cursor, limit):
            var items = [URLQueryItem(name: "limit", value: String(limit))]
            if let cursor, !cursor.isEmpty {
                items.append(URLQueryItem(name: "cursor", value: cursor))
            }
            return items
        case let .zoneAt(lat, lon):
            return [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lon", value: String(lon))
            ]
        default:
            return []
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .login, .refresh, .forgotPassword, .resetPassword, .runnerApply:
            return false
        default:
            return true
        }
    }
}
