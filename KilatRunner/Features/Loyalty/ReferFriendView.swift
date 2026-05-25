import SwiftUI
import UIKit
import KilatUI

struct ReferFriendView: View {
    @Bindable private var viewModel: ReferFriendViewModel
    @State private var showsShareSheet = false

    init(viewModel: ReferFriendViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                hero
                friendList
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.destructive)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Refer a Friend")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.friends.isEmpty {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $showsShareSheet) {
            ShareSheet(items: [viewModel.shareText])
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.md) {
            Text("Your code")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.onPrimaryTonal.opacity(0.75))
                .textCase(.uppercase)
            Text(viewModel.referralCode ?? "READY")
                .font(Tokens.FontRole.displayL)
                .foregroundStyle(Tokens.Color.onPrimaryTonal)
                .monospaced()
            HStack(spacing: Tokens.Space.sm) {
                PrimaryButton(
                    title: viewModel.referralCode == nil ? "Create code" : "Share",
                    icon: "square.and.arrow.up",
                    isLoading: viewModel.isCreatingCode,
                    action: {
                        if viewModel.referralCode == nil {
                            Task { await viewModel.ensureCode() }
                        } else {
                            showsShareSheet = true
                        }
                    }
                )
                Button("Copy") {
                    UIPasteboard.general.string = viewModel.referralCode
                }
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.onPrimaryTonal)
                .disabled(viewModel.referralCode == nil)
            }
        }
        .padding(Tokens.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
    }

    private var friendList: some View {
        LazyVStack(spacing: Tokens.Space.sm) {
            ForEach(viewModel.friends) { friend in
                HStack(spacing: Tokens.Space.sm) {
                    VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                        Text(friend.name)
                            .font(Tokens.FontRole.bodyBold)
                            .foregroundStyle(Tokens.Color.textPrimary)
                        Text("\(friend.deliveriesToDate)/5 deliveries · \(friend.signupDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }
                    Spacer()
                    if friend.isPayoutEligible {
                        Button("Redeem") {
                            Task { await viewModel.redeem(friend) }
                        }
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.primary)
                    } else {
                        Text(friend.payoutStatus.rawValue.capitalized)
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textSecondary)
                    }
                }
                .padding(Tokens.Space.md)
                .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
