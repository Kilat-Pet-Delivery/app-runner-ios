import Foundation
@testable import KilatRunner

final class MockURLProtocol: URLProtocol {
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data?)

    static var requestHandler: RequestHandler?
    static private(set) var capturedRequests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let materializedRequest = Self.materializingBody(of: request)
        Self.capturedRequests.append(materializedRequest)

        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NetworkError.unknown("Missing mock request handler."))
            return
        }

        do {
            let (response, data) = try handler(materializedRequest)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    private static func materializingBody(of request: URLRequest) -> URLRequest {
        guard request.httpBody == nil, let stream = request.httpBodyStream else {
            return request
        }
        var copy = request
        copy.httpBody = Self.readAll(from: stream)
        return copy
    }

    private static func readAll(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data
    }

    override func stopLoading() {}

    static func reset() {
        requestHandler = nil
        capturedRequests = []
    }
}
