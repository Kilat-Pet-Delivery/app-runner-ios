import SwiftUI
import KilatUI

struct PermissionsView: View {
    @Bindable private var viewModel: PermissionsViewModel
    let onComplete: () -> Void

    init(viewModel: PermissionsViewModel, onComplete: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: Tokens.Space.lg) {
            Spacer()
            if let step = viewModel.currentStep {
                Image(systemName: icon(for: step))
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Tokens.Color.primary)
                Text(step.title)
                    .font(Tokens.FontRole.displayL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(step.message)
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textSecondary)
                    .multilineTextAlignment(.center)
                if viewModel.showsSettingsLink {
                    Text("Enable this in Settings, then come back.")
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.destructive)
                }
                PrimaryButton(title: viewModel.showsSettingsLink ? "Continue" : "Allow") {
                    Task { await viewModel.requestCurrent() }
                }
                Button("Skip") {
                    viewModel.skipCurrent()
                    if viewModel.isCompleted { onComplete() }
                }
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.textSecondary)
            } else {
                ProgressView()
                    .tint(Tokens.Color.primary)
            }
            Spacer()
        }
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.background.ignoresSafeArea())
        .task {
            await viewModel.load()
            if viewModel.isCompleted {
                onComplete()
            }
        }
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed { onComplete() }
        }
    }

    private func icon(for step: RunnerPermissionStep) -> String {
        switch step {
        case .location: return "location.fill"
        case .camera: return "camera.fill"
        case .notifications: return "bell.fill"
        }
    }
}
