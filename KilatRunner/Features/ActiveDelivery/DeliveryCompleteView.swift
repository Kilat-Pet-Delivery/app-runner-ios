import SwiftUI
import KilatUI

struct DeliveryCompleteView: View {
    @Bindable var viewModel: DeliveryCompleteViewModel
    let fareLabel: String
    let onDone: () -> Void
    let onViewEarnings: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Space.lg) {
            AnimatedCheckmark()

            VStack(spacing: Tokens.Space.xs) {
                Text("Delivery complete")
                    .font(Tokens.FontRole.titleL)
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text(fareLabel)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.primary)
            }

            HStack(spacing: Tokens.Space.xs) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        viewModel.rating = star
                    } label: {
                        Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Tokens.Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            FlowLayout(spacing: Tokens.Space.xs) {
                ForEach(DeliveryCompleteViewModel.availableTags, id: \.self) { tag in
                    QuickReplyChip(title: tag) { viewModel.toggleTag(tag) }
                        .opacity(viewModel.selectedTags.contains(tag) ? 1 : 0.72)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(Tokens.FontRole.caption)
                    .foregroundStyle(Tokens.Color.destructive)
            }

            PrimaryButton(title: "Done", icon: "house.fill", isLoading: viewModel.isSubmitting) {
                Task {
                    await viewModel.complete()
                    if viewModel.didComplete { onDone() }
                }
            }

            SecondaryButton(title: "View earnings", icon: "wallet.pass.fill", action: onViewEarnings)
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: spacing)], spacing: spacing) {
            content
        }
    }
}
