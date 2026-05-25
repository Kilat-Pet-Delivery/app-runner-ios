import Foundation
import XCTest
@testable import KilatRunner

final class IncidentRepositoryTests: XCTestCase {
    private var tokenStore: IncidentRepoInMemoryTokenStore!
    private var repository: IncidentRepository!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        tokenStore = IncidentRepoInMemoryTokenStore()
        try? tokenStore.saveAccessToken("access-token")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session
        )
        repository = IncidentRepository(
            authInterceptor: AuthInterceptor(apiClient: apiClient, tokenStore: tokenStore)
        )
    }

    override func tearDown() {
        repository = nil
        tokenStore = nil
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_create_postsCorrectBody() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/incidents")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")

            let body = try XCTUnwrap(request.httpBody)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(json["type"] as? String, "problem_report")
            XCTAssertEqual(json["severity"] as? String, "medium")
            XCTAssertEqual(json["booking_id"] as? String, "booking-4")
            XCTAssertEqual(json["notes"] as? String, "Wrong item")
            XCTAssertEqual(json["photo_url"] as? String, "incident/photo.jpg")

            return Self.jsonResponse(request: request, body: Self.incidentEnvelope)
        }

        let incident = try await repository.createIncident(
            type: .problemReport,
            severity: .medium,
            bookingID: "booking-4",
            notes: "Wrong item",
            photoURL: "incident/photo.jpg"
        )

        XCTAssertEqual(incident.id, "incident-1")
        XCTAssertEqual(incident.status, .open)
    }

    private static func jsonResponse(request: URLRequest, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }

    private static let incidentEnvelope = #"""
    {"data":{
      "id":"incident-1",
      "type":"problem_report",
      "severity":"medium",
      "status":"open",
      "booking_id":"booking-4",
      "notes":"Wrong item",
      "photo_url":"incident/photo.jpg",
      "created_at":"2026-05-25T08:00:00Z"
    },"success":true}
    """#
}

final class IncidentRepositorySpy: IncidentRepositoryProtocol {
    struct CreateCall: Equatable {
        let type: IncidentType
        let severity: IncidentSeverity
        let bookingID: String?
        let notes: String?
        let photoURL: String?
    }

    struct ResolveCall: Equatable {
        let id: String
        let reason: String
    }

    private(set) var createCalls: [CreateCall] = []
    private(set) var getCalls: [String] = []
    private(set) var resolveCalls: [ResolveCall] = []

    func createIncident(
        type: IncidentType,
        severity: IncidentSeverity,
        bookingID: String?,
        notes: String?,
        photoURL: String?
    ) async throws -> Incident {
        createCalls.append(
            CreateCall(type: type, severity: severity, bookingID: bookingID, notes: notes, photoURL: photoURL)
        )
        return Incident(
            id: "incident-1",
            type: type,
            severity: severity,
            status: .open,
            bookingID: bookingID,
            notes: notes,
            photoURL: photoURL,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    func getIncident(id: String) async throws -> Incident {
        getCalls.append(id)
        return Incident(
            id: id,
            type: .problemReport,
            severity: .medium,
            status: .open,
            bookingID: nil,
            notes: nil,
            photoURL: nil,
            createdAt: nil
        )
    }

    func resolveIncident(id: String, reason: String) async throws -> Incident {
        resolveCalls.append(ResolveCall(id: id, reason: reason))
        return Incident(
            id: id,
            type: .sos,
            severity: .critical,
            status: .resolved,
            bookingID: nil,
            notes: reason,
            photoURL: nil,
            createdAt: nil
        )
    }
}

private final class IncidentRepoInMemoryTokenStore: TokenStore {
    private var storedAccessToken: String?
    private var storedRefreshToken: String?

    func saveAccessToken(_ token: String) throws {
        storedAccessToken = token
    }

    func accessToken() -> String? {
        storedAccessToken
    }

    func saveRefreshToken(_ token: String) throws {
        storedRefreshToken = token
    }

    func refreshToken() -> String? {
        storedRefreshToken
    }

    func clear() {
        storedAccessToken = nil
        storedRefreshToken = nil
    }
}
