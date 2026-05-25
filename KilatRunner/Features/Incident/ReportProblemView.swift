import SwiftUI
import KilatUI

#if canImport(UIKit)
import UIKit
#endif

struct ReportProblemView: View {
    @Bindable var viewModel: ReportProblemViewModel
    let onSOS: () -> Void
    let onDone: () -> Void

#if canImport(UIKit)
    @State private var selectedImage: UIImage?
#endif

    private let columns = [
        GridItem(.flexible(), spacing: Tokens.Space.sm),
        GridItem(.flexible(), spacing: Tokens.Space.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.Space.lg) {
                emergencyBanner
                issueGrid

#if canImport(UIKit)
                PhotoCaptureZone(selectedImage: $selectedImage)
                    .onChange(of: selectedImage) { _, image in
                        viewModel.photoData = image?.jpegData(compressionQuality: 0.82)
                    }
#endif

                TextField("Add details", text: $viewModel.notes, axis: .vertical)
                    .font(Tokens.FontRole.body)
                    .padding(Tokens.Space.sm)
                    .frame(minHeight: 96, alignment: .topLeading)
                    .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.destructive)
                }

                PrimaryButton(
                    title: "Submit report",
                    icon: "paperplane.fill",
                    isLoading: viewModel.isSubmitting,
                    action: { Task { await viewModel.submit() } }
                )
            }
            .padding(Tokens.Space.lg)
        }
        .background(Tokens.Color.background.ignoresSafeArea())
        .navigationTitle("Report problem")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.didSubmit) { _, didSubmit in
            if didSubmit {
                onDone()
            }
        }
    }

    private var emergencyBanner: some View {
        Button(action: onSOS) {
            HStack(alignment: .center, spacing: Tokens.Space.sm) {
                Image(systemName: "sos.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                    Text("Emergency")
                        .font(Tokens.FontRole.bodyBold)
                    Text("Pet or runner safety issue")
                        .font(Tokens.FontRole.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(Tokens.Space.md)
            .background(Tokens.Color.destructive, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var issueGrid: some View {
        LazyVGrid(columns: columns, spacing: Tokens.Space.sm) {
            ForEach(ReportProblemIssue.allCases) { issue in
                Button {
                    viewModel.selectedIssue = issue
                } label: {
                    VStack(alignment: .leading, spacing: Tokens.Space.sm) {
                        Image(systemName: icon(for: issue))
                            .font(.system(size: 22, weight: .semibold))
                        Text(issue.label)
                            .font(Tokens.FontRole.bodyBold)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(viewModel.selectedIssue == issue ? Tokens.Color.onPrimaryTonal : Tokens.Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
                    .padding(Tokens.Space.sm)
                    .background(tileBackground(for: issue), in: RoundedRectangle(cornerRadius: Tokens.Radius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func tileBackground(for issue: ReportProblemIssue) -> Color {
        viewModel.selectedIssue == issue ? Tokens.Color.primaryTonal : Tokens.Color.surface
    }

    private func icon(for issue: ReportProblemIssue) -> String {
        switch issue {
        case .petUnwell: return "heart.text.square.fill"
        case .vendorNotReady: return "clock.badge.exclamationmark.fill"
        case .wrongItem: return "shippingbox.fill"
        case .traffic: return "car.2.fill"
        case .locationWrong: return "mappin.and.ellipse"
        case .other: return "ellipsis.circle.fill"
        }
    }
}
