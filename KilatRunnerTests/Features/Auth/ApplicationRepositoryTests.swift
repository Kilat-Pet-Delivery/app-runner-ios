import Foundation
import XCTest
@testable import KilatRunner

final class ApplicationRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_applyEndpointShape() async throws {
        let repository = makeRepository()
        let request = RunnerApplicationRequest(
            name: "Aiman Hakim",
            phone: "+60123456789",
            icNumber: "900101141234",
            vehicleType: .motorbike,
            plateNumber: "VKL4521",
            petExperience: ["dogs", "cats"],
            comfortableWithLivePets: true,
            consentAcknowledged: true
        )

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/v1/runners/apply")
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try XCTUnwrap(request.httpBody)
            let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(json?["icNumber"] as? String, "900101141234")
            XCTAssertEqual(json?["vehicleType"] as? String, "motorbike")
            XCTAssertEqual(json?["plateNumber"] as? String, "VKL4521")
            return Self.jsonResponse(
                request: request,
                statusCode: 201,
                body: #"{"data":{"applicationId":"KR-2026-00001"},"success":true}"#
            )
        }

        let response = try await repository.apply(request)
        XCTAssertEqual(response.applicationId, "KR-2026-00001")
    }

    private func makeRepository() -> ApplicationRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiClient = APIClient(
            baseURL: URL(string: "https://example.test/api/v1")!,
            session: session,
            encoder: APIClient.makeCamelCaseEncoder()
        )
        return ApplicationRepository(apiClient: apiClient)
    }

    private static func jsonResponse(request: URLRequest, statusCode: Int, body: String) -> (HTTPURLResponse, Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, body.data(using: .utf8))
    }
}
