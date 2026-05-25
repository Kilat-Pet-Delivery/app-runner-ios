import SwiftUI
import KilatUI

protocol CoachMarksStorage {
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

extension UserDefaults: CoachMarksStorage {}

@Observable
final class CoachMarksState {
    static let dashboardKey = "coachmarks.dashboard.v1.dismissed"

    private let storage: CoachMarksStorage
    private let key: String
    private(set) var isPresented: Bool

    init(storage: CoachMarksStorage = UserDefaults.standard, key: String = CoachMarksState.dashboardKey) {
        self.storage = storage
        self.key = key
        isPresented = !storage.bool(forKey: key)
    }

    func dismiss() {
        storage.set(true, forKey: key)
        isPresented = false
    }
}

struct CoachMarksOverlay: View {
    @Bindable var state: CoachMarksState

    var body: some View {
        if state.isPresented {
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: Tokens.Space.md) {
                    Label("You're ready", systemImage: "sparkles")
                        .font(Tokens.FontRole.titleM)
                        .foregroundStyle(Tokens.Color.textPrimary)
                    Text("Use the online toggle when you are ready for jobs. The bell keeps every job, chat, and safety alert close.")
                        .font(Tokens.FontRole.body)
                        .foregroundStyle(Tokens.Color.textSecondary)
                    PrimaryButton(title: "Got it") {
                        state.dismiss()
                    }
                }
                .padding(Tokens.Space.lg)
                .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
                .padding(Tokens.Space.lg)
            }
            .transition(.opacity)
        }
    }
}
