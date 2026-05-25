import Foundation
import Observation

@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    private(set) var pendingIntent: PushIntent?

    init(initialIntent: PushIntent? = nil) {
        self.pendingIntent = initialIntent
    }

    func publish(_ intent: PushIntent) {
        pendingIntent = intent
    }

    func consume() -> PushIntent? {
        let intent = pendingIntent
        pendingIntent = nil
        return intent
    }
}
