import SwiftUI
import KilatUI

struct ReviewsView: View {
    @Bindable private var viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                summaryChips
                starFilters

                if viewModel.isLoading, viewModel.reviews.isEmpty {
                    ProgressView()
                        .tint(Tokens.Color.primary)
                        .frame(maxWidth: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(Tokens.Color.destructive)
                } else {
                    reviewList
                }
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.reviews.isEmpty {
                await viewModel.load()
            }
        }
    }

    private var summaryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Tokens.Space.xs) {
                ForEach(viewModel.summaryChips, id: \.label) { chip in
                    Text("\(chip.label) · \(chip.count)")
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.primary)
                        .padding(.horizontal, Tokens.Space.sm)
                        .padding(.vertical, Tokens.Space.xxs)
                        .background(Tokens.Color.primaryTonal, in: Capsule())
                }
            }
        }
    }

    private var starFilters: some View {
        HStack(spacing: Tokens.Space.xs) {
            ForEach([5, 4, 3, 2, 1], id: \.self) { stars in
                let selected = viewModel.selectedStars == stars
                Button {
                    viewModel.selectStars(stars)
                } label: {
                    Text("\(stars)★")
                        .font(Tokens.FontRole.label)
                        .foregroundStyle(selected ? Tokens.Color.onPrimary : Tokens.Color.textPrimary)
                        .padding(.horizontal, Tokens.Space.sm)
                        .padding(.vertical, Tokens.Space.xs)
                        .background(selected ? Tokens.Color.primary : Tokens.Color.surface, in: Capsule())
                }
            }
        }
    }

    private var reviewList: some View {
        LazyVStack(spacing: Tokens.Space.sm) {
            ForEach(viewModel.filteredReviews) { review in
                VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                    HStack {
                        Text(review.customerName)
                            .font(Tokens.FontRole.bodyBold)
                            .foregroundStyle(Tokens.Color.textPrimary)
                        Spacer()
                        Text(String(repeating: "★", count: review.rating))
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text(review.comment)
                        .font(Tokens.FontRole.body)
                        .foregroundStyle(Tokens.Color.textSecondary)
                    HStack {
                        if let tipCents = review.tipCents, tipCents > 0 {
                            Text(String(format: "Tip RM %.2f", Double(tipCents) / 100))
                                .font(Tokens.FontRole.caption)
                                .foregroundStyle(Tokens.Color.primary)
                        }
                        Spacer()
                        Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(Tokens.FontRole.caption)
                            .foregroundStyle(Tokens.Color.textTertiary)
                    }
                }
                .padding(Tokens.Space.md)
                .background(Tokens.Color.surface, in: RoundedRectangle(cornerRadius: Tokens.Radius.lg, style: .continuous))
            }
        }
    }
}
