import SwiftUI
import KilatUI

struct AddBankAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var viewModel: BankAccountsViewModel
    @State private var bankName = "Maybank"
    @State private var accountNumber = ""
    @State private var holderName = ""

    private let banks = ["Maybank", "CIMB", "Public Bank", "RHB", "Hong Leong", "Bank Islam"]

    init(viewModel: BankAccountsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Bank", selection: $bankName) {
                    ForEach(banks, id: \.self) { bank in
                        Text(bank).tag(bank)
                    }
                }
                TextField("Account number", text: $accountNumber)
                    .keyboardType(.numberPad)
                TextField("Holder name", text: $holderName)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle("Add account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.add(
                                BankAccountDraft(
                                    bankName: bankName,
                                    accountNumber: accountNumber,
                                    holderName: holderName
                                )
                            )
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!isValid || viewModel.isSaving)
                }
            }
        }
    }

    private var isValid: Bool {
        accountNumber.count >= 6 && !holderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
