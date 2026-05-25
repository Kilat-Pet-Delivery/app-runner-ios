import Foundation
import Observation

@MainActor
@Observable
final class HotZonesViewModel {
    private(set) var zones: [HotZone] = []
    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private let repository: ZonesRepositoryProtocol

    init(repository: ZonesRepositoryProtocol = ZonesRepository()) {
        self.repository = repository
    }

    var sortedZones: [HotZone] {
        zones.sorted { lhs, rhs in
            if lhs.multiplier == rhs.multiplier {
                return (lhs.distanceKm ?? .greatestFiniteMagnitude) < (rhs.distanceKm ?? .greatestFiniteMagnitude)
            }
            return lhs.multiplier > rhs.multiplier
        }
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            zones = try await repository.fetchActiveZones()
        } catch let error as NetworkError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = NetworkError.unknown(error.localizedDescription).userMessage
        }
    }

    func applySurgeChanged(_ event: ZoneSurgeChangedEvent) {
        guard let index = zones.firstIndex(where: { $0.code == event.zoneCode }) else { return }
        zones[index].multiplier = event.multiplier
    }
}
