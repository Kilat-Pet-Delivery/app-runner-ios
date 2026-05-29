import Foundation

protocol PhotoUploading {
    func upload(data: Data, fileName: String) async throws -> String
}

final class PhotoUploader: PhotoUploading {
    func upload(data: Data, fileName: String) async throws -> String {
        guard !data.isEmpty else {
            throw NetworkError.invalidResponse
        }
        return "pod/\(UUID().uuidString)-\(fileName)"
    }
}
