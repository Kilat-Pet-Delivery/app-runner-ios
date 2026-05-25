import SwiftUI
import KilatUI
#if canImport(UIKit)
import UIKit
#endif

struct ChatThreadView: View {
    @Bindable private var viewModel: ChatViewModel
    let participantName: String

    @State private var showsPhotoPicker = false
    #if canImport(UIKit)
    @State private var pickedImage: UIImage?
    #endif

    init(viewModel: ChatViewModel, participantName: String) {
        self.viewModel = viewModel
        self.participantName = participantName
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Tokens.Space.lg)
                .padding(.vertical, Tokens.Space.sm)
                .background(Tokens.Color.surface)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Tokens.Space.sm) {
                        if viewModel.nextCursor != nil {
                            loadOlderRow
                        }
                        ForEach(viewModel.messages) { message in
                            ChatBubble(
                                text: message.body,
                                attachmentURL: message.attachmentURL,
                                senderSide: message.senderSide == .self ? .self : .other,
                                deliveryState: bubbleState(for: message.deliveryState),
                                timestamp: message.timestamp
                            )
                            .id(message.id)
                        }
                        if viewModel.remoteIsTyping {
                            typingIndicator
                        }
                    }
                    .padding(Tokens.Space.md)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()
            composer
                .background(Tokens.Color.surface)
        }
        .background(Tokens.Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.connect() }
        .onDisappear { viewModel.disconnect() }
        #if canImport(UIKit)
        .sheet(isPresented: $showsPhotoPicker) {
            PhotoPickerSheet(selectedImage: $pickedImage) { image in
                Task { await viewModel.sendPhoto(image) }
            }
        }
        #endif
    }

    private var header: some View {
        HStack(spacing: Tokens.Space.sm) {
            VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
                Text(participantName)
                    .font(Tokens.FontRole.titleM)
                    .foregroundStyle(Tokens.Color.textPrimary)
                HStack(spacing: Tokens.Space.xs) {
                    Circle()
                        .fill(presenceColor)
                        .frame(width: 8, height: 8)
                    Text(presenceLabel)
                        .font(Tokens.FontRole.caption)
                        .foregroundStyle(Tokens.Color.textSecondary)
                }
            }
            Spacer()
        }
    }

    private var loadOlderRow: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingOlder {
                ProgressView()
            } else {
                Button("Load earlier messages") {
                    Task { await viewModel.loadOlder() }
                }
                .font(Tokens.FontRole.label)
                .foregroundStyle(Tokens.Color.primary)
            }
            Spacer()
        }
        .padding(.vertical, Tokens.Space.xs)
    }

    private var typingIndicator: some View {
        HStack(spacing: Tokens.Space.xs) {
            ForEach(0..<3) { _ in
                Circle().fill(Tokens.Color.textSecondary).frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, Tokens.Space.sm)
        .padding(.vertical, Tokens.Space.xs)
        .background(Tokens.Color.surfaceMuted, in: Capsule())
    }

    private var composer: some View {
        HStack(spacing: Tokens.Space.sm) {
            Button {
                showsPhotoPicker = true
            } label: {
                Image(systemName: "camera.fill")
                    .foregroundStyle(Tokens.Color.primary)
                    .frame(width: Tokens.Hit.min, height: Tokens.Hit.min)
            }
            .accessibilityLabel("Attach photo")

            TextField("Message", text: $viewModel.composeText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, Tokens.Space.sm)
                .padding(.vertical, Tokens.Space.xs)
                .background(Tokens.Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Tokens.Radius.md, style: .continuous))
                .onChange(of: viewModel.composeText) { _, newValue in
                    viewModel.setTyping(active: !newValue.isEmpty)
                }

            Button {
                let body = viewModel.composeText
                Task { await viewModel.sendText(body) }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(Tokens.Color.onPrimary)
                    .frame(width: Tokens.Hit.min, height: Tokens.Hit.min)
                    .background(Tokens.Color.primary, in: Circle())
            }
            .disabled(viewModel.composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, Tokens.Space.md)
        .padding(.vertical, Tokens.Space.sm)
    }

    private var presenceColor: Color {
        switch viewModel.remotePresence {
        case .online: return Tokens.Color.online
        case .offline, .lastSeen: return Tokens.Color.textSecondary
        }
    }

    private var presenceLabel: String {
        switch viewModel.remotePresence {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        case let .lastSeen(date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Last seen \(formatter.localizedString(for: date, relativeTo: Date()))"
        }
    }

    private func bubbleState(for state: ChatDeliveryState) -> ChatBubble.DeliveryState {
        switch state {
        case .sent: return .sent
        case .delivered: return .delivered
        case .read: return .read
        }
    }
}

#if canImport(UIKit)
import PhotosUI

private struct PhotoPickerSheet: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onPick: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: $selectedImage, onPick: onPick)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        @Binding var selectedImage: UIImage?
        let onPick: (UIImage) -> Void

        init(selectedImage: Binding<UIImage?>, onPick: @escaping (UIImage) -> Void) {
            self._selectedImage = selectedImage
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, _ in
                guard let image = reading as? UIImage else { return }
                Task { @MainActor in
                    self?.selectedImage = image
                    self?.onPick(image)
                }
            }
        }
    }
}
#endif
