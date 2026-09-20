import SwiftUI

struct TextFileEditorView: View {
    let title: String
    let initialContent: String
    let confirmTitle: LocalizedStringKey
    let onSave: (String) -> Void

    @State private var content: String
    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        initialContent: String = "",
        confirmTitle: LocalizedStringKey = "Save",
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.initialContent = initialContent
        self.confirmTitle = confirmTitle
        self.onSave = onSave
        _content = State(initialValue: initialContent)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $content)
                .scrollContentBackground(.hidden)
                .background(FVColor.background)
                .foregroundStyle(FVColor.textPrimary)
                .padding(FVSpacing.sm)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(FVColor.background, for: .navigationBar)
                .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(FVColor.accent)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(confirmTitle) {
                            onSave(content)
                            dismiss()
                        }
                        .foregroundStyle(FVColor.accent)
                    }
                }
        }
    }
}
