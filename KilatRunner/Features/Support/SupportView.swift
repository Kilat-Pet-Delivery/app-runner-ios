import SwiftUI
import KilatUI

struct SupportView: View {
    @Bindable private var viewModel: SupportViewModel

    init(viewModel: SupportViewModel = SupportViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                search
                chatHero
                topics
                faqs
                if let ticket = viewModel.recentTicket {
                    recent(ticket)
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Support")
        .navigationDestination(item: $viewModel.route) { route in
            switch route {
            case let .chat(threadID):
                ChatThreadView(
                    viewModel: ChatViewModel(
                        threadID: threadID,
                        selfUserID: "runner",
                        remoteUserID: "support"
                    ),
                    participantName: "Support"
                )
            default:
                EmptyView()
            }
        }
        .task { await viewModel.load() }
    }

    private var search: some View {
        HStack {
            Image(kilatAsset: "search")
                .resizable()
                .renderingMode(.template)
                .frame(width: 18, height: 18)
            TextField("Search support", text: $viewModel.query)
        }
        .padding(Tokens.Space.md)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }

    private var chatHero: some View {
        Button {
            Task { await viewModel.openSupportChat() }
        } label: {
            HStack(spacing: Tokens.Space.md) {
                Image(kilatAsset: "message")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("Chat with support")
                        .font(Tokens.FontRole.titleM)
                    Text("Fast help for active deliveries")
                        .font(Tokens.FontRole.caption)
                }
                Spacer()
            }
            .foregroundStyle(Tokens.Color.onPrimaryTonal)
            .padding(Tokens.Space.lg)
            .background(Tokens.Color.primaryTonal, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    private var topics: some View {
        let items = ["Payments", "Deliveries", "Live pets", "Account", "App issues", "Other"]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.Space.sm) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(Tokens.FontRole.label)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
            }
        }
    }

    private var faqs: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.sm) {
            Text("FAQs")
                .font(Tokens.FontRole.titleM)
            ForEach(viewModel.filteredFAQs) { item in
                Button {
                    viewModel.toggleFAQ(item.id)
                } label: {
                    VStack(alignment: .leading, spacing: Tokens.Space.xs) {
                        Text(item.question)
                            .font(Tokens.FontRole.label)
                        if viewModel.expandedFAQIDs.contains(item.id) {
                            Text(item.answer)
                                .font(Tokens.FontRole.caption)
                                .foregroundStyle(Tokens.Color.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Tokens.Space.md)
                    .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recent(_ ticket: SupportTicket) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("Recent ticket")
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.textSecondary)
            Text(ticket.title)
                .font(Tokens.FontRole.label)
            Text(ticket.status.capitalized)
                .font(Tokens.FontRole.caption)
                .foregroundStyle(Tokens.Color.primary)
        }
        .padding(Tokens.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.md))
    }
}
