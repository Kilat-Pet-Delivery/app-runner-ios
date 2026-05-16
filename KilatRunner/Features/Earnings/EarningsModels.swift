import Foundation

struct Earning: Decodable, Equatable, Identifiable {
    let id: String
    let bookingId: String
    let amountCents: Int64
    let currency: String
    let status: String
    let completedAt: Date
}

struct EarningsPage: Decodable, Equatable {
    let items: [Earning]
    let page: Int
    let limit: Int
    let total: Int
}

struct PaginatedAPIResponseEnvelope<Payload: Decodable>: Decodable {
    let data: Payload
    let pagination: Pagination
    let success: Bool?
}

struct Pagination: Decodable, Equatable {
    let limit: Int
    let page: Int
    let total: Int
    let totalPages: Int?
}

extension Earning {
    init(booking: Booking) {
        let completedDate = booking.deliveredAt ?? booking.updatedAt
        self.init(
            id: booking.id,
            bookingId: booking.id,
            amountCents: booking.finalPriceCents ?? booking.estimatedPriceCents,
            currency: booking.currency,
            status: booking.status.rawValue,
            completedAt: completedDate
        )
    }
}
