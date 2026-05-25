import SwiftUI
import KilatUI

struct SOSView: View {
    @Bindable var viewModel: SOSViewModel
    let onClose: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Tokens.Color.destructive.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Tokens.Space.xl) {
                Spacer(minLength: Tokens.Space.xl)

                VStack(spacing: Tokens.Space.sm) {
                    Text("SOS")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(.white)
                    Text(statusText)
                        .font(Tokens.FontRole.bodyBold)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                }

                PulsingButton(icon: "exclamationmark.triangle.fill", tint: Tokens.Color.destructive) {}
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 1)
                        .onEnded { _ in Task { await viewModel.fireAfterLongPress() } }
                )
                .accessibilityLabel("Hold SOS")

                statusBanner

                VStack(spacing: Tokens.Space.sm) {
                    TextField("Emergency notes", text: $viewModel.notes, axis: .vertical)
                        .font(Tokens.FontRole.body)
                        .padding(Tokens.Space.sm)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(.white)
                    }
                }

                quickActions

                if viewModel.canCancelDuringCooldown {
                    SecondaryButton(
                        title: "Cancel false alarm",
                        icon: "xmark.circle.fill",
                        isEnabled: !viewModel.isCancelling,
                        action: { Task { await viewModel.cancelFalseAlarm() } }
                    )
                }

                Button("Close", action: onClose)
                    .font(Tokens.FontRole.button)
                    .foregroundStyle(.white.opacity(0.86))

                Spacer(minLength: Tokens.Space.lg)
            }
            .padding(Tokens.Space.lg)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusText: String {
        if viewModel.didResolve {
            return "False alarm resolved"
        }
        if viewModel.hasActiveIncident {
            return "Location shared · Help arriving"
        }
        return "Hold for 1 second to alert support"
    }

    private var statusBanner: some View {
        HStack(spacing: Tokens.Space.sm) {
            Image(systemName: viewModel.hasActiveIncident ? "location.fill" : "hand.tap.fill")
                .font(.system(size: 18, weight: .bold))
            Text(viewModel.hasActiveIncident ? "Location shared · Help arriving" : "Press and hold to send SOS")
                .font(Tokens.FontRole.bodyBold)
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(Tokens.Space.md)
        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Space.sm) {
            quickAction(title: "Emergency contact", icon: "person.crop.circle.badge.exclamationmark", url: "tel://")
            quickAction(title: "Call vet", icon: "cross.case.fill", url: "tel://")
            quickAction(title: "Call partner", icon: "phone.connection.fill", url: "tel://")
            quickAction(title: "Call 999", icon: "phone.fill", url: "tel://999")
        }
    }

    private func quickAction(title: String, icon: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: Tokens.Space.xs) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(Tokens.FontRole.caption)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 82)
            .padding(Tokens.Space.xs)
            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
        }
    }
}
