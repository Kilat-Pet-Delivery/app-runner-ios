import Foundation

struct EmptyRequest: Encodable {}

struct EmptyResponse: Decodable, Equatable {
    init() {}
    init(from decoder: Decoder) throws {}
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL = AppEnvironment.apiBaseURL,
        session: URLSession = .shared,
        encoder: JSONEncoder = APIClient.makeEncoder(),
        decoder: JSONDecoder = APIClient.makeDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func request<Response: Decodable>(
        _ endpoint: APIEndpoint,
        token: String? = nil
    ) async throws -> Response {
        try await request(endpoint, body: Optional<EmptyRequest>.none, token: token)
    }

    func uploadMultipart<Response: Decodable>(
        _ endpoint: APIEndpoint,
        fields: [String: String],
        fileField: String,
        fileName: String,
        fileMIMEType: String,
        fileData: Data,
        token: String? = nil
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = makeMultipartBody(
            boundary: boundary,
            fields: fields,
            fileField: fileField,
            fileName: fileName,
            fileMIMEType: fileMIMEType,
            fileData: fileData
        )
        var request = try makeRequest(endpoint, body: Optional<EmptyRequest>.none, token: token)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validate(httpResponse)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    private func makeMultipartBody(
        boundary: String,
        fields: [String: String],
        fileField: String,
        fileName: String,
        fileMIMEType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        for (name, value) in fields {
            body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            body.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }
        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fileField)\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: \(fileMIMEType)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(fileData)
        body.append("\(lineBreak)--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return body
    }

    func request<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body?,
        token: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(endpoint, body: body, token: token)
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw NetworkError.offline
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        try validate(httpResponse)

        if data.isEmpty, Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    private func makeRequest<Body: Encodable>(
        _ endpoint: APIEndpoint,
        body: Body?,
        token: String?
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appending(path: endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.requiresAuth, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            do {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.encodingFailed(error.localizedDescription)
            }
        }

        return request
    }

    private func validate(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200..<300:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500..<600:
            throw NetworkError.serverError(response.statusCode)
        default:
            throw NetworkError.invalidResponse
        }
    }

    static func makeCamelCaseEncoder() -> JSONEncoder {
        makeEncoder(keyEncodingStrategy: .useDefaultKeys)
    }

    private static func makeEncoder(keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
