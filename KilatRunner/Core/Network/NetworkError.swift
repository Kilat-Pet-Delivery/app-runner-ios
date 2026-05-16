enum NetworkError: Error, Equatable {
    case offline
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingFailed(String)
    case encodingFailed(String)
    case unknown(String)

    var userMessage: String {
        switch self {
        case .offline:
            return "You appear to be offline. Check your connection and try again."
        case .invalidURL:
            return "The app could not build a valid request."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You do not have permission to perform this action."
        case .notFound:
            return "The requested item could not be found."
        case .serverError:
            return "The server is having trouble. Please try again shortly."
        case let .decodingFailed(message):
            return "The app could not read the server response. \(message)"
        case let .encodingFailed(message):
            return "The app could not send the request. \(message)"
        case let .unknown(message):
            return message.isEmpty ? "Something went wrong. Please try again." : message
        }
    }
}
