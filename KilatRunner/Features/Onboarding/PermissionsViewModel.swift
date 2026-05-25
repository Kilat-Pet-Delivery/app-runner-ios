import AVFoundation
import CoreLocation
import Foundation
import Observation
import UserNotifications

enum RunnerPermissionStep: String, CaseIterable, Identifiable {
    case location
    case camera
    case notifications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location: return "Location"
        case .camera: return "Camera"
        case .notifications: return "Notifications"
        }
    }

    var message: String {
        switch self {
        case .location: return "Always allow location so active deliveries keep updating."
        case .camera: return "Camera access lets you capture pickup and delivery proof."
        case .notifications: return "Notifications keep urgent jobs, chat, and SOS updates visible."
        }
    }
}

enum RunnerPermissionStatus: Equatable {
    case notDetermined
    case granted
    case denied
}

protocol PermissionsClientProtocol {
    func status(for step: RunnerPermissionStep) async -> RunnerPermissionStatus
    func request(_ step: RunnerPermissionStep) async -> RunnerPermissionStatus
}

final class SystemPermissionsClient: NSObject, PermissionsClientProtocol {
    private let locationManager = CLLocationManager()

    func status(for step: RunnerPermissionStep) async -> RunnerPermissionStatus {
        switch step {
        case .location:
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse: return .granted
            case .notDetermined: return .notDetermined
            default: return .denied
            }
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: return .granted
            case .notDetermined: return .notDetermined
            default: return .denied
            }
        case .notifications:
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: return .granted
            case .notDetermined: return .notDetermined
            default: return .denied
            }
        }
    }

    func request(_ step: RunnerPermissionStep) async -> RunnerPermissionStatus {
        switch step {
        case .location:
            locationManager.requestAlwaysAuthorization()
            return await status(for: step)
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .granted : .denied
        case .notifications:
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            return granted ? .granted : .denied
        }
    }
}

@Observable
final class PermissionsViewModel {
    private(set) var currentStep: RunnerPermissionStep?
    private(set) var statuses: [RunnerPermissionStep: RunnerPermissionStatus] = [:]
    private(set) var isCompleted = false
    private(set) var showsSettingsLink = false

    @ObservationIgnored private let client: PermissionsClientProtocol

    init(client: PermissionsClientProtocol = SystemPermissionsClient()) {
        self.client = client
    }

    @MainActor
    func load() async {
        for step in RunnerPermissionStep.allCases {
            statuses[step] = await client.status(for: step)
        }
        advance()
    }

    @MainActor
    func requestCurrent() async {
        guard let currentStep else { return }
        statuses[currentStep] = await client.request(currentStep)
        advance()
    }

    @MainActor
    func skipCurrent() {
        advance(fromCurrent: true)
    }

    @MainActor
    private func advance(fromCurrent: Bool = false) {
        if fromCurrent, let currentStep {
            statuses[currentStep] = .granted
        }

        currentStep = RunnerPermissionStep.allCases.first { statuses[$0] != .granted }
        showsSettingsLink = currentStep.map { statuses[$0] == .denied } ?? false
        isCompleted = currentStep == nil
    }
}
