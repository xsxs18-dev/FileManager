import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

struct UnlockedPDFSheet: View {
    let document: PDFDocument
    let originalName: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(document: document)
                .background(FVColor.background)
                .navigationTitle(originalName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(FVColor.background, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Schließen") { dismiss() }
                            .foregroundStyle(FVColor.accent)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Entsperrte Version speichern") {
                            onSave()
                            dismiss()
                        }
                        .foregroundStyle(FVColor.accent)
                    }
                }
        }
    }
}
