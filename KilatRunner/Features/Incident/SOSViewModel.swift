import Foundation
import Observation

protocol CurrentDateProviding {
    func now() -> Date
}

struct SystemDateProvider: CurrentDateProviding {
    func now() -> Date { Date() }
}

@MainActor
@Observable
final class SOSViewModel {
    var notes = ""
    private(set) var incident: Incident?
    private(set) var isFiring = false
    private(set) var isCancelling = false
    private(set) var didResolve = false
    private(set) var isLocationStreaming = false
    private(set) var cooldownEndsAt: Date?
    private(set) var errorMessage: String?

    @ObservationIgnored private let bookingID: String
    @ObservationIgnored private let repository: IncidentRepositoryProtocol
    @ObservationIgnored private let dateProvider: CurrentDateProviding
    @ObservationIgnored private let cooldownSeconds: TimeInterval

    var hasActiveIncident: Bool {
        incident != nil && !didResolve
    }

    var canCancelDuringCooldown: Bool {
        guard hasActiveIncident, let cooldownEndsAt else { return false }
        return dateProvider.now() < cooldownEndsAt
    }

    init(
        bookingID: String,
        repository: IncidentRepositoryProtocol = IncidentRepository(),
        dateProvider: CurrentDateProviding = SystemDateProvider(),
        cooldownSeconds: TimeInterval = 5
    ) {
        self.bookingID = bookingID
        self.repository = repository
        self.dateProvider = dateProvider
        self.cooldownSeconds = cooldownSeconds
    }

    func fireAfterLongPress() async {
        guard incident == nil, !isFiring else { return }
        errorMessage = nil
        isFiring = true
        defer { isFiring = false }

        do {
            incident = try await repository.createIncident(
                type: .sos,
                severity: .critical,
                bookingID: bookingID,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                photoURL: nil
            )
            isLocationStreaming = true
            cooldownEndsAt = dateProvider.now().addingTimeInterval(cooldownSeconds)
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func cancelFalseAlarm() async {
        guard let incident, canCancelDuringCooldown, !isCancelling else { return }
        errorMessage = nil
        isCancelling = true
        defer { isCancelling = false }

        do {
            self.incident = try await repository.resolveIncident(id: incident.id, reason: "false_alarm")
            didResolve = true
            isLocationStreaming = false
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }
}
