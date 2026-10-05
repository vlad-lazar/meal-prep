import SwiftUI

struct PostcodeSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void = {}
    @State private var postcode = ""
    @State private var errorText: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 2200", text: $postcode)
                        .keyboardType(.numberPad)
                        .font(.rounded(.title2))
                        .onChange(of: postcode) { _, new in
                            postcode = String(new.filter(\.isNumber).prefix(4))
                        }
                } header: {
                    Text("Danish postcode")
                } footer: {
                    Text(errorText ?? "Used only to find grocery stores near you.")
                        .foregroundStyle(errorText == nil ? Color.secondary : Color.red)
                }
                Section {
                    Button {
                        Task {
                            await model.locate()
                            if model.coordinate != nil {
                                dismiss()
                                Task { await model.refreshNearby() }
                            }
                        }
                    } label: {
                        Label("Use my current location", systemImage: "location.fill")
                    }
                }
            }
            .navigationTitle("Your area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(postcode.count != 4 || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await model.usePostcode(postcode)
            dismiss()
            onSaved()
        } catch {
            errorText = "Couldn't find that postcode — try another."
        }
    }
}
