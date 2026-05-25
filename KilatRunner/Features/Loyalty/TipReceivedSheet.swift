import SwiftUI
import KilatUI

struct TipReceivedSheet: View {
    @Bindable var viewModel: TipReceivedViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Space.lg) {
            AnimatedCheckmark(color: .yellow)
                .frame(width: 88, height: 88)

            VStack(spacing: Tokens.Space.xs) {
                Text(viewModel.amountLabel)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Tokens.Color.textPrimary)
                Text("\(viewModel.customerName) sent you a tip")
                    .font(Tokens.FontRole.bodyBold)
                    .foregroundStyle(Tokens.Color.textSecondary)
            }

            if let message = viewModel.message, !message.isEmpty {
                Text("\"\(message)\"")
                    .font(Tokens.FontRole.body)
                    .foregroundStyle(Tokens.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(Tokens.Space.md)
                    .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
            }

            PrimaryButton(title: "Send thank you", icon: "paperplane.fill") {
                viewModel.sendThankYou()
            }
            SecondaryButton(title: "Close", action: onClose)
        }
        .padding(Tokens.Space.xl)
        .background(Tokens.Color.surface)
        .navigationDestination(item: $viewModel.thankYouRoute) { route in
            let chatViewModel = ChatViewModel(threadID: route.threadID, selfUserID: "runner", remoteUserID: route.customerName)
            ChatThreadView(viewModel: chatViewModelWithPrefill(chatViewModel, route.quickReply), participantName: route.customerName)
        }
    }

    private func chatViewModelWithPrefill(_ chatViewModel: ChatViewModel, _ text: String) -> ChatViewModel {
        chatViewModel.composeText = text
        return chatViewModel
    }
}
