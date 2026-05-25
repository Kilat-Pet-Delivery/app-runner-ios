import XCTest
@testable import KilatRunner

@MainActor
final class HotZonesViewModelTests: XCTestCase {
    func test_load_rendersPolygonsWithMultiplierBasedOpacity() async {
        let repository = ZonesRepositorySpy()
        repository.zones = [
            ZoneFixture.zone(code: "klcc", multiplier: 1.8),
            ZoneFixture.zone(code: "bangsar", multiplier: 1.0)
        ]
        let viewModel = HotZonesViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.zones.count, 2)
        XCTAssertEqual(viewModel.zones[0].fillOpacity, 0.5, accuracy: 0.001)
        XCTAssertEqual(viewModel.zones[1].fillOpacity, 0, accuracy: 0.001)
    }

    func test_surgeChangedEvent_updatesAffectedZone_inPlace() async {
        let repository = ZonesRepositorySpy()
        repository.zones = [
            ZoneFixture.zone(code: "klcc", multiplier: 1.1),
            ZoneFixture.zone(code: "bangsar", multiplier: 1.2)
        ]
        let viewModel = HotZonesViewModel(repository: repository)

        await viewModel.load()
        viewModel.applySurgeChanged(ZoneSurgeChangedEvent(zoneCode: "bangsar", multiplier: 1.7))

        XCTAssertEqual(viewModel.zones.map(\.code), ["klcc", "bangsar"])
        XCTAssertEqual(viewModel.zones[1].multiplier, 1.7)
        XCTAssertTrue(viewModel.zones[1].pulses)
    }
}

private enum ZoneFixture {
    static func zone(code: String, multiplier: Double) -> HotZone {
        HotZone(
            id: code,
            code: code,
            name: code.capitalized,
            centroidLatitude: 3.1390,
            centroidLongitude: 101.6869,
            polygon: [
                ZoneCoordinate(latitude: 3.13, longitude: 101.68),
                ZoneCoordinate(latitude: 3.14, longitude: 101.68),
                ZoneCoordinate(latitude: 3.14, longitude: 101.69),
                ZoneCoordinate(latitude: 3.13, longitude: 101.69)
            ],
            multiplier: multiplier,
            distanceKm: 1.2
        )
    }
}

private final class ZonesRepositorySpy: ZonesRepositoryProtocol {
    var zones: [HotZone] = []

    func fetchActiveZones() async throws -> [HotZone] {
        zones
    }

    func lookupZoneAt(lat: Double, lon: Double) async throws -> HotZone? {
        zones.first
    }
}
