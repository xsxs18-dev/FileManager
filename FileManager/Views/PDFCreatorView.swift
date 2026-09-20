import SwiftUI
import UIKit

struct PDFCreatorView: View {
    @State private var activeSheet: ActiveSheet?
    @State private var isScanning = false
    @State private var scannedImages: [UIImage] = []
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private enum ActiveSheet: Identifiable {
        case imagesToPDF
        case textToPDF
        case vaultImages
        case scanNaming

        var id: String {
            switch self {
            case .imagesToPDF: return "imagesToPDF"
            case .textToPDF: return "textToPDF"
            case .vaultImages: return "vaultImages"
            case .scanNaming: return "scanNaming"
            }
        }
    }

    var body: some View {
        ZStack {
            FVColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: FVSpacing.md) {
                    Text("Combine photos, files, scans, or typed text into a PDF. New PDFs are saved to My Files.")
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FVSpacing.lg)
                        .padding(.top, FVSpacing.md)

                    option(
                        title: "From Photos",
                        subtitle: "Pick photos from your library",
                        systemImage: "photo.on.rectangle"
                    ) {
                        activeSheet = .imagesToPDF
                    }

                    option(
                        title: "From Files",
                        subtitle: "Combine images already in your vault",
                        systemImage: "folder"
                    ) {
                        activeSheet = .vaultImages
                    }

                    option(
                        title: "Scan Document",
                        subtitle: "Use your camera as a scanner",
                        systemImage: "camera.viewfinder"
                    ) {
                        isScanning = true
                    }

                    option(
                        title: "From Text",
                        subtitle: "Write or paste text and export it",
                        systemImage: "doc.richtext"
                    ) {
                        activeSheet = .textToPDF
                    }

                    if let successMessage {
                        Text(successMessage)
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.accent)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(FVFont.caption)
                            .foregroundStyle(FVColor.danger)
                    }
                }
                .padding(FVSpacing.md)
            }
        }
        .navigationTitle("PDF Creator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FVColor.background, for: .navigationBar)
        .toolbarColorScheme(ThemeManager.shared.current.colorScheme, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .imagesToPDF:
                ImagesToPDFSheet { images, name in
                    createPDF(fromImages: images, named: name)
                }
            case .textToPDF:
                TextToPDFSheet { text, name in
                    createPDF(fromText: text, named: name)
                }
            case .vaultImages:
                VaultImagePickerSheet { images, name in
                    createPDF(fromImages: images, named: name)
                }
            case .scanNaming:
                NameInputSheet(
                    title: "Save PDF",
                    placeholder: "File name",
                    initialValue: "Scan",
                    confirmTitle: "Save"
                ) { name in
                    createPDF(fromImages: scannedImages, named: name)
                    scannedImages = []
                }
            }
        }
        .fullScreenCover(isPresented: $isScanning) {
            DocumentScannerView(
                onFinish: { images in
                    isScanning = false
                    scannedImages = images
                    if !images.isEmpty { activeSheet = .scanNaming }
                },
                onCancel: {
                    isScanning = false
                }
            )
            .ignoresSafeArea()
        }
    }

    private func option(title: LocalizedStringKey, subtitle: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: FVSpacing.md) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(FVColor.accent)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FVFont.headline)
                        .foregroundStyle(FVColor.textPrimary)
                    Text(subtitle)
                        .font(FVFont.caption)
                        .foregroundStyle(FVColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(FVColor.textSecondary)
            }
            .padding(FVSpacing.md)
            .fvCard()
        }
    }

    private func createPDF(fromImages images: [UIImage], named name: String) {
        errorMessage = nil
        successMessage = nil
        do {
            let url = try PDFService.shared.createPDF(fromImages: images, named: name, in: FileSystemService.shared.rootURL)
            successMessage = String(localized: "Saved \(url.lastPathComponent) to My Files.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createPDF(fromText text: String, named name: String) {
        errorMessage = nil
        successMessage = nil
        do {
            let url = try PDFService.shared.createPDF(fromText: text, named: name, in: FileSystemService.shared.rootURL)
            successMessage = String(localized: "Saved \(url.lastPathComponent) to My Files.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
